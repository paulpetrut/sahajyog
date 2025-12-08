defmodule Sahajyog.ExternalApi do
  @moduledoc """
  Client for the learnsahajayoga.org API with robust error handling for deployment environments.

  Filter options (countries, years, categories, languages) are cached via `Sahajyog.ApiCache`.
  Use the public `fetch_*` functions which leverage caching, or `fetch_*_uncached` for direct API access.
  """

  require Logger

  @base_url "https://learnsahajayoga.org/api"
  @default_timeout 15_000
  @default_receive_timeout 20_000

  # Telemetry event names
  @telemetry_prefix [:sahajyog, :external_api]

  def fetch_talks(filters \\ %{}) do
    search_query = filters[:search_query]

    url =
      if search_query && search_query != "" do
        build_search_url(search_query)
      else
        build_talks_url(filters)
      end

    case make_request(url) do
      {:ok, %{"results" => results, "total_results" => total}} when is_list(results) ->
        {:ok, results, total}

      {:ok, %{"results" => results}} when is_list(results) ->
        {:ok, results, length(results)}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected API response format: #{inspect(unexpected_body)}")
        {:error, "The talks service returned an unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch talks: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch countries with caching.
  """
  def fetch_countries do
    Sahajyog.ApiCache.get_countries()
  end

  @doc """
  Fetch countries directly from API (bypasses cache).
  """
  def fetch_countries_uncached do
    url = "#{@base_url}/meta/countries"

    case make_request(url, :countries) do
      {:ok, %{"languages" => languages}} when is_list(languages) ->
        countries =
          languages
          |> Enum.find(fn lang -> lang["code"] == "en" end)
          |> case do
            %{"countries" => countries} when is_list(countries) ->
              countries
              |> Enum.sort_by(fn country -> country["name"] end)
              |> Enum.map(fn country -> country["name"] end)

            _ ->
              []
          end

        {:ok, countries}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected countries response: #{inspect(unexpected_body)}")
        {:error, "Unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch countries: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch years with caching.
  """
  def fetch_years do
    Sahajyog.ApiCache.get_years()
  end

  @doc """
  Fetch years directly from API (bypasses cache).
  """
  def fetch_years_uncached do
    url = "#{@base_url}/meta/years"

    case make_request(url, :years) do
      {:ok, %{"years" => years}} when is_list(years) ->
        year_list =
          years
          |> Enum.sort_by(fn year -> -String.to_integer(year["year"]) end)
          |> Enum.map(fn year -> year["year"] end)

        {:ok, year_list}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected years response: #{inspect(unexpected_body)}")
        {:error, "Unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch years: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch translation languages with caching.
  """
  def fetch_translation_languages do
    Sahajyog.ApiCache.get_translation_languages()
  end

  @doc """
  Fetch translation languages directly from API (bypasses cache).
  """
  def fetch_translation_languages_uncached do
    url = "#{@base_url}/meta/languages"

    case make_request(url, :translation_languages) do
      {:ok, %{"languages" => languages}} when is_list(languages) ->
        language_list =
          languages
          |> Enum.sort_by(fn lang -> -lang["talk_count"] end)
          |> Enum.map(fn lang ->
            %{
              code: lang["language_code"],
              name: lang["language_name"],
              count: lang["talk_count"]
            }
          end)

        {:ok, language_list}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected languages response: #{inspect(unexpected_body)}")
        {:error, "Unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch translation languages: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch categories with caching.
  """
  def fetch_categories do
    Sahajyog.ApiCache.get_categories()
  end

  @doc """
  Fetch categories directly from API (bypasses cache).
  """
  def fetch_categories_uncached do
    url = "#{@base_url}/meta/categories"

    case make_request(url, :categories) do
      {:ok, %{"languages" => languages}} when is_list(languages) ->
        categories =
          languages
          |> Enum.find(fn lang -> lang["language_code"] == "en" end)
          |> case do
            %{"categories" => categories} when is_list(categories) ->
              categories
              |> Enum.sort_by(fn cat -> -cat["talk_count"] end)
              |> Enum.map(fn cat -> cat["name"] end)

            _ ->
              []
          end

        {:ok, categories}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected categories response: #{inspect(unexpected_body)}")
        {:error, "Unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch categories: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetch spoken languages with caching.
  """
  def fetch_spoken_languages do
    Sahajyog.ApiCache.get_spoken_languages()
  end

  @doc """
  Fetch spoken languages directly from API (bypasses cache).
  """
  def fetch_spoken_languages_uncached do
    url = "#{@base_url}/meta/spoken-languages"

    case make_request(url, :spoken_languages) do
      {:ok, %{"spoken_languages" => languages}} when is_list(languages) ->
        spoken_languages =
          languages
          |> Enum.sort_by(fn lang -> -lang["talk_count"] end)
          |> Enum.map(fn lang -> lang["language_name"] end)

        {:ok, spoken_languages}

      {:ok, unexpected_body} ->
        Logger.error("Unexpected spoken languages response: #{inspect(unexpected_body)}")
        {:error, "Unexpected response format"}

      {:error, reason} ->
        Logger.error("Failed to fetch spoken languages: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_search_url(query) do
    params = %{"q" => query, "lang" => "en"}

    "#{@base_url}/search"
    |> URI.parse()
    |> URI.append_query(URI.encode_query(params))
    |> URI.to_string()
  end

  defp build_talks_url(filters) do
    # Use translation language if specified, otherwise default to "en"
    translation_lang = filters[:translation_language]
    lang = if translation_lang != nil && translation_lang != "", do: translation_lang, else: "en"

    params =
      %{"lang" => lang, "sort_by" => "date", "sort_order" => "ASC"}
      |> maybe_add_param("country", filters[:country])
      |> maybe_add_param("year", filters[:year])
      |> maybe_add_param("category", filters[:category])
      |> maybe_add_param("spoken-languages", filters[:spoken_language])

    "#{@base_url}/talks"
    |> URI.parse()
    |> URI.append_query(URI.encode_query(params))
    |> URI.to_string()
  end

  defp maybe_add_param(params, _key, nil), do: params
  defp maybe_add_param(params, _key, ""), do: params
  defp maybe_add_param(params, key, value), do: Map.put(params, key, value)

  defp make_request(url, endpoint \\ :talks) do
    # Replace base URL if overridden by env var, mostly for dev/testing
    url =
      if System.get_env("API_BASE_URL") do
        String.replace(url, @base_url, System.get_env("API_BASE_URL"))
      else
        url
      end

    start_time = System.monotonic_time(:millisecond)
    metadata = %{url: url, endpoint: endpoint}

    # Emit telemetry start event
    :telemetry.execute(
      @telemetry_prefix ++ [:request, :start],
      %{system_time: System.system_time()},
      metadata
    )

    # Deployment-friendly options with exponential backoff and jitter
    # to avoid thundering herd problems
    options = [
      connect_options: [timeout: @default_timeout],
      receive_timeout: @default_receive_timeout,
      retry: :transient,
      max_retries: 3,
      retry_delay: fn attempt ->
        # Exponential backoff: 2^attempt * 1000ms with random jitter (0-1000ms)
        base_delay = :math.pow(2, attempt) * 1000
        jitter = :rand.uniform(1000)
        trunc(base_delay + jitter)
      end,
      retry_log_level: :warning,
      headers:
        [
          {"user-agent", System.get_env("API_USER_AGENT") || "SahajyogApp/1.0"},
          {"accept", "application/json"}
        ] ++
          if(System.get_env("API_HOST_HEADER"),
            do: [{"host", System.get_env("API_HOST_HEADER")}],
            else: []
          )
    ]

    result = Req.get(url, options)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    case result do
      {:ok, %{status: 200, body: body}} ->
        # Emit telemetry success event
        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: 200},
          Map.put(metadata, :result, :ok)
        )

        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("HTTP #{status} response in #{duration}ms - Body: #{inspect(body)}")

        # Emit telemetry error event
        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: status},
          Map.merge(metadata, %{result: :error, error: :http_error})
        )

        {:error, "The talks service returned HTTP #{status}"}

      {:error, %Req.TransportError{reason: :timeout}} ->
        Logger.error("Request timeout after #{duration}ms")

        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: nil},
          Map.merge(metadata, %{result: :error, error: :timeout})
        )

        {:error, "Connection timeout. Please try again later."}

      {:error, %Req.TransportError{reason: :econnrefused}} ->
        Logger.error("Connection refused after #{duration}ms")

        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: nil},
          Map.merge(metadata, %{result: :error, error: :econnrefused})
        )

        {:error, "Unable to connect to the talks service. Please try again later."}

      {:error, %Req.TransportError{reason: :nxdomain}} ->
        Logger.error("DNS resolution failed after #{duration}ms")

        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: nil},
          Map.merge(metadata, %{result: :error, error: :nxdomain})
        )

        {:error, "Unable to resolve talks service domain. Please check your internet connection."}

      {:error, %Req.TransportError{reason: reason}} ->
        Logger.error("Transport error after #{duration}ms: #{inspect(reason)}")

        :telemetry.execute(
          @telemetry_prefix ++ [:request, :stop],
          %{duration: duration, status: nil},
          Map.merge(metadata, %{result: :error, error: reason})
        )

        {:error, "Network error: #{inspect(reason)}"}

      {:error, exception} ->
        Logger.error("Request failed after #{duration}ms: #{inspect(exception)}")

        :telemetry.execute(
          @telemetry_prefix ++ [:request, :exception],
          %{duration: duration},
          Map.merge(metadata, %{result: :error, error: exception})
        )

        {:error, "Unable to load talks. Please try again later."}
    end
  end
end
