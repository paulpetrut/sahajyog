defmodule SahajyogWeb.EventsLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events

  @per_page 12
  @time_ranges [
    {"1 month", "1_month"},
    {"3 months", "3_months"},
    {"6 months", "6_months"},
    {"1 year", "1_year"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Events")
      |> assign(:time_ranges, @time_ranges)
      |> assign(:selected_time_range, nil)
      |> assign(:selected_month, nil)
      |> assign(:selected_country, nil)
      |> assign(:selected_city, nil)
      |> assign(:search_query, "")
      |> assign(:current_page, 1)
      |> assign(:per_page, @per_page)
      # Default filter
      |> assign(:filter, "all")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filter = params["filter"] || "all"
    socket = assign(socket, :filter, filter)
    socket = load_events(socket)
    {:noreply, socket}
  end

  defp load_events(socket) do
    if connected?(socket) do
      user_id = socket.assigns.current_scope.user.id

      events =
        case socket.assigns.filter do
          "my_events" -> Events.list_my_events(user_id)
          "past" -> Events.list_past_public_events()
          _ -> Events.list_events_for_user(user_id)
        end

      countries = extract_countries(events)
      cities = extract_cities(events)
      months = if socket.assigns.filter == "past", do: extract_months(events), else: []

      socket
      |> assign(:all_events, events)
      |> assign(:total_results, length(events))
      |> assign(:events, paginate_events(events, 1, @per_page))
      |> assign(:countries, countries)
      |> assign(:cities, cities)
      |> assign(:months, months)
      |> assign(:loading, false)
    else
      socket
      |> assign(:events, nil)
      |> assign(:all_events, [])
      |> assign(:countries, [])
      |> assign(:cities, [])
      |> assign(:months, [])
      |> assign(:loading, true)
      |> assign(:total_results, 0)
    end
  end

  @impl true
  def handle_event("filter_time", %{"time_range" => time_range}, socket) do
    time_range = if time_range == "", do: nil, else: time_range
    socket = apply_filters(socket, %{time_range: time_range})
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_month", %{"month" => month}, socket) do
    month = if month == "", do: nil, else: month
    socket = apply_filters(socket, %{month: month})
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_country", %{"country" => country}, socket) do
    country = if country == "", do: nil, else: country
    socket = apply_filters(socket, %{country: country, city: nil})
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_city", %{"city" => city}, socket) do
    city = if city == "", do: nil, else: city
    socket = apply_filters(socket, %{city: city})
    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    socket = apply_filters(socket, %{search: query})
    {:noreply, socket}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    all_events = socket.assigns.all_events

    {:noreply,
     socket
     |> assign(:selected_time_range, nil)
     |> assign(:selected_country, nil)
     |> assign(:selected_city, nil)
     |> assign(:search_query, "")
     |> assign(:current_page, 1)
     |> assign(:total_results, length(all_events))
     |> assign(:events, paginate_events(all_events, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("goto_page", %{"page" => page}, socket) do
    page_num = String.to_integer(page)
    filtered_events = get_filtered_events(socket)

    {:noreply,
     socket
     |> assign(:current_page, page_num)
     |> assign(:events, paginate_events(filtered_events, page_num, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("next_page", _params, socket) do
    total_pages = ceil(socket.assigns.total_results / socket.assigns.per_page)
    current_page = socket.assigns.current_page

    if current_page < total_pages do
      next_page = current_page + 1
      filtered_events = get_filtered_events(socket)

      {:noreply,
       socket
       |> assign(:current_page, next_page)
       |> assign(:events, paginate_events(filtered_events, next_page, socket.assigns.per_page))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_page", _params, socket) do
    current_page = socket.assigns.current_page

    if current_page > 1 do
      prev_page = current_page - 1
      filtered_events = get_filtered_events(socket)

      {:noreply,
       socket
       |> assign(:current_page, prev_page)
       |> assign(:events, paginate_events(filtered_events, prev_page, socket.assigns.per_page))}
    else
      {:noreply, socket}
    end
  end

  defp apply_filters(socket, new_filters) do
    socket =
      socket
      |> maybe_assign(:selected_time_range, new_filters[:time_range])
      |> maybe_assign(:selected_month, new_filters[:month])
      |> maybe_assign(:selected_country, new_filters[:country])
      |> maybe_assign(:selected_city, new_filters[:city])
      |> maybe_assign(:search_query, new_filters[:search])
      |> assign(:current_page, 1)

    filtered_events = get_filtered_events(socket)

    socket
    |> assign(:total_results, length(filtered_events))
    |> assign(:events, paginate_events(filtered_events, 1, socket.assigns.per_page))
  end

  defp maybe_assign(socket, _key, nil), do: socket
  defp maybe_assign(socket, key, value), do: assign(socket, key, value)

  defp get_filtered_events(socket) do
    socket.assigns.all_events
    |> filter_by_time_range(socket.assigns.selected_time_range)
    |> filter_by_month(socket.assigns.selected_month)
    |> filter_by_country(socket.assigns.selected_country)
    |> filter_by_city(socket.assigns.selected_city)
    |> filter_by_search(socket.assigns.search_query)
  end

  defp filter_by_time_range(events, nil), do: events

  defp filter_by_time_range(events, time_range) do
    today = Date.utc_today()

    end_date =
      case time_range do
        "1_month" -> Date.add(today, 30)
        "3_months" -> Date.add(today, 90)
        "6_months" -> Date.add(today, 180)
        "1_year" -> Date.add(today, 365)
        _ -> nil
      end

    if end_date do
      Enum.filter(events, fn event ->
        event.event_date && Date.compare(event.event_date, today) != :lt &&
          Date.compare(event.event_date, end_date) != :gt
      end)
    else
      events
    end
  end

  defp filter_by_month(events, nil), do: events

  defp filter_by_month(events, month_str) do
    [year_s, month_s] = String.split(month_str, "-")
    year = String.to_integer(year_s)
    month = String.to_integer(month_s)

    Enum.filter(events, fn e ->
      e.event_date && e.event_date.year == year && e.event_date.month == month
    end)
  end

  defp filter_by_country(events, nil), do: events

  defp filter_by_country(events, country) do
    Enum.filter(events, &(&1.country == country))
  end

  defp filter_by_city(events, nil), do: events

  defp filter_by_city(events, city) do
    Enum.filter(events, &(&1.city == city))
  end

  defp filter_by_search(events, nil), do: events
  defp filter_by_search(events, ""), do: events

  defp filter_by_search(events, query) do
    query = String.downcase(query)

    Enum.filter(events, fn event ->
      String.contains?(String.downcase(event.title || ""), query) ||
        String.contains?(String.downcase(event.city || ""), query) ||
        String.contains?(String.downcase(event.country || ""), query)
    end)
  end

  defp paginate_events(events, page, per_page) do
    events
    |> Enum.slice((page - 1) * per_page, per_page)
  end

  defp extract_countries(events) do
    events
    |> Enum.map(& &1.country)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_cities(events) do
    events
    |> Enum.map(& &1.city)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_months(events) do
    events
    |> Enum.map(& &1.event_date)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn date ->
      {Calendar.strftime(date, "%B %Y"),
       "#{date.year}-#{String.pad_leading("#{date.month}", 2, "0")}"}
    end)
    |> Enum.uniq()
    |> Enum.sort_by(fn {_, val} -> val end, :desc)
  end

  defp days_until(event_date) do
    today = Date.utc_today()
    Date.diff(event_date, today)
  end

  defp format_event_date(nil), do: "-"

  defp format_event_date(date) do
    Calendar.strftime(date, "%b %d, %Y")
  end

  defp event_status_class("draft"), do: "bg-warning/10 text-warning border border-warning/20"
  defp event_status_class("public"), do: "bg-success/10 text-success border border-success/20"
  defp event_status_class("cancelled"), do: "bg-error/10 text-error border border-error/20"

  defp event_status_class(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  defp filters_active?(assigns) do
    assigns.selected_time_range || assigns.selected_month || assigns.selected_country ||
      assigns.selected_city || assigns.search_query != ""
  end

  defp page_numbers(current_page, total_pages) do
    cond do
      total_pages <= 7 ->
        Enum.to_list(1..max(1, total_pages))

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

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div class="text-center sm:text-left">
            <h1 class="text-3xl sm:text-4xl font-bold text-base-content mb-2">
              {gettext("Events")}
            </h1>
            <p class="text-base text-base-content/70">
              {gettext("Discover and join upcoming Sahaja Yoga events")}
            </p>
          </div>
          <div>
            <.primary_button navigate="/events/propose" icon="hero-plus">
              {gettext("Propose Event")}
            </.primary_button>
          </div>
        </div>

        <Layouts.events_nav current_page={
          cond do
            @filter == "my_events" -> :my_events
            @filter == "past" -> :past
            true -> :list
          end
        } />

        <%!-- Filters Section --%>
        <div class="mb-6 p-4 bg-base-200/50 rounded-xl border border-base-content/10">
          <div class="flex flex-wrap gap-3 items-center">
            <%!-- Search --%>
            <div class="flex-1 min-w-[200px]">
              <form phx-change="search" phx-submit="search">
                <div class="relative">
                  <.icon
                    name="hero-magnifying-glass"
                    class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-base-content/40"
                  />
                  <input
                    type="text"
                    name="query"
                    value={@search_query}
                    placeholder={gettext("Search events...")}
                    class="w-full pl-10 pr-4 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm text-base-content placeholder-base-content/40 focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    phx-debounce="300"
                  />
                </div>
              </form>
            </div>

            <%!-- Time/Month Filter --%>
            <div class="w-full sm:w-auto">
              <%= if @filter == "past" do %>
                <select
                  name="month"
                  class="w-full px-3 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm text-base-content focus:outline-none focus:ring-2 focus:ring-primary"
                  phx-change="filter_month"
                >
                  <option value="">{gettext("All months")}</option>
                  <%= for {label, value} <- @months do %>
                    <option value={value} selected={@selected_month == value}>
                      {label}
                    </option>
                  <% end %>
                </select>
              <% else %>
                <select
                  name="time_range"
                  class="w-full px-3 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm text-base-content focus:outline-none focus:ring-2 focus:ring-primary"
                  phx-change="filter_time"
                >
                  <option value="">{gettext("All time")}</option>
                  <%= for {label, value} <- @time_ranges do %>
                    <option value={value} selected={@selected_time_range == value}>
                      {label}
                    </option>
                  <% end %>
                </select>
              <% end %>
            </div>

            <%!-- Country Filter --%>
            <%= if @countries != [] do %>
              <div class="w-full sm:w-auto">
                <select
                  name="country"
                  class="w-full px-3 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm text-base-content focus:outline-none focus:ring-2 focus:ring-primary"
                  phx-change="filter_country"
                >
                  <option value="">{gettext("All countries")}</option>
                  <%= for country <- @countries do %>
                    <option value={country} selected={@selected_country == country}>
                      {country}
                    </option>
                  <% end %>
                </select>
              </div>
            <% end %>

            <%!-- City Filter --%>
            <%= if @cities != [] do %>
              <div class="w-full sm:w-auto">
                <select
                  name="city"
                  class="w-full px-3 py-2 bg-base-100 border border-base-content/20 rounded-lg text-sm text-base-content focus:outline-none focus:ring-2 focus:ring-primary"
                  phx-change="filter_city"
                >
                  <option value="">{gettext("All cities")}</option>
                  <%= for city <- @cities do %>
                    <option value={city} selected={@selected_city == city}>
                      {city}
                    </option>
                  <% end %>
                </select>
              </div>
            <% end %>

            <%!-- Clear Filters --%>
            <%= if filters_active?(assigns) do %>
              <button
                phx-click="clear_filters"
                class="px-3 py-2 text-sm text-primary hover:text-primary/80 font-medium whitespace-nowrap"
              >
                {gettext("Clear filters")}
              </button>
            <% end %>
          </div>

          <%!-- Results Count --%>
          <%= if @events != nil do %>
            <p class="text-sm text-base-content/60 mt-3">
              {ngettext(
                "Showing %{count} event",
                "Showing %{count} events",
                @total_results,
                count: @total_results
              )}
            </p>
          <% end %>
        </div>

        <%!-- Events Grid / Loading --%>
        <%= if @loading do %>
          <.events_skeleton_grid count={6} />
        <% else %>
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
            <.card
              :for={event <- @events}
              hover
              class="group overflow-hidden sm:hover:-translate-y-1 animate-fade-in"
            >
              <.link navigate={~p"/events/#{event.slug}"} class="block">
                <div class="p-4 sm:p-6">
                  <%!-- Status & Date Badge --%>
                  <div class="flex items-center justify-between mb-3">
                    <%= if event.status != "public" do %>
                      <span class={[
                        "px-2 py-1 rounded-full text-xs font-medium",
                        event_status_class(event.status)
                      ]}>
                        {event.status}
                      </span>
                    <% else %>
                      <span class="px-2 py-1 bg-primary/10 text-primary rounded-full text-xs font-medium border border-primary/20">
                        <%= if event.event_date do %>
                          <% days = days_until(event.event_date) %>
                          <%= cond do %>
                            <% days == 0 -> %>
                              {gettext("Today")}
                            <% days == 1 -> %>
                              {gettext("Tomorrow")}
                            <% days > 0 and days <= 7 -> %>
                              {gettext("In %{days} days", days: days)}
                            <% days < 0 -> %>
                              {gettext("Past")}
                            <% true -> %>
                              {format_event_date(event.event_date)}
                          <% end %>
                        <% else %>
                          {gettext("Date TBD")}
                        <% end %>
                      </span>
                    <% end %>
                  </div>

                  <%!-- Title --%>
                  <h3 class="text-lg sm:text-xl font-bold text-base-content mb-2 line-clamp-2 group-hover:text-primary transition-colors">
                    {event.title}
                  </h3>

                  <%!-- Location --%>
                  <%= if event.city || event.country do %>
                    <div class="flex items-center gap-2 text-sm text-base-content/60 mb-3">
                      <.icon name="hero-map-pin" class="w-4 h-4" />
                      <span>
                        {[event.city, event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                      </span>
                    </div>
                  <% end %>

                  <%!-- Date & Time --%>
                  <%= if event.event_date do %>
                    <div class="flex items-center gap-2 text-sm text-base-content/60 mb-3">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      <span>{format_event_date(event.event_date)}</span>
                      <%= if event.event_time do %>
                        <span class="text-base-content/40">•</span>
                        <span>{Calendar.strftime(event.event_time, "%H:%M")}</span>
                      <% end %>
                    </div>
                  <% end %>

                  <%!-- Participants --%>
                  <%= if event.estimated_participants do %>
                    <div class="flex items-center gap-2 text-sm text-base-content/60">
                      <.icon name="hero-users" class="w-4 h-4" />
                      <span>{event.estimated_participants} {gettext("expected")}</span>
                    </div>
                  <% end %>

                  <%!-- Footer --%>
                  <div class="flex items-center justify-between text-xs text-base-content/50 pt-4 mt-4 border-t border-base-content/10">
                    <div class="flex items-center gap-2">
                      <.icon name="hero-user" class="w-3 h-3" />
                      <span>{event.user.email |> String.split("@") |> List.first()}</span>
                    </div>
                    <.icon
                      name="hero-arrow-right"
                      class="w-4 h-4 text-primary opacity-0 group-hover:opacity-100 transition-opacity"
                    />
                  </div>
                </div>
              </.link>
            </.card>
          </div>

          <%!-- Pagination --%>
          <%= if @total_results > @per_page do %>
            <div class="mt-6 sm:mt-8">
              <div class="flex flex-col sm:flex-row items-center justify-between gap-3 sm:gap-4">
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
                  {ngettext("event", "events", @total_results)}
                </p>

                <div class="flex items-center gap-1 sm:gap-2">
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
              </div>
            </div>
          <% end %>
        <% end %>

        <%!-- Empty State --%>
        <%= if @events != nil and @events == [] do %>
          <.empty_state
            icon="hero-calendar"
            title={
              if filters_active?(assigns),
                do: gettext("No events found"),
                else: gettext("No upcoming events")
            }
            description={
              if filters_active?(assigns),
                do: gettext("Try adjusting your filters"),
                else: gettext("Be the first to propose an event")
            }
          >
            <:actions>
              <%= if filters_active?(assigns) do %>
                <.secondary_button phx-click="clear_filters">
                  {gettext("Clear Filters")}
                </.secondary_button>
              <% else %>
                <.primary_button navigate="/events/propose" icon="hero-plus">
                  {gettext("Propose Event")}
                </.primary_button>
              <% end %>
            </:actions>
          </.empty_state>
        <% end %>
      </div>
    </.page_container>
    """
  end

  # Skeleton component for loading state
  defp events_skeleton_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
      <div :for={_ <- 1..@count} class="bg-base-200 rounded-xl p-6 animate-pulse">
        <div class="h-4 bg-base-300 rounded w-20 mb-4"></div>
        <div class="h-6 bg-base-300 rounded w-3/4 mb-3"></div>
        <div class="h-4 bg-base-300 rounded w-1/2 mb-2"></div>
        <div class="h-4 bg-base-300 rounded w-2/3 mb-4"></div>
        <div class="h-px bg-base-300 my-4"></div>
        <div class="flex justify-between">
          <div class="h-3 bg-base-300 rounded w-24"></div>
          <div class="h-3 bg-base-300 rounded w-16"></div>
        </div>
      </div>
    </div>
    """
  end
end
