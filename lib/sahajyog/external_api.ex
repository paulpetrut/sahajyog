defmodule Sahajyog.ExternalApi do
  @moduledoc """
  Client for the learnsahajayoga.org API with robust error handling for deployment environments.
  """

  require Logger

  @base_url "https://learnsahajayoga.org/api"
  @default_timeout 15_000
  @default_receive_timeout 20_000

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

  def fetch_countries do
    url = "#{@base_url}/meta/countries"

    case make_request(url) do
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

  def fetch_years do
    url = "#{@base_url}/meta/years"

    case make_request(url) do
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

  def fetch_translation_languages do
    url = "#{@base_url}/meta/languages"

    case make_request(url) do
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

  defp make_request(url) do
    start_time = System.monotonic_time(:millisecond)

    # Deployment-friendly options with aggressive retry for 520 errors
    options = [
      connect_options: [timeout: @default_timeout],
      receive_timeout: @default_receive_timeout,
      retry: :transient,
      max_retries: 3,
      retry_delay: fn attempt -> attempt * 3000 end,
      retry_log_level: :warning,
      headers: [
        {"user-agent", "SahajyogApp/1.0"},
        {"accept", "application/json"}
      ]
    ]

    result = Req.get(url, options)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    case result do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        Logger.error("HTTP #{status} response in #{duration}ms - Body: #{inspect(body)}")
        {:error, "The talks service returned HTTP #{status}"}

      {:error, %Req.TransportError{reason: :timeout}} ->
        Logger.error("Request timeout after #{duration}ms")
        {:error, "Connection timeout. Please try again later."}

      {:error, %Req.TransportError{reason: :econnrefused}} ->
        Logger.error("Connection refused after #{duration}ms")
        {:error, "Unable to connect to the talks service. Please try again later."}

      {:error, %Req.TransportError{reason: :nxdomain}} ->
        Logger.error("DNS resolution failed after #{duration}ms")
        {:error, "Unable to resolve talks service domain. Please check your internet connection."}

      {:error, %Req.TransportError{reason: reason}} ->
        Logger.error("Transport error after #{duration}ms: #{inspect(reason)}")
        {:error, "Network error: #{inspect(reason)}"}

      {:error, exception} ->
        Logger.error("Request failed after #{duration}ms: #{inspect(exception)}")
        {:error, "Unable to load talks. Please try again later."}
    end
  end
end
