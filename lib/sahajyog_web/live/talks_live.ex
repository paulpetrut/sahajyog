defmodule SahajyogWeb.TalksLive do
  use SahajyogWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Talks")
      |> assign(:search_query, "")
      |> assign(:selected_country, "")
      |> assign(:selected_year, "")
      |> assign(:selected_category, "")
      |> assign(:selected_spoken_language, "")
      |> assign(:sort_by, "date_asc")
      |> assign(:countries, [])
      |> assign(:years, [])
      |> assign(:categories, [])
      |> assign(:spoken_languages, [])
      |> assign(:total_results, 0)
      |> assign(:talks_empty?, true)
      |> assign(:show_advanced_filters, false)
      |> assign(:current_page, 1)
      |> assign(:per_page, 21)
      |> assign(:loading, false)
      |> assign(:error, nil)
      |> stream_configure(:talks, dom_id: fn talk -> "talk-#{talk["id"]}" end)
      |> stream(:talks, [])

    socket =
      if connected?(socket) do
        socket = load_filter_options(socket)

        case fetch_talks(%{}) do
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

            socket
            |> stream(:talks, [], reset: true)
            |> assign(:talks_empty?, false)
            |> assign(:loading, false)
            |> assign(:error, reason)
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
    countries =
      case Sahajyog.ExternalApi.fetch_countries() do
        {:ok, countries} -> countries
        {:error, _} -> []
      end

    years =
      case Sahajyog.ExternalApi.fetch_years() do
        {:ok, years} -> years
        {:error, _} -> []
      end

    categories =
      case Req.get("https://learnsahajayoga.org/api/meta/categories",
             connect_options: [timeout: 5000],
             receive_timeout: 8000,
             retry: :transient
           ) do
        {:ok, %{status: 200, body: %{"languages" => languages}}} when is_list(languages) ->
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

        _ ->
          []
      end

    spoken_languages =
      case Req.get("https://learnsahajayoga.org/api/meta/spoken-languages",
             connect_options: [timeout: 5000],
             receive_timeout: 8000,
             retry: :transient
           ) do
        {:ok, %{status: 200, body: %{"spoken_languages" => languages}}} when is_list(languages) ->
          languages
          |> Enum.sort_by(fn lang -> -lang["talk_count"] end)
          |> Enum.map(fn lang -> lang["language_name"] end)

        _ ->
          []
      end

    socket
    |> assign(:countries, countries)
    |> assign(:years, years)
    |> assign(:categories, categories)
    |> assign(:spoken_languages, spoken_languages)
  end

  def handle_event("apply_all_filters", params, socket) do
    socket =
      socket
      |> assign(:search_query, params["search"] || "")
      |> assign(:selected_country, params["country"] || "")
      |> assign(:selected_year, params["year"] || "")
      |> assign(:selected_category, params["category"] || "")
      |> assign(:selected_spoken_language, params["spoken_language"] || "")
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
      |> assign(:sort_by, "date_asc")

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
    {:noreply, assign(socket, :locale, locale)}
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

  defp format_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m"
      minutes > 0 -> "#{minutes}m #{secs}s"
      true -> "#{secs}s"
    end
  end

  defp format_duration(_), do: nil

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
    <div class="bg-gray-800 rounded-lg overflow-hidden border border-gray-700 hover:border-blue-500 transition-all hover:shadow-lg hover:shadow-blue-500/20 group flex flex-col">
      <div class="p-4 sm:p-6 flex flex-col flex-1">
        <%!-- Title - fixed height --%>
        <h3 class="text-lg sm:text-xl font-semibold text-white mb-2 sm:mb-3 group-hover:text-blue-400 transition-colors line-clamp-2 min-h-[3rem] sm:min-h-[3.5rem]">
          {Map.get(@talk, "title", "Untitled")}
        </h3>

        <%!-- Metadata --%>
        <div class="space-y-1.5 sm:space-y-2 text-xs sm:text-sm text-gray-400 mb-3 sm:mb-4">
          <%= if date = Map.get(@talk, "date") do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-calendar" class="w-4 h-4 flex-shrink-0" />
              <span>{String.slice(date, 0, 4)}</span>
            </div>
          <% end %>

          <%= if category = Map.get(@talk, "category") do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-tag" class="w-4 h-4 flex-shrink-0" />
              <span class="line-clamp-1">{category}</span>
            </div>
          <% end %>

          <%= if country = Map.get(@talk, "country") do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-map-pin" class="w-4 h-4 flex-shrink-0" />
              <span class="line-clamp-1">{country}</span>
            </div>
          <% end %>

          <%= case Map.get(@talk, "spoken_languages") do %>
            <% spoken_languages when is_list(spoken_languages) and spoken_languages != [] -> %>
              <div class="flex items-center gap-2">
                <.icon name="hero-language" class="w-4 h-4 flex-shrink-0" />
                <span class="line-clamp-1">{Enum.join(spoken_languages, ", ")}</span>
              </div>
            <% _ -> %>
          <% end %>

          <%= if duration = Map.get(@talk, "duration") do %>
            <div class="flex items-center gap-2">
              <.icon name="hero-clock" class="w-4 h-4" />
              <span>{format_duration(duration)}</span>
            </div>
          <% end %>
        </div>

        <%!-- Action button - pushed to bottom --%>
        <%= if web_url = Map.get(@talk, "web_url") do %>
          <a
            href={web_url}
            target="_blank"
            rel="noopener noreferrer"
            class="mt-auto inline-flex items-center gap-2 px-3 sm:px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-xs sm:text-sm font-medium self-start"
          >
            <span>{gettext("View Talk")}</span>
            <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3 sm:w-4 sm:h-4" />
          </a>
        <% end %>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8">
          <div class="mb-4 sm:mb-6">
            <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-white mb-2">
              {gettext("Sahaja Yoga Talks")}
            </h1>
            <p class="text-sm sm:text-base text-gray-400">
              {gettext("Explore spiritual teachings and wisdom")}
            </p>
          </div>

          <%!-- Search and Filters --%>
          <div class="bg-gray-800 rounded-lg p-4 sm:p-6 border border-gray-700">
            <form phx-change="apply_all_filters">
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4">
                <%!-- Search --%>
                <div class="sm:col-span-2 lg:col-span-2">
                  <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                    {gettext("Search")}
                  </label>
                  <div class="relative">
                    <input
                      type="text"
                      name="search"
                      value={@search_query}
                      placeholder={gettext("Search talks...")}
                      class="w-full px-3 sm:px-4 py-2 pl-9 sm:pl-10 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    />
                    <.icon
                      name="hero-magnifying-glass"
                      class="absolute left-2 sm:left-3 top-1/2 -translate-y-1/2 w-4 h-4 sm:w-5 sm:h-5 text-gray-500"
                    />
                  </div>
                </div>

                <%!-- Sort By --%>
                <div>
                  <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                    {gettext("Sort By")}
                  </label>
                  <select
                    name="sort_by"
                    value={@sort_by}
                    class="w-full px-3 sm:px-4 py-2 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="relevance">{gettext("Relevance")}</option>
                    <option value="date_desc">{gettext("Newest")}</option>
                    <option value="date_asc">{gettext("Oldest")}</option>
                  </select>
                </div>

                <%!-- Country Filter --%>
                <div>
                  <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                    {gettext("Country")}
                  </label>
                  <select
                    name="country"
                    value={@selected_country}
                    class="w-full px-3 sm:px-4 py-2 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">{gettext("All Countries")}</option>
                    <%= for country <- @countries do %>
                      <option value={country}>
                        {country}
                      </option>
                    <% end %>
                  </select>
                </div>

                <%!-- Year Filter --%>
                <div>
                  <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                    {gettext("Year")}
                  </label>
                  <select
                    name="year"
                    value={@selected_year}
                    class="w-full px-3 sm:px-4 py-2 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
                  class="text-xs sm:text-sm text-blue-400 hover:text-blue-300 transition-colors flex items-center gap-2"
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
                <div class="mt-3 sm:mt-4 pt-3 sm:pt-4 border-t border-gray-700">
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
                    <%!-- Category Filter --%>
                    <div>
                      <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                        {gettext("Category")}
                      </label>
                      <select
                        name="category"
                        value={@selected_category}
                        class="w-full px-3 sm:px-4 py-2 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
                      <label class="block text-xs sm:text-sm font-medium text-gray-300 mb-1 sm:mb-2">
                        {gettext("Spoken Language")}
                      </label>
                      <select
                        name="spoken_language"
                        value={@selected_spoken_language}
                        class="w-full px-3 sm:px-4 py-2 bg-gray-900 border border-gray-600 rounded-lg text-sm sm:text-base text-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
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
            <%= if @search_query != "" or @selected_country != "" or @selected_year != "" or @selected_category != "" or @selected_spoken_language != "" do %>
              <div class="mt-3 sm:mt-4 flex items-center gap-2 flex-wrap">
                <span class="text-xs sm:text-sm text-gray-400">{gettext("Active filters:")}</span>
                <%= if @search_query != "" do %>
                  <span class="px-2 sm:px-3 py-1 bg-blue-600 text-white text-xs sm:text-sm rounded-full">
                    {gettext("Search")}: {@search_query}
                  </span>
                <% end %>
                <%= if @selected_country != "" do %>
                  <span class="px-2 sm:px-3 py-1 bg-blue-600 text-white text-xs sm:text-sm rounded-full">
                    {@selected_country}
                  </span>
                <% end %>
                <%= if @selected_year != "" do %>
                  <span class="px-2 sm:px-3 py-1 bg-blue-600 text-white text-xs sm:text-sm rounded-full">
                    {@selected_year}
                  </span>
                <% end %>
                <%= if @selected_category != "" do %>
                  <span class="px-2 sm:px-3 py-1 bg-blue-600 text-white text-xs sm:text-sm rounded-full">
                    {@selected_category}
                  </span>
                <% end %>
                <%= if @selected_spoken_language != "" do %>
                  <span class="px-2 sm:px-3 py-1 bg-blue-600 text-white text-xs sm:text-sm rounded-full">
                    {@selected_spoken_language}
                  </span>
                <% end %>
                <button
                  phx-click="clear_filters"
                  class="px-2 sm:px-3 py-1 bg-gray-700 hover:bg-gray-600 text-white text-xs sm:text-sm rounded-full transition-colors"
                >
                  {gettext("Clear all")}
                </button>
              </div>
            <% end %>
          </div>
        </div>

        <%= cond do %>
          <%!-- Loading state --%>
          <% @loading -> %>
            <div class="flex items-center justify-center py-20">
              <div class="text-center">
                <.icon
                  name="hero-arrow-path"
                  class="w-12 h-12 text-blue-500 animate-spin mx-auto mb-4"
                />
                <p class="text-gray-400 text-lg">{gettext("Loading talks...")}</p>
              </div>
            </div>
            <%!-- Error state --%>
          <% @error -> %>
            <div class="bg-red-900/20 border border-red-500/50 rounded-lg p-6 text-center">
              <.icon name="hero-exclamation-triangle" class="w-12 h-12 text-red-500 mx-auto mb-4" />
              <h3 class="text-xl font-semibold text-red-400 mb-2">
                {gettext("Error Loading Talks")}
              </h3>
              <p class="text-gray-300">{@error}</p>
            </div>
            <%!-- Empty state --%>
          <% @talks_empty? -> %>
            <div class="bg-gray-800 rounded-lg p-12 text-center">
              <.icon name="hero-document-text" class="w-16 h-16 text-gray-600 mx-auto mb-4" />
              <p class="text-gray-400 text-lg">{gettext("No talks available")}</p>
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
                <p class="text-gray-400 text-xs sm:text-sm">
                  {gettext("Showing")}
                  <span class="text-white font-semibold">
                    {(@current_page - 1) * @per_page + 1}
                  </span>
                  {gettext("to")}
                  <span class="text-white font-semibold">
                    {min(@current_page * @per_page, @total_results)}
                  </span>
                  {gettext("of")} <span class="text-white font-semibold">{@total_results}</span>
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
                          "opacity-50 cursor-not-allowed bg-gray-700 text-gray-500",
                        @current_page > 1 && "bg-gray-700 hover:bg-gray-600 text-white"
                      ]}
                    >
                      <.icon name="hero-chevron-left" class="w-3 h-3 sm:w-4 sm:h-4" />
                      <span class="hidden sm:inline">{gettext("Previous")}</span>
                    </button>

                    <%!-- Page numbers --%>
                    <div class="flex items-center gap-1">
                      <%= for page_num <- page_numbers(@current_page, ceil(@total_results / @per_page)) do %>
                        <%= if page_num == "..." do %>
                          <span class="px-2 sm:px-3 py-2 text-gray-500 text-xs sm:text-sm">...</span>
                        <% else %>
                          <button
                            phx-click="goto_page"
                            phx-value-page={page_num}
                            class={[
                              "px-2 sm:px-3 py-2 rounded-lg transition-colors text-xs sm:text-sm",
                              @current_page == page_num &&
                                "bg-blue-600 text-white font-semibold",
                              @current_page != page_num &&
                                "bg-gray-700 hover:bg-gray-600 text-gray-300"
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
                          "opacity-50 cursor-not-allowed bg-gray-700 text-gray-500",
                        @current_page < ceil(@total_results / @per_page) &&
                          "bg-gray-700 hover:bg-gray-600 text-white"
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
