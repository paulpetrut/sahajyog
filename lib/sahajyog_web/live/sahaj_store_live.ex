defmodule SahajyogWeb.SahajStoreLive do
  @moduledoc """
  LiveView for browsing approved store items in the SahajStore marketplace.
  """
  use SahajyogWeb, :live_view

  alias Sahajyog.Resources.R2Storage
  alias Sahajyog.Store
  alias Sahajyog.Store.StoreItem

  import SahajyogWeb.FormatHelpers, only: [truncate_text: 2]

  @default_per_page 24

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("SahajStore"))
      |> assign(:search_query, "")
      |> assign(:pricing_filter, "all")
      |> assign(:delivery_filter, "all")
      |> assign(:current_page, 1)
      |> assign(:per_page, @default_per_page)
      |> assign(:total_results, 0)
      |> assign(:user_has_items, false)

    socket =
      if connected?(socket) do
        # Subscribe to real-time updates for approved items
        Store.subscribe_to_approved_items()

        items = Store.list_approved_items()

        # Check if current user has any items
        user_has_items =
          if socket.assigns.current_scope && socket.assigns.current_scope.user do
            user_id = socket.assigns.current_scope.user.id
            Store.list_user_items(user_id) != []
          else
            false
          end

        socket
        |> assign(:all_items, items)
        |> assign(:total_results, length(items))
        |> assign(:items, paginate_items(items, 1, @default_per_page))
        |> assign(:loading, false)
        |> assign(:user_has_items, user_has_items)
      else
        socket
        |> assign(:items, nil)
        |> assign(:all_items, [])
        |> assign(:loading, true)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    filtered_items = filter_items(socket.assigns.all_items, query, socket.assigns)

    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:current_page, 1)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    filtered_items = filter_items(socket.assigns.all_items, "", socket.assigns)

    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:current_page, 1)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("filter_pricing", %{"type" => pricing_type}, socket) do
    assigns = %{socket.assigns | pricing_filter: pricing_type}
    filtered_items = filter_items(socket.assigns.all_items, socket.assigns.search_query, assigns)

    {:noreply,
     socket
     |> assign(:pricing_filter, pricing_type)
     |> assign(:current_page, 1)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("filter_delivery", %{"type" => delivery_type}, socket) do
    assigns = %{socket.assigns | delivery_filter: delivery_type}
    filtered_items = filter_items(socket.assigns.all_items, socket.assigns.search_query, assigns)

    {:noreply,
     socket
     |> assign(:delivery_filter, delivery_type)
     |> assign(:current_page, 1)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("change_per_page", %{"per_page" => per_page}, socket) do
    per_page_num = String.to_integer(per_page)
    filtered_items = get_filtered_items(socket)

    {:noreply,
     socket
     |> assign(:per_page, per_page_num)
     |> assign(:current_page, 1)
     |> assign(:items, paginate_items(filtered_items, 1, per_page_num))}
  end

  @impl true
  def handle_event("goto_page", %{"page" => page}, socket) do
    page_num = String.to_integer(page)
    filtered_items = get_filtered_items(socket)

    {:noreply,
     socket
     |> assign(:current_page, page_num)
     |> assign(:items, paginate_items(filtered_items, page_num, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("next_page", _params, socket) do
    total_pages = ceil(socket.assigns.total_results / socket.assigns.per_page)
    current_page = socket.assigns.current_page

    if current_page < total_pages do
      next_page = current_page + 1
      filtered_items = get_filtered_items(socket)

      {:noreply,
       socket
       |> assign(:current_page, next_page)
       |> assign(:items, paginate_items(filtered_items, next_page, socket.assigns.per_page))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_page", _params, socket) do
    current_page = socket.assigns.current_page

    if current_page > 1 do
      prev_page = current_page - 1
      filtered_items = get_filtered_items(socket)

      {:noreply,
       socket
       |> assign(:current_page, prev_page)
       |> assign(:items, paginate_items(filtered_items, prev_page, socket.assigns.per_page))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("clear_filter", %{"filter" => filter}, socket) do
    socket =
      case filter do
        "search" -> assign(socket, :search_query, "")
        "pricing" -> assign(socket, :pricing_filter, "all")
        "delivery" -> assign(socket, :delivery_filter, "all")
        _ -> socket
      end

    filtered_items = get_filtered_items(socket)

    {:noreply,
     socket
     |> assign(:current_page, 1)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    all_items = socket.assigns.all_items

    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:pricing_filter, "all")
     |> assign(:delivery_filter, "all")
     |> assign(:current_page, 1)
     |> assign(:total_results, length(all_items))
     |> assign(:items, paginate_items(all_items, 1, socket.assigns.per_page))}
  end

  @impl true
  def handle_info({:store_item_approved, approved_item}, socket) do
    # Fetch the full item with preloaded associations
    full_item = Store.get_item_with_media!(approved_item.id)

    # Add the new item to all_items
    all_items = [full_item | socket.assigns.all_items]

    # Recalculate filtered items and pagination
    filtered_items = filter_items(all_items, socket.assigns.search_query, socket.assigns)
    current_page = socket.assigns.current_page
    per_page = socket.assigns.per_page

    {:noreply,
     socket
     |> assign(:all_items, all_items)
     |> assign(:total_results, length(filtered_items))
     |> assign(:items, paginate_items(filtered_items, current_page, per_page))}
  end

  defp get_filtered_items(socket) do
    filter_items(socket.assigns.all_items, socket.assigns.search_query, socket.assigns)
  end

  defp paginate_items(items, page, per_page) do
    items
    |> Enum.slice((page - 1) * per_page, per_page)
  end

  defp filter_items(items, query, assigns) do
    items
    |> filter_by_search(query)
    |> filter_by_pricing(assigns.pricing_filter)
    |> filter_by_delivery(assigns.delivery_filter)
  end

  defp filter_by_search(items, ""), do: items

  defp filter_by_search(items, query) do
    query = String.downcase(query)

    Enum.filter(items, fn item ->
      String.contains?(String.downcase(item.name), query) ||
        (item.description && String.contains?(String.downcase(item.description), query))
    end)
  end

  defp filter_by_pricing(items, "all"), do: items

  defp filter_by_pricing(items, pricing_type) do
    Enum.filter(items, fn item -> item.pricing_type == pricing_type end)
  end

  defp filter_by_delivery(items, "all"), do: items

  defp filter_by_delivery(items, delivery_method) do
    Enum.filter(items, fn item ->
      methods = item.delivery_methods || []
      delivery_method in methods
    end)
  end

  defp page_numbers(current_page, total_pages) do
    cond do
      total_pages <= 7 ->
        Enum.to_list(1..max(total_pages, 1)//1)

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

  defp get_thumbnail_url(item) do
    case Enum.find(item.media, fn m -> m.media_type == "photo" end) do
      nil -> nil
      media -> R2Storage.generate_store_media_url(media.r2_key)
    end
  end

  defp format_price(nil, _currency), do: nil

  defp format_price(price, currency) do
    symbol = StoreItem.currency_symbol(currency)
    "#{symbol}#{Decimal.round(price, 2)}"
  end

  defp pricing_filter_options do
    [
      {"fixed_price", gettext("Fixed Price"), "hero-banknotes",
       "bg-blue-500/10 text-blue-500 border-blue-500/20"},
      {"accepts_donation", gettext("Donation"), "hero-gift",
       "bg-purple-500/10 text-purple-500 border-purple-500/20"}
    ]
  end

  defp delivery_filter_options do
    [
      {"express_delivery", gettext("Express"), "hero-truck",
       "bg-orange-500/10 text-orange-500 border-orange-500/20"},
      {"shipping", gettext("Shipping"), "hero-paper-airplane",
       "bg-green-500/10 text-green-500 border-green-500/20"},
      {"local_pickup", gettext("Pickup"), "hero-map-pin",
       "bg-yellow-500/10 text-yellow-500 border-yellow-500/20"},
      {"in_person", gettext("In Person"), "hero-user-group",
       "bg-indigo-500/10 text-indigo-500 border-indigo-500/20"}
    ]
  end

  defp filters_active?(assigns) do
    assigns.search_query != "" or assigns.pricing_filter != "all" or
      assigns.delivery_filter != "all"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300 noise-overlay">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8 font-sans">
        <%!-- Header --%>
        <div class="mb-8 sm:mb-12 relative animate-fade-in px-2 sm:px-0">
          <div class="text-center lg:px-48">
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-3 tracking-tight">
              {gettext("SahajStore")}
            </h1>
            <p class="text-base sm:text-lg text-base-content/60 max-w-xl mx-auto font-medium leading-relaxed">
              {gettext(
                "Discover unique items from our community. From meditation essentials to handcrafted goods."
              )}
            </p>
          </div>

          <%!-- Header Actions (Matching Topics/Events Layout) --%>
          <div class="lg:absolute right-0 top-0 flex items-center gap-3 mt-6 lg:mt-0 justify-center">
            <%= if @current_scope && @current_scope.user && @user_has_items do %>
              <.link
                navigate={~p"/store/my-items"}
                class="inline-flex items-center gap-2 px-4 py-2.5 bg-base-200 hover:bg-base-300 text-base-content rounded-lg text-sm font-semibold border border-base-content/10 transition-all shadow-sm group"
              >
                <.icon
                  name="hero-shopping-bag"
                  class="w-5 h-5 text-base-content/60 group-hover:text-primary"
                />
                <span class="hidden md:inline">{gettext("My Items")}</span>
              </.link>
            <% end %>
            <.primary_button navigate="/store/new" icon="hero-plus">
              {gettext("List Item")}
            </.primary_button>
          </div>
        </div>
        <div class="bg-gradient-to-br from-base-200/80 to-base-300/80 backdrop-blur-sm rounded-xl p-4 sm:p-6 border border-base-content/10 shadow-xl">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4 items-end">
            <%!-- Search --%>
            <div class="sm:col-span-2 lg:col-span-2">
              <label class="flex items-center gap-2 text-xs sm:text-sm font-semibold text-base-content/80 mb-2">
                <.icon name="hero-magnifying-glass" class="w-4 h-4 text-primary" />
                {gettext("Search")}
              </label>
              <div class="relative">
                <form phx-change="search" phx-submit="search" class="w-full">
                  <input
                    type="text"
                    name="query"
                    value={@search_query}
                    placeholder={gettext("Search items...")}
                    phx-debounce="300"
                    class="w-full px-4 py-3 pl-11 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content placeholder-base-content/40 focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all font-medium"
                  />
                  <.icon
                    name="hero-magnifying-glass"
                    class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-base-content/40"
                  />
                </form>
              </div>
            </div>

            <%!-- Pricing Filter --%>
            <div>
              <label class="flex items-center gap-2 text-xs sm:text-sm font-semibold text-base-content/80 mb-2">
                <.icon name="hero-banknotes" class="w-4 h-4 text-accent" />
                {gettext("Pricing")}
              </label>
              <form phx-change="filter_pricing">
                <select
                  name="type"
                  class="w-full px-4 py-3 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all cursor-pointer font-medium"
                >
                  <option value="all">{gettext("Any Pricing")}</option>
                  <%= for {value, label, _icon, _class} <- pricing_filter_options() do %>
                    <option value={value} selected={@pricing_filter == value}>{label}</option>
                  <% end %>
                </select>
              </form>
            </div>

            <%!-- Delivery Filter --%>
            <div>
              <label class="flex items-center gap-2 text-xs sm:text-sm font-semibold text-base-content/80 mb-2">
                <.icon name="hero-truck" class="w-4 h-4 text-success" />
                {gettext("Delivery")}
              </label>
              <form phx-change="filter_delivery">
                <select
                  name="type"
                  class="w-full px-4 py-3 bg-base-100/50 border border-base-content/20 rounded-lg text-sm sm:text-base text-base-content focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary focus:bg-base-100 transition-all cursor-pointer font-medium"
                >
                  <option value="all">{gettext("Any Method")}</option>
                  <%= for {value, label, _icon, _class} <- delivery_filter_options() do %>
                    <option value={value} selected={@delivery_filter == value}>{label}</option>
                  <% end %>
                </select>
              </form>
            </div>
          </div>

          <%!-- Active filters and clear button --%>
          <%= if filters_active?(assigns) do %>
            <div class="mt-4 pt-4 border-t border-base-content/10 flex items-center justify-between gap-4 flex-wrap animate-fade-in">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="text-xs sm:text-sm text-base-content/40 font-semibold uppercase tracking-wider">
                  {gettext("Active filters")}
                </span>
                <%= if @search_query != "" do %>
                  <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-primary/10 text-primary text-xs sm:text-sm rounded-lg border border-primary/20 hover:bg-primary/20 transition-colors font-medium">
                    <span>{gettext("Search")}: {@search_query}</span>
                    <button
                      phx-click="clear_filter"
                      phx-value-filter="search"
                      class="hover:bg-primary/30 rounded-md p-0.5 transition-colors"
                    >
                      <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                    </button>
                  </span>
                <% end %>
                <%= if @pricing_filter != "all" do %>
                  <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-primary/10 text-primary text-xs sm:text-sm rounded-lg border border-primary/20 hover:bg-primary/20 transition-colors font-medium">
                    <span>
                      {Enum.find_value(pricing_filter_options(), fn {v, l, _, _} ->
                        v == @pricing_filter && l
                      end)}
                    </span>
                    <button
                      phx-click="clear_filter"
                      phx-value-filter="pricing"
                      class="hover:bg-primary/30 rounded-md p-0.5 transition-colors"
                    >
                      <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                    </button>
                  </span>
                <% end %>
                <%= if @delivery_filter != "all" do %>
                  <span class="inline-flex items-center gap-1.5 px-3 py-1 bg-primary/10 text-primary text-xs sm:text-sm rounded-lg border border-primary/20 hover:bg-primary/20 transition-colors font-medium">
                    <span>
                      {Enum.find_value(delivery_filter_options(), fn {v, l, _, _} ->
                        v == @delivery_filter && l
                      end)}
                    </span>
                    <button
                      phx-click="clear_filter"
                      phx-value-filter="delivery"
                      class="hover:bg-primary/30 rounded-md p-0.5 transition-colors"
                    >
                      <.icon name="hero-x-mark" class="w-3.5 h-3.5" />
                    </button>
                  </span>
                <% end %>
              </div>

              <div class="flex items-center gap-4">
                <span class="text-xs sm:text-sm text-base-content/40 font-medium whitespace-nowrap">
                  {@total_results} {ngettext("result", "results", @total_results)}
                </span>
                <button
                  phx-click="clear_filters"
                  class="inline-flex items-center gap-1.5 px-3 py-2 bg-base-content/5 hover:bg-error/10 text-base-content/60 hover:text-error transition-all duration-200 rounded-lg border border-base-content/10 hover:border-error/20 text-xs sm:text-sm font-bold group"
                >
                  <.icon
                    name="hero-arrow-path"
                    class="w-4 h-4 transition-transform duration-500 group-hover:rotate-180"
                  />
                  {gettext("Clear all")}
                </button>
              </div>
            </div>
          <% else %>
            <div class="mt-4 flex justify-between items-center text-xs sm:text-sm text-base-content/40 border-t border-base-content/5 pt-4">
              <span>
                {ngettext(
                  "%{count} available item",
                  "%{count} available items",
                  @total_results,
                  count: @total_results
                )}
              </span>
              <div class="flex items-center gap-2">
                <span class="text-xs font-medium uppercase tracking-wider">
                  {gettext("Per page")}:
                </span>
                <div class="flex gap-1">
                  <%= for count <- [12, 24, 48] do %>
                    <button
                      phx-click="change_per_page"
                      phx-value-per_page={count}
                      class={[
                        "px-2 py-0.5 rounded transition-all font-bold text-xs",
                        @per_page == count && "bg-primary text-primary-content",
                        @per_page != count && "hover:bg-base-content/10 text-base-content/60"
                      ]}
                    >
                      {count}
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Items Grid --%>
        <div class="mt-10">
          <%= if @loading do %>
            <.store_skeleton_grid count={8} />
          <% else %>
            <%= if @items == [] do %>
              <div class="bg-base-100/50 backdrop-blur-sm rounded-2xl p-12 text-center border border-dashed border-base-content/20 animate-fade-in">
                <div class="w-20 h-20 bg-base-200/50 rounded-full flex items-center justify-center mx-auto mb-6 ring-8 ring-base-100/50">
                  <.icon name="hero-shopping-bag" class="w-10 h-10 text-base-content/20" />
                </div>
                <h3 class="text-xl font-bold text-base-content mb-2">{gettext("No items found")}</h3>
                <p class="text-base-content/60 max-w-md mx-auto mb-8 font-medium">
                  <%= if filters_active?(assigns) do %>
                    {gettext("We couldn't find any items matching your filters. Try adjusting them!")}
                  <% else %>
                    {gettext(
                      "The marketplace is currently empty. Be the first to share something with the community!"
                    )}
                  <% end %>
                </p>
                <%= if filters_active?(assigns) do %>
                  <button
                    phx-click="clear_filters"
                    class="btn btn-primary rounded-xl px-8 shadow-lg shadow-primary/20"
                  >
                    {gettext("Clear all filters")}
                  </button>
                <% else %>
                  <.link
                    navigate="/store/new"
                    class="btn btn-primary rounded-xl px-8 shadow-lg shadow-primary/20"
                  >
                    {gettext("List First Item")}
                  </.link>
                <% end %>
              </div>
            <% else %>
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 sm:gap-8">
                <div
                  :for={{item, index} <- Enum.with_index(@items)}
                  class="group relative bg-gradient-to-br from-base-200 to-base-300 rounded-2xl overflow-hidden border border-base-content/10 hover:border-primary/50 transition-all duration-300 hover:shadow-2xl hover:shadow-primary/10 hover:-translate-y-1.5 flex flex-col h-full animate-fade-in"
                  style={"animation-delay: #{rem(index, 4) * 100}ms; animation-fill-mode: backwards;"}
                >
                  <.link navigate={~p"/store/#{item.id}"} class="flex flex-col h-full">
                    <%!-- Image --%>
                    <div class="aspect-[4/3] overflow-hidden relative bg-base-300">
                      <%= if thumbnail_url = get_thumbnail_url(item) do %>
                        <img
                          src={thumbnail_url}
                          alt={item.name}
                          class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 ease-in-out"
                          loading="lazy"
                        />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center bg-gradient-to-br from-base-200 to-base-300">
                          <.icon name="hero-photo" class="w-16 h-16 text-base-content/5" />
                        </div>
                      <% end %>

                      <%!-- Pricing Overlay --%>
                      <div class="absolute top-3 right-3">
                        <div class={[
                          "px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg backdrop-blur-md border border-white/10",
                          item.pricing_type == "fixed_price" && "bg-base-900/90 text-white",
                          item.pricing_type != "fixed_price" && "bg-primary/90 text-white"
                        ]}>
                          <%= if item.pricing_type == "fixed_price" do %>
                            {format_price(item.price, item.currency)}
                          <% else %>
                            <span class="flex items-center gap-1">
                              <.icon name="hero-gift" class="w-3.5 h-3.5" />
                              {gettext("Donation")}
                            </span>
                          <% end %>
                        </div>
                      </div>
                    </div>

                    <%!-- Content --%>
                    <div class="p-5 flex-1 flex flex-col">
                      <h3 class="text-lg font-bold text-base-content mb-1.5 group-hover:text-primary transition-colors line-clamp-1">
                        {item.name}
                      </h3>

                      <%= if item.description do %>
                        <p class="text-sm text-base-content/60 line-clamp-2 mb-4 font-medium leading-normal">
                          {truncate_text(item.description, 100)}
                        </p>
                      <% else %>
                        <div class="flex-1"></div>
                      <% end %>

                      <div class="mt-auto flex items-center justify-between pt-4 border-t border-base-content/5">
                        <div class="flex items-center gap-2">
                          <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-base-content/5 text-base-content/60 rounded-md text-[10px] font-bold uppercase tracking-wider">
                            {gettext("%{count} left", count: item.quantity)}
                          </span>
                        </div>
                        <div class="flex -space-x-1.5">
                          <%= for method <- Enum.take(item.delivery_methods || [], 3) do %>
                            <div
                              class="w-7 h-7 rounded-full bg-base-100 ring-2 ring-base-200 flex items-center justify-center shadow-sm"
                              title={Phoenix.Naming.humanize(method)}
                            >
                              <.icon
                                name={delivery_icon(method)}
                                class="w-3.5 h-3.5 text-base-content/70"
                              />
                            </div>
                          <% end %>
                        </div>
                      </div>
                    </div>
                  </.link>
                </div>
              </div>

              <%!-- Pagination --%>
              <%= if @total_results > @per_page do %>
                <div class="mt-12 pt-8 border-t border-base-content/10 flex flex-col sm:flex-row items-center justify-between gap-4">
                  <p class="text-base-content/50 text-xs sm:text-sm font-medium">
                    {gettext("Showing")}
                    <span class="text-base-content font-bold">
                      {(@current_page - 1) * @per_page + 1}
                    </span>
                    {gettext("to")}
                    <span class="text-base-content font-bold">
                      {min(@current_page * @per_page, @total_results)}
                    </span>
                    {gettext("of")}
                    <span class="text-base-content font-bold">{@total_results}</span>
                    {ngettext("item", "items", @total_results)}
                  </p>

                  <div class="flex items-center gap-1.5">
                    <button
                      phx-click="prev_page"
                      disabled={@current_page == 1}
                      class={[
                        "p-2 rounded-xl transition-all",
                        @current_page == 1 && "opacity-30 cursor-not-allowed bg-base-100",
                        @current_page > 1 &&
                          "bg-base-100 hover:bg-base-200 text-base-content active:scale-90"
                      ]}
                    >
                      <.icon name="hero-chevron-left" class="w-5 h-5" />
                    </button>

                    <div class="flex items-center gap-1">
                      <%= for page_num <- page_numbers(@current_page, ceil(@total_results / @per_page)) do %>
                        <%= if page_num == "..." do %>
                          <span class="px-2 text-base-content/30 font-bold">...</span>
                        <% else %>
                          <button
                            phx-click="goto_page"
                            phx-value-page={page_num}
                            class={[
                              "w-10 h-10 rounded-xl transition-all font-bold text-sm",
                              @current_page == page_num &&
                                "bg-primary text-primary-content shadow-lg shadow-primary/20",
                              @current_page != page_num &&
                                "hover:bg-base-100 text-base-content/70 hover:text-base-content"
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
                        "p-2 rounded-xl transition-all",
                        @current_page >= ceil(@total_results / @per_page) &&
                          "opacity-30 cursor-not-allowed bg-base-100",
                        @current_page < ceil(@total_results / @per_page) &&
                          "bg-base-100 hover:bg-base-200 text-base-content active:scale-90"
                      ]}
                    >
                      <.icon name="hero-chevron-right" class="w-5 h-5" />
                    </button>
                  </div>
                </div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp delivery_icon("express_delivery"), do: "hero-truck"
  defp delivery_icon("shipping"), do: "hero-paper-airplane"
  defp delivery_icon("local_pickup"), do: "hero-map-pin"
  defp delivery_icon("in_person"), do: "hero-user-group"
  defp delivery_icon(_), do: "hero-cube"

  # Skeleton components for loading state
  defp store_skeleton_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 lg:gap-8">
      <.store_card_skeleton :for={_ <- 1..@count} />
    </div>
    """
  end

  defp store_card_skeleton(assigns) do
    ~H"""
    <div
      class="bg-base-100 rounded-2xl border border-base-content/5 overflow-hidden shadow-sm"
      aria-hidden="true"
    >
      <div class="skeleton aspect-[4/3] w-full rounded-none opacity-50"></div>
      <div class="p-5">
        <div class="skeleton h-5 w-3/4 mb-4 rounded opacity-40"></div>
        <div class="skeleton h-3 w-full mb-2 rounded opacity-30"></div>
        <div class="skeleton h-3 w-2/3 mb-6 rounded opacity-30"></div>
        <div class="flex items-center justify-between pt-4 border-t border-base-content/5">
          <div class="skeleton h-3 w-16 rounded opacity-30"></div>
          <div class="flex gap-1">
            <div class="skeleton h-6 w-6 rounded-full opacity-30"></div>
            <div class="skeleton h-6 w-6 rounded-full opacity-30"></div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
