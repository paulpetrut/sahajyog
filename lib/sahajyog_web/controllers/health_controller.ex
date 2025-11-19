defmodule SahajyogWeb.HealthController do
  use SahajyogWeb, :controller

  require Logger

  def index(conn, _params) do
    health_status = %{
      status: "ok",
      timestamp: DateTime.utc_now(),
      checks: %{
        database: check_database(),
        external_api: check_external_api(),
        r2_storage: check_r2_storage()
      }
    }

    overall_status = if all_checks_pass?(health_status.checks), do: 200, else: 503

    conn
    |> put_status(overall_status)
    |> json(health_status)
  end

  def api_test(conn, _params) do
    Logger.info("API connectivity test requested")

    test_results = %{
      timestamp: DateTime.utc_now(),
      tests: %{
        basic_talks: test_basic_talks(),
        search: test_search(),
        countries: test_countries(),
        years: test_years()
      }
    }

    json(conn, test_results)
  end

  defp check_database do
    try do
      Sahajyog.Repo.query!("SELECT 1")
      %{status: "ok", message: "Database connection successful"}
    rescue
      e ->
        %{status: "error", message: "Database connection failed: #{inspect(e)}"}
    end
  end

  defp check_external_api do
    case Sahajyog.ExternalApi.fetch_talks(%{}) do
      {:ok, talks, total} when is_list(talks) ->
        %{
          status: "ok",
          message: "External API accessible",
          talks_count: length(talks),
          total_available: total
        }

      {:error, reason} ->
        %{status: "error", message: "External API failed: #{reason}"}
    end
  end

  defp check_r2_storage do
    try do
      # Simple check - just verify configuration exists
      bucket = Application.get_env(:sahajyog, :r2)[:bucket]

      if bucket do
        %{status: "ok", message: "R2 configuration present", bucket: bucket}
      else
        %{status: "warning", message: "R2 configuration missing"}
      end
    rescue
      e ->
        %{status: "error", message: "R2 check failed: #{inspect(e)}"}
    end
  end

  defp test_basic_talks do
    start_time = System.monotonic_time(:millisecond)

    result =
      case Sahajyog.ExternalApi.fetch_talks(%{}) do
        {:ok, talks, total} ->
          %{
            status: "success",
            talks_returned: length(talks),
            total_available: total,
            sample_talk: List.first(talks)
          }

        {:error, reason} ->
          %{status: "error", reason: reason}
      end

    end_time = System.monotonic_time(:millisecond)
    Map.put(result, :duration_ms, end_time - start_time)
  end

  defp test_search do
    start_time = System.monotonic_time(:millisecond)

    result =
      case Sahajyog.ExternalApi.fetch_talks(%{search_query: "kundalini"}) do
        {:ok, talks, total} ->
          %{
            status: "success",
            search_results: length(talks),
            total_found: total
          }

        {:error, reason} ->
          %{status: "error", reason: reason}
      end

    end_time = System.monotonic_time(:millisecond)
    Map.put(result, :duration_ms, end_time - start_time)
  end

  defp test_countries do
    start_time = System.monotonic_time(:millisecond)

    result =
      case Sahajyog.ExternalApi.fetch_countries() do
        {:ok, countries} ->
          %{
            status: "success",
            countries_count: length(countries),
            sample_countries: Enum.take(countries, 5)
          }

        {:error, reason} ->
          %{status: "error", reason: reason}
      end

    end_time = System.monotonic_time(:millisecond)
    Map.put(result, :duration_ms, end_time - start_time)
  end

  defp test_years do
    start_time = System.monotonic_time(:millisecond)

    result =
      case Sahajyog.ExternalApi.fetch_years() do
        {:ok, years} ->
          %{
            status: "success",
            years_count: length(years),
            year_range: "#{List.last(years)} - #{List.first(years)}"
          }

        {:error, reason} ->
          %{status: "error", reason: reason}
      end

    end_time = System.monotonic_time(:millisecond)
    Map.put(result, :duration_ms, end_time - start_time)
  end

  defp all_checks_pass?(checks) do
    Enum.all?(checks, fn {_key, check} ->
      Map.get(check, :status) == "ok"
    end)
  end
end
