defmodule SahajyogWeb.TalksLive do
  use SahajyogWeb, :live_view
  require Logger

  import SahajyogWeb.FormatHelpers, only: [format_duration: 1]

  def mount(_params, session, socket) do
    # Get current locale from session and map to API language code
    locale = session["locale"] || "en"
    default_translation_lang = map_locale_to_api_code(locale)

    socket =
      socket
      |> assign(:page_title, "Talks")
      |> assign(:search_query, "")
      |> assign(:selected_country, "")
      |> assign(:selected_year, "")
      |> assign(:selected_category, "")
      |> assign(:selected_spoken_language, "")
      |> assign(:selected_translation_language, default_translation_lang)
      |> assign(:sort_by, "date_asc")
      |> assign(:countries, [])
      |> assign(:years, [])
      |> assign(:categories, [])
      |> assign(:spoken_languages, [])
      |> assign(:translation_languages, [])
      |> assign(:total_results, 0)
      |> assign(:talks_empty?, true)
      |> assign(:show_advanced_filters, false)
      |> assign(:current_page, 1)
      |> assign(:per_page, 21)
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> assign(:retry_count, 0)
      |> stream_configure(:talks, dom_id: fn talk -> "talk-#{talk["id"]}" end)
      |> stream(:talks, [])

    socket =
      if connected?(socket) do
        socket = load_filter_options(socket)

        initial_filters = %{
          translation_language: default_translation_lang,
          sort_by: "date_asc",
          page: 1,
          per_page: 21
        }

        case fetch_talks(initial_filters) do
          {:ok, talks, total} ->
            socket
            |> stream(:talks, talks, reset: true)
            |> assign(:total_results, total)
            |> assign(:talks_empty?, talks == [])
            |> assign(:loading, false)
            |> assign(:error, nil)

          {:error, reason} ->
            require Logger
            Logger.error("Failed to load talks in mount: #{inspect(reason)}")

            # Schedule a retry after 5 seconds for deployment scenarios
            Process.send_after(self(), :retry_load, 5000)

            socket
            |> stream(:talks, [], reset: true)
            |> assign(:talks_empty?, false)
            |> assign(:loading, true)
            |> assign(:error, nil)
            |> assign(:retry_count, 1)
        end
      else
        socket
        |> assign(:loading, true)
        |> assign(:error, nil)
      end

    {:ok, socket}
  rescue
    error ->
      require Logger
      Logger.error("Error in TalksLive mount: #{inspect(error)}")
      Logger.error("Stacktrace: #{inspect(__STACKTRACE__)}")

      {:ok,
       socket
       |> stream(:talks, [], reset: true)
       |> assign(:talks_empty?, true)
       |> assign(:loading, false)
       |> assign(:error, "An error occurred. Please try again later.")}
  end

  defp fetch_talks(filters) do
    case Sahajyog.ExternalApi.fetch_talks(filters) do
      {:ok, results, _total} ->
        search_query = filters[:search_query]

        # Use results as-is since API returns complete data
        enriched_results = results

        # Apply client-side filtering if searching
        filtered_results =
          if search_query != nil and search_query != "" do
            enriched_results
            |> filter_by_country(filters[:country])
            |> filter_by_year(filters[:year])
            |> filter_by_category(filters[:category])
            |> filter_by_spoken_language(filters[:spoken_language])
          else
            enriched_results
          end

        # Apply sorting
        sorted_results = apply_sorting(filtered_results, filters[:sort_by] || "date_asc")

        # Update total after filtering
        total_after_filter = length(sorted_results)

        # Paginate results
        page = filters[:page] || 1
        per_page = filters[:per_page] || 21
        start_index = (page - 1) * per_page

        paginated_results =
          sorted_results
          |> Enum.slice(start_index, per_page)

        {:ok, paginated_results, total_after_filter}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp apply_sorting(results, "date_asc") do
    Enum.sort_by(results, fn talk -> Map.get(talk, "date", "9999-99-99") end, :asc)
  end

  defp apply_sorting(results, "date_desc") do
    Enum.sort_by(results, fn talk -> Map.get(talk, "date", "0000-00-00") end, :desc)
  end

  defp apply_sorting(results, "relevance") do
    # For search results, keep original order (API returns by relevance)
    results
  end

  defp apply_sorting(results, _), do: results

  defp filter_by_country(results, nil), do: results
  defp filter_by_country(results, ""), do: results

  defp filter_by_country(results, country) do
    Enum.filter(results, fn talk -> Map.get(talk, "country") == country end)
  end

  defp filter_by_year(results, nil), do: results
  defp filter_by_year(results, ""), do: results

  defp filter_by_year(results, year) do
    Enum.filter(results, fn talk ->
      case Map.get(talk, "date") do
        nil -> false
        date -> String.starts_with?(date, year)
      end
    end)
  end

  defp filter_by_category(results, nil), do: results
  defp filter_by_category(results, ""), do: results

  defp filter_by_category(results, category) do
    Enum.filter(results, fn talk -> Map.get(talk, "category") == category end)
  end

  defp filter_by_spoken_language(results, nil), do: results
  defp filter_by_spoken_language(results, ""), do: results

  defp filter_by_spoken_language(results, language) do
    Enum.filter(results, fn talk ->
      case Map.get(talk, "spoken_languages") do
        languages when is_list(languages) -> language in languages
        _ -> false
      end
    end)
  end

  defp load_filter_options(socket) do
    # Fetch all filter options in parallel using Task.async_stream for better performance
    tasks = [
      {:countries, fn -> Sahajyog.ExternalApi.fetch_countries() end},
      {:years, fn -> Sahajyog.ExternalApi.fetch_years() end},
      {:categories, fn -> Sahajyog.ExternalApi.fetch_categories() end},
      {:spoken_languages, fn -> Sahajyog.ExternalApi.fetch_spoken_languages() end},
      {:translation_languages, fn -> Sahajyog.ExternalApi.fetch_translation_languages() end}
    ]

    results =
      tasks
      |> Task.async_stream(fn {key, func} -> {key, func.()} end, timeout: 15_000)
      |> Enum.reduce(%{}, fn
        {:ok, {key, {:ok, data}}}, acc -> Map.put(acc, key, data)
        {:ok, {key, {:error, _}}}, acc -> Map.put(acc, key, [])
        {:exit, _reason}, acc -> acc
      end)

    socket
    |> assign(:countries, Map.get(results, :countries, []))
    |> assign(:years, Map.get(results, :years, []))
    |> assign(:categories, Map.get(results, :categories, []))
    |> assign(:spoken_languages, Map.get(results, :spoken_languages, []))
    |> assign(:translation_languages, Map.get(results, :translation_languages, []))
  end

  def handle_event("apply_all_filters", params, socket) do
    socket =
      socket
      |> assign(:search_query, params["search"] || "")
      |> assign(:selected_country, params["country"] || "")
      |> assign(:selected_year, params["year"] || "")
      |> assign(:selected_category, params["category"] || "")
      |> assign(:selected_spoken_language, params["spoken_language"] || "")
      |> assign(:selected_translation_language, params["translation_language"] || "")
      |> assign(:sort_by, params["sort_by"] || "date_asc")

    apply_filters(socket)
  end

  def handle_event("change_sort", %{"sort_by" => sort_by}, socket) do
    socket = assign(socket, :sort_by, sort_by)
    apply_filters(socket, false)
  end

  def handle_event("search", %{"search" => search_query}, socket) do
    socket = assign(socket, :search_query, search_query)
    apply_filters(socket)
  end

  def handle_event("filter_country", params, socket) do
    country = params["country"] || params["value"] || ""
    socket = assign(socket, :selected_country, country)
    apply_filters(socket)
  end

  def handle_event("filter_year", params, socket) do
    year = params["year"] || params["value"] || ""
    socket = assign(socket, :selected_year, year)
    apply_filters(socket)
  end

  def handle_event("filter_category", params, socket) do
    category = params["category"] || params["value"] || ""
    socket = assign(socket, :selected_category, category)
    apply_filters(socket)
  end

  def handle_event("filter_spoken_language", params, socket) do
    language = params["spoken_language"] || params["value"] || ""
    socket = assign(socket, :selected_spoken_language, language)
    apply_filters(socket)
  end

  def handle_event("filter_translation_language", params, socket) do
    language = params["translation_language"] || params["value"] || ""
    socket = assign(socket, :selected_translation_language, language)
    apply_filters(socket)
  end

  def handle_event("toggle_advanced_filters", _params, socket) do
    {:noreply, assign(socket, :show_advanced_filters, !socket.assigns.show_advanced_filters)}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> assign(:search_query, "")
      |> assign(:selected_country, "")
      |> assign(:selected_year, "")
      |> assign(:selected_category, "")
      |> assign(:selected_spoken_language, "")
      |> assign(:selected_translation_language, "")
      |> assign(:sort_by, "date_asc")

    apply_filters(socket)
  end

  def handle_event("clear_filter", %{"filter" => filter}, socket) do
    socket =
      case filter do
        "search" -> assign(socket, :search_query, "")
        "country" -> assign(socket, :selected_country, "")
        "year" -> assign(socket, :selected_year, "")
        "category" -> assign(socket, :selected_category, "")
        "spoken_language" -> assign(socket, :selected_spoken_language, "")
        "translation_language" -> assign(socket, :selected_translation_language, "")
        _ -> socket
      end

    apply_filters(socket)
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    page_num = String.to_integer(page)
    socket = assign(socket, :current_page, page_num)
    apply_filters(socket, false)
  end

  def handle_event("next_page", _params, socket) do
    total_pages = ceil(socket.assigns.total_results / socket.assigns.per_page)

    socket =
      if socket.assigns.current_page < total_pages do
        assign(socket, :current_page, socket.assigns.current_page + 1)
      else
        socket
      end

    apply_filters(socket, false)
  end

  def handle_event("prev_page", _params, socket) do
    socket =
      if socket.assigns.current_page > 1 do
        assign(socket, :current_page, socket.assigns.current_page - 1)
      else
        socket
      end

    apply_filters(socket, false)
  end

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(SahajyogWeb.Gettext, locale)
    translation_lang = map_locale_to_api_code(locale)

    socket =
      socket
      |> assign(:locale, locale)
      |> assign(:selected_translation_language, translation_lang)

    apply_filters(socket)
  end

  def handle_info(:retry_load, socket) do
    retry_count = socket.assigns.retry_count

    if retry_count < 3 do
      require Logger
      Logger.info("Retrying talks load (attempt #{retry_count + 1}/3)")

      socket = load_filter_options(socket)

      case fetch_talks(%{}) do
        {:ok, talks, total} ->
          {:noreply,
           socket
           |> stream(:talks, talks, reset: true)
           |> assign(:total_results, total)
           |> assign(:talks_empty?, talks == [])
           |> assign(:loading, false)
           |> assign(:error, nil)}

        {:error, reason} ->
          Logger.warning("Retry #{retry_count + 1} failed: #{inspect(reason)}")
          Process.send_after(self(), :retry_load, 5000)

          {:noreply,
           socket
           |> assign(:retry_count, retry_count + 1)
           |> assign(:loading, true)}
      end
    else
      Logger.error("All retry attempts exhausted for talks load")

      {:noreply,
       socket
       |> assign(:loading, false)
       |> assign(:error, "Unable to load talks. Please refresh the page.")}
    end
  end

  defp apply_filters(socket, reset_page \\ true) do
    socket =
      if reset_page do
        socket
        |> assign(:loading, true)
        |> assign(:current_page, 1)
      else
        assign(socket, :loading, true)
      end

    filters = %{
      search_query: socket.assigns.search_query,
      country: socket.assigns.selected_country,
      year: socket.assigns.selected_year,
      category: socket.assigns.selected_category,
      spoken_language: socket.assigns.selected_spoken_language,
      translation_language: socket.assigns.selected_translation_language,
      sort_by: socket.assigns.sort_by,
      page: socket.assigns.current_page,
      per_page: socket.assigns.per_page
    }

    socket =
      case fetch_talks(filters) do
        {:ok, talks, total} ->
          socket
          |> stream(:talks, talks, reset: true)
          |> assign(:total_results, total)
          |> assign(:talks_empty?, talks == [])
          |> assign(:loading, false)
          |> assign(:error, nil)

        {:error, reason} ->
          socket
          |> stream(:talks, [], reset: true)
          |> assign(:talks_empty?, true)
          |> assign(:loading, false)
          |> assign(:error, reason)
      end

    {:noreply, socket}
  end

  defp map_locale_to_api_code(locale) do
    case locale do
      "en" -> ""
      "ro" -> "ro"
      "de" -> "de"
      "es" -> "es"
      "fr" -> "fr"
      "it" -> "it"
      _ -> ""
    end
  end

  defp page_numbers(current_page, total_pages) do
    cond do
      total_pages <= 7 ->
        Enum.to_list(1..total_pages)

      current_page <= 4 ->
        [1, 2, 3, 4, 5, "...", total_pages]

      current_page >= total_pages - 3 ->
        [
          1,
          "...",
          total_pages - 4,
          total_pages - 3,
          total_pages - 2,
          total_pages - 1,
          total_pages
        ]

      true ->
        [1, "...", current_page - 1, current_page, current_page + 1, "...", total_pages]
    end
  end

  defp talk_card(assigns) do
    ~H"""
    <div class="group relative bg-gradient-to-br from-base-200 to-base-300 rounded-xl overflow-hidden border border-base-content/10 hover:border-primary/50 transition-all duration-300 hover:shadow-2xl hover:shadow-primary/10 hover:-translate-y-1 flex flex-col h-full">
      <%!-- Decorative gradient overlay --%>
      <div class="absolute inset-0 bg-gradient-to-br from-warning/5 to-accent/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
      </div>

      <%!-- Content --%>
      <div class="relative p-5 sm:p-6 flex flex-col flex-1">
        <%!-- Duration badge --%>
        <%= if duration = Map.get(@talk, "duration") do %>
          <div class="flex justify-end mb-3">
            <span class="inline-flex items-center gap-1 px-2 py-1 bg-accent/10 text-accent rounded-md text-xs font-medium border border-accent/20">
              <.icon name="hero-clock" class="w-3 h-3" />
              {format_duration(duration)}
            </span>
          </div>
        <% end %>

        <%!-- Title --%>
        <h3 class="text-lg sm:text-xl font-bold text-base-content mb-3 line-clamp-2 min-h-[3.5rem] leading-tight">
          {Map.get(@talk, "title", "Untitled")}
        </h3>

        <%!-- Year and Location --%>
        <div class="flex items-center gap-2 text-sm text-base-content/60 mb-4 flex-wrap">
          <%= if date = Map.get(@talk, "date") do %>
            <span class="font-semibold text-primary">{String.slice(date, 0, 4)}</span>
          <% end %>
          <%= if Map.get(@talk, "date") && Map.get(@talk, "country") do %>
            <span class="text-base-content/30">•</span>
          <% end %>
          <%= if country = Map.get(@talk, "country") do %>
            <span class="line-clamp-1">{country}</span>
          <% end %>
        </div>

        <%!-- Category badge --%>
        <%= if category = Map.get(@talk, "category") do %>
          <div class="mb-3">
            <span class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-base-content/5 text-base-content/70 rounded-lg text-xs font-medium border border-base-content/10">
              <.icon name="hero-tag" class="w-3.5 h-3.5" />
              {category}
            </span>
          </div>
        <% end %>

        <%!-- Spoken languages --%>
        <%= case Map.get(@talk, "spoken_languages") do %>
          <% spoken_languages when is_list(spoken_languages) and spoken_languages != [] -> %>
            <div class="flex items-center gap-2 text-sm text-base-content/60 mb-3">
              <.icon name="hero-language" class="w-4 h-4 text-base-content/40" />
              <span class="line-clamp-1 font-medium">{Enum.join(spoken_languages, ", ")}</span>
            </div>
          <% _ -> %>
        <% end %>

        <%!-- Subtitles section --%>
        <%= case Map.get(@talk, "video_subtitles") do %>
          <% subtitles when is_list(subtitles) and subtitles != [] -> %>
            <div class="mb-4 pb-4 border-b border-base-content/10">
              <div class="flex items-center gap-2 mb-2">
                <.icon name="hero-language" class="w-4 h-4 text-base-content/40" />
                <span class="text-xs text-base-content/50 font-medium uppercase tracking-wide">
                  {gettext("Subtitles Available")}
                </span>
              </div>
              <div class="flex flex-nowrap gap-1.5 overflow-x-auto scrollbar-hide">
                <%= for subtitle <- Enum.take(subtitles, 6) do %>
                  <span class="px-2 py-1 bg-base-100/50 text-base-content/70 rounded-md text-xs font-medium border border-base-content/10 whitespace-nowrap flex-shrink-0">
                    {String.upcase(subtitle)}
                  </span>
                <% end %>
                <%= if length(subtitles) > 6 do %>
                  <span class="px-2 py-1 text-base-content/50 text-xs font-medium whitespace-nowrap flex-shrink-0">
                    +{length(subtitles) - 6} {gettext("more")}
                  </span>
                <% end %>
              </div>
            </div>
          <% _ -> %>
        <% end %>

        <%!-- Spacer --%>
        <div class="flex-1"></div>

        <%!-- Action button --%>
        <%= if web_url = Map.get(@talk, "web_url") do %>
          <a
            href={web_url}
            target="_blank"
            rel="noopener noreferrer"
            class="mt-4 w-full inline-flex items-center justify-center gap-2 px-4 py-3 bg-gradient-to-r from-primary to-primary/80 hover:from-primary/90 hover:to-primary/70 text-primary-content rounded-lg transition-all duration-200 text-sm font-semibold shadow-lg shadow-primary/20 group-hover:shadow-primary/40"
          >
            <span>{gettext("Watch Talk")}</span>
            <.icon name="hero-play" class="w-4 h-4" />
          </a>
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8">
          <div class="mb-4 sm:mb-6 text-center">
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-3">
              {gettext("Sahaja Yoga Talks")}
            </h1>
            <p class="text-base sm:text-lg text-base-content/60 max-w-2xl mx-auto">
              {gettext("Explore spiritual teachings and wisdom")}
            </p>
          </div>

          <%!-- Search and Filters --%>
          <div class="bg-gradient-to-br from-base-200/80 to-base-300/80 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-base-content/10 shadow-xl">
            <form phx-change="apply_all_filters" phx-debounce="300">
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4">
                <%!-- Search --%>
                <div class="sm:col-span-2 lg:col-span-2">
                  <label class="block text-xs sm:text-sm font-semibold text-base-content/80 mb-2 flex items-center gap-2">
                    <.icon name="hero-magnifying-glass" class="w-4 h-4 text-primary" />
                    {gettext("Search")}
                  </label>
                  <div class="relative">
                    <input
                      type="text"
                      name="search"
                      value={@search_query}
                      placeholder={gettext("Search talks...")}
                      phx-debounce="500"
                      class="w-full px-4 py-3 pl-11 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content placeholder-base-content/40 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all"
                    />
                    <.icon
                      name="hero-magnifying-glass"
                      class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/40"
                    />
                  </div>
                </div>

                <%!-- Sort By --%>
                <div>
                  <label class="block text-xs sm:text-sm font-semibold text-base-content/80 mb-2 flex items-center gap-2">
                    <.icon name="hero-arrows-up-down" class="w-4 h-4 text-accent" />
                    {gettext("Sort By")}
                  </label>
                  <select
                    name="sort_by"
                    value={@sort_by}
                    class="w-full px-4 py-3 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all cursor-pointer"
                  >
                    <option value="relevance">{gettext("Relevance")}</option>
                    <option value="date_desc">{gettext("Newest")}</option>
                    <option value="date_asc">{gettext("Oldest")}</option>
                  </select>
                </div>

                <%!-- Translation Language Filter --%>
                <div>
                  <label class="block text-xs sm:text-sm font-semibold text-base-content/80 mb-2 flex items-center gap-2">
                    <.icon name="hero-language" class="w-4 h-4 text-success" />
                    {gettext("Translation Language")}
                  </label>
                  <select
                    name="translation_language"
                    value={@selected_translation_language}
                    class="w-full px-4 py-3 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all cursor-pointer"
                  >
                    <option value="" selected={@selected_translation_language == ""}>
                      {gettext("English (Default)")}
                    </option>
                    <%= for lang <- @translation_languages do %>
                      <option value={lang.code} selected={@selected_translation_language == lang.code}>
                        {lang.name} ({lang.count})
                      </option>
                    <% end %>
                  </select>
                </div>

                <%!-- Year Filter --%>
                <div>
                  <label class="block text-xs sm:text-sm font-semibold text-base-content/80 mb-2 flex items-center gap-2">
                    <.icon name="hero-calendar" class="w-4 h-4 text-warning" />
                    {gettext("Year")}
                  </label>
                  <select
                    name="year"
                    value={@selected_year}
                    class="w-full px-4 py-3 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all cursor-pointer"
                  >
                    <option value="">{gettext("All Years")}</option>
                    <%= for year <- @years do %>
                      <option value={year}>
                        {year}
                      </option>
                    <% end %>
                  </select>
                </div>
              </div>

              <%!-- Advanced Filters Toggle --%>
              <div class="mt-3 sm:mt-4">
                <button
                  type="button"
                  phx-click="toggle_advanced_filters"
                  class="text-xs sm:text-sm text-primary hover:text-primary/80 transition-colors flex items-center gap-2"
                >
                  <.icon
                    name={if @show_advanced_filters, do: "hero-chevron-up", else: "hero-chevron-down"}
                    class="w-3 h-3 sm:w-4 sm:h-4"
                  />
                  <span>
                    {if @show_advanced_filters, do: gettext("Hide"), else: gettext("Show")} {gettext(
                      "Advanced Filters"
                    )}
                  </span>
                </button>
              </div>

              <%!-- Advanced Filters --%>
              <%= if @show_advanced_filters do %>
                <div class="mt-3 sm:mt-4 pt-3 sm:pt-4 border-t border-base-content/10">
                  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
                    <%!-- Country Filter --%>
                    <div>
                      <label class="block text-xs sm:text-sm font-medium text-base-content/80 mb-1 sm:mb-2">
                        {gettext("Country")}
                      </label>
                      <select
                        name="country"
                        value={@selected_country}
                        class="w-full px-3 sm:px-4 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                      >
                        <option value="">{gettext("All Countries")}</option>
                        <%= for country <- @countries do %>
                          <option value={country}>
                            {country}
                          </option>
                        <% end %>
                      </select>
                    </div>

                    <%!-- Category Filter --%>
                    <div>
                      <label class="block text-xs sm:text-sm font-medium text-base-content/80 mb-1 sm:mb-2">
                        {gettext("Category")}
                      </label>
                      <select
                        name="category"
                        value={@selected_category}
                        class="w-full px-3 sm:px-4 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                      >
                        <option value="">{gettext("All Categories")}</option>
                        <%= for category <- @categories do %>
                          <option value={category}>
                            {category}
                          </option>
                        <% end %>
                      </select>
                    </div>

                    <%!-- Spoken Language Filter --%>
                    <div>
                      <label class="block text-xs sm:text-sm font-medium text-base-content/80 mb-1 sm:mb-2">
                        {gettext("Spoken Language")}
                      </label>
                      <select
                        name="spoken_language"
                        value={@selected_spoken_language}
                        class="w-full px-3 sm:px-4 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                      >
                        <option value="">{gettext("All Languages")}</option>
                        <%= for language <- @spoken_languages do %>
                          <option value={language}>
                            {language}
                          </option>
                        <% end %>
                      </select>
                    </div>
                  </div>
                </div>
              <% end %>
            </form>

            <%!-- Active filters and clear button --%>
            <%= if @search_query != "" or @selected_country != "" or @selected_year != "" or @selected_category != "" or @selected_spoken_language != "" or @selected_translation_language != "" do %>
              <div class="mt-3 sm:mt-4 flex items-center gap-2 flex-wrap">
                <span class="text-xs sm:text-sm text-base-content/60">
                  {gettext("Active filters:")}
                </span>
                <%= if @search_query != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-primary text-primary-content text-xs sm:text-sm rounded-full group">
                    <span>{gettext("Search")}: {@search_query}</span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="search"
                      class="hover:bg-primary-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear search filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <%= if @selected_country != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-primary text-primary-content text-xs sm:text-sm rounded-full">
                    <span>{@selected_country}</span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="country"
                      class="hover:bg-primary-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear country filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <%= if @selected_year != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-primary text-primary-content text-xs sm:text-sm rounded-full">
                    <span>{@selected_year}</span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="year"
                      class="hover:bg-primary-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear year filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <%= if @selected_category != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-primary text-primary-content text-xs sm:text-sm rounded-full">
                    <span>{@selected_category}</span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="category"
                      class="hover:bg-primary-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear category filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <%= if @selected_spoken_language != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-primary text-primary-content text-xs sm:text-sm rounded-full">
                    <span>{@selected_spoken_language}</span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="spoken_language"
                      class="hover:bg-primary-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear spoken language filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <%= if @selected_translation_language != "" do %>
                  <span class="inline-flex items-center gap-1 px-2 sm:px-3 py-1 bg-accent text-accent-content text-xs sm:text-sm rounded-full">
                    <span>
                      {Enum.find(@translation_languages, fn l ->
                        l.code == @selected_translation_language
                      end)
                      |> case do
                        %{name: name} -> name
                        _ -> @selected_translation_language
                      end}
                    </span>
                    <button
                      type="button"
                      phx-click="clear_filter"
                      phx-value-filter="translation_language"
                      class="hover:bg-accent-content/20 rounded-full p-0.5 transition-colors"
                      aria-label={gettext("Clear translation language filter")}
                    >
                      <.icon name="hero-x-mark" class="w-3 h-3" />
                    </button>
                  </span>
                <% end %>
                <button
                  type="button"
                  phx-click="clear_filters"
                  class="px-2 sm:px-3 py-1 bg-base-100 hover:bg-error/20 hover:text-error text-base-content text-xs sm:text-sm rounded-full transition-colors flex items-center gap-1"
                >
                  <.icon name="hero-x-mark" class="w-3 h-3" />
                  {gettext("Clear all")}
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <%= cond do %>
          <%!-- Loading state with skeleton cards --%>
          <% @loading -> %>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
              <%= for _i <- 1..6 do %>
                <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-xl overflow-hidden border border-base-content/10 flex flex-col h-full animate-pulse">
                  <div class="p-5 sm:p-6 flex flex-col flex-1">
                    <%!-- Duration badge skeleton --%>
                    <div class="flex justify-end mb-3">
                      <div class="skeleton h-6 w-16 rounded-md"></div>
                    </div>
                    <%!-- Title skeleton --%>
                    <div class="skeleton h-6 w-full mb-2 rounded"></div>
                    <div class="skeleton h-6 w-3/4 mb-3 rounded"></div>
                    <%!-- Year and Location skeleton --%>
                    <div class="flex items-center gap-2 mb-4">
                      <div class="skeleton h-4 w-12 rounded"></div>
                      <div class="skeleton h-4 w-24 rounded"></div>
                    </div>
                    <%!-- Category badge skeleton --%>
                    <div class="skeleton h-8 w-32 mb-3 rounded-lg"></div>
                    <%!-- Spacer --%>
                    <div class="flex-1"></div>
                    <%!-- Action button skeleton --%>
                    <div class="skeleton h-12 w-full mt-4 rounded-lg"></div>
                  </div>
                </div>
              <% end %>
            </div>
            <div class="text-center mt-6">
              <p class="text-base-content/60 text-sm flex items-center justify-center gap-2">
                <.icon name="hero-arrow-path" class="w-4 h-4 animate-spin" />
                {gettext("Loading talks...")}
              </p>
            </div>
            <%!-- Error state --%>
          <% @error -> %>
            <div class="bg-error/10 border border-error/50 rounded-lg p-6 text-center">
              <.icon name="hero-exclamation-triangle" class="w-12 h-12 text-error mx-auto mb-4" />
              <h3 class="text-xl font-semibold text-error mb-2">
                {gettext("Error Loading Talks")}
              </h3>
              <p class="text-base-content/80">{@error}</p>
            </div>
            <%!-- Empty state --%>
          <% @talks_empty? -> %>
            <div class="bg-base-200 rounded-lg p-12 text-center">
              <.icon name="hero-document-text" class="w-16 h-16 text-base-content/30 mx-auto mb-4" />
              <p class="text-base-content/60 text-lg">{gettext("No talks available")}</p>
            </div>
            <%!-- Talks grid --%>
          <% true -> %>
            <div
              id="talks-list"
              phx-update="stream"
              class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6"
            >
              <%= for {id, talk} <- @streams.talks do %>
                <div id={id}>
                  <.talk_card talk={talk} />
                </div>
              <% end %>
            </div>

            <%!-- Pagination --%>
            <div class="mt-6 sm:mt-8">
              <div class="flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-4">
                <%!-- Stats --%>
                <p class="text-base-content/60 text-xs sm:text-sm">
                  {gettext("Showing")}
                  <span class="text-base-content font-semibold">
                    {(@current_page - 1) * @per_page + 1}
                  </span>
                  {gettext("to")}
                  <span class="text-base-content font-semibold">
                    {min(@current_page * @per_page, @total_results)}
                  </span>
                  {gettext("of")}
                  <span class="text-base-content font-semibold">{@total_results}</span>
                  {ngettext("talk", "talks", @total_results)}
                </p>

                <%!-- Pagination controls --%>
                <%= if @total_results > @per_page do %>
                  <div class="flex items-center gap-1 sm:gap-2">
                    <%!-- Previous button --%>
                    <button
                      phx-click="prev_page"
                      disabled={@current_page == 1}
                      class={[
                        "px-2 sm:px-4 py-2 rounded-lg transition-colors flex items-center gap-1 sm:gap-2 text-xs sm:text-sm",
                        @current_page == 1 &&
                          "opacity-50 cursor-not-allowed bg-base-100 text-base-content/40",
                        @current_page > 1 && "bg-base-100 hover:bg-base-200 text-base-content"
                      ]}
                    >
                      <.icon name="hero-chevron-left" class="w-3 h-3 sm:w-4 sm:h-4" />
                      <span class="hidden sm:inline">{gettext("Previous")}</span>
                    </button>

                    <%!-- Page numbers --%>
                    <div class="flex items-center gap-1">
                      <%= for page_num <- page_numbers(@current_page, ceil(@total_results / @per_page)) do %>
                        <%= if page_num == "..." do %>
                          <span class="px-2 sm:px-3 py-2 text-base-content/40 text-xs sm:text-sm">
                            ...
                          </span>
                        <% else %>
                          <button
                            phx-click="goto_page"
                            phx-value-page={page_num}
                            class={[
                              "px-2 sm:px-3 py-2 rounded-lg transition-colors text-xs sm:text-sm",
                              @current_page == page_num &&
                                "bg-primary text-primary-content font-semibold",
                              @current_page != page_num &&
                                "bg-base-100 hover:bg-base-200 text-base-content/80"
                            ]}
                          >
                            {page_num}
                          </button>
                        <% end %>
                      <% end %>
                    </div>

                    <%!-- Next button --%>
                    <button
                      phx-click="next_page"
                      disabled={@current_page >= ceil(@total_results / @per_page)}
                      class={[
                        "px-2 sm:px-4 py-2 rounded-lg transition-colors flex items-center gap-1 sm:gap-2 text-xs sm:text-sm",
                        @current_page >= ceil(@total_results / @per_page) &&
                          "opacity-50 cursor-not-allowed bg-base-100 text-base-content/40",
                        @current_page < ceil(@total_results / @per_page) &&
                          "bg-base-100 hover:bg-base-200 text-base-content"
                      ]}
                    >
                      <span class="hidden sm:inline">{gettext("Next")}</span>
                      <.icon name="hero-chevron-right" class="w-3 h-3 sm:w-4 sm:h-4" />
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end
