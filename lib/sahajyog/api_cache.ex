defmodule Sahajyog.ApiCache do
  @moduledoc """
  ETS-based cache for external API responses.

  Caches filter options (countries, years, categories, languages) which rarely change.
  Uses TTL-based expiration to ensure data freshness.
  """

  use GenServer
  require Logger

  @table_name :api_cache
  @default_ttl :timer.hours(1)

  # Cache keys
  @countries_key :countries
  @years_key :years
  @categories_key :categories
  @spoken_languages_key :spoken_languages
  @translation_languages_key :translation_languages

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get cached countries or fetch from API.
  """
  def get_countries do
    get_or_fetch(@countries_key, fn -> Sahajyog.ExternalApi.fetch_countries_uncached() end)
  end

  @doc """
  Get cached years or fetch from API.
  """
  def get_years do
    get_or_fetch(@years_key, fn -> Sahajyog.ExternalApi.fetch_years_uncached() end)
  end

  @doc """
  Get cached categories or fetch from API.
  """
  def get_categories do
    get_or_fetch(@categories_key, fn -> Sahajyog.ExternalApi.fetch_categories_uncached() end)
  end

  @doc """
  Get cached spoken languages or fetch from API.
  """
  def get_spoken_languages do
    get_or_fetch(@spoken_languages_key, fn ->
      Sahajyog.ExternalApi.fetch_spoken_languages_uncached()
    end)
  end

  @doc """
  Get cached translation languages or fetch from API.
  """
  def get_translation_languages do
    get_or_fetch(@translation_languages_key, fn ->
      Sahajyog.ExternalApi.fetch_translation_languages_uncached()
    end)
  end

  @doc """
  Invalidate all cached data.
  """
  def invalidate_all do
    GenServer.call(__MODULE__, :invalidate_all)
  end

  @doc """
  Invalidate a specific cache key.
  """
  def invalidate(key) do
    GenServer.call(__MODULE__, {:invalidate, key})
  end

  @doc """
  Get cache stats for monitoring.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Private helpers

  defp get_or_fetch(key, fetch_fn) do
    case get_cached(key) do
      {:ok, value} ->
        {:ok, value}

      :miss ->
        case fetch_fn.() do
          {:ok, value} ->
            put_cached(key, value)
            {:ok, value}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp get_cached(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at}] ->
        if System.monotonic_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :miss
        end

      [] ->
        :miss
    end
  end

  defp put_cached(key, value, ttl \\ @default_ttl) do
    expires_at = System.monotonic_time(:millisecond) + ttl
    :ets.insert(@table_name, {key, value, expires_at})
    :ok
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])
    Logger.info("ApiCache started with ETS table: #{inspect(table)}")

    # Schedule periodic cleanup of expired entries
    schedule_cleanup()

    {:ok, %{table: table, hits: 0, misses: 0}}
  end

  @impl true
  def handle_call(:invalidate_all, _from, state) do
    :ets.delete_all_objects(@table_name)
    Logger.info("ApiCache: All entries invalidated")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:invalidate, key}, _from, state) do
    :ets.delete(@table_name, key)
    Logger.info("ApiCache: Entry invalidated for key: #{inspect(key)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    info = :ets.info(@table_name)
    size = Keyword.get(info, :size, 0)

    stats = %{
      size: size,
      memory_bytes: Keyword.get(info, :memory, 0) * :erlang.system_info(:wordsize),
      hits: state.hits,
      misses: state.misses
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)

    expired_count =
      :ets.foldl(
        fn {key, _value, expires_at}, acc ->
          if now >= expires_at do
            :ets.delete(@table_name, key)
            acc + 1
          else
            acc
          end
        end,
        0,
        @table_name
      )

    if expired_count > 0 do
      # Logger.debug("ApiCache: Cleaned up #{expired_count} expired entries")
    end

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    # Run cleanup every 10 minutes
    Process.send_after(self(), :cleanup, :timer.minutes(10))
  end
end
