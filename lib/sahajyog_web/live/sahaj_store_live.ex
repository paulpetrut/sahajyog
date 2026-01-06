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
      {"all", gettext("All"), "hero-squares-2x2"},
      {"fixed_price", gettext("Fixed Price"), "hero-currency-rupee"},
      {"accepts_donation", gettext("Donation"), "hero-gift"}
    ]
  end

  defp delivery_filter_options do
    [
      {"all", gettext("All"), "hero-squares-2x2"},
      {"express_delivery", gettext("Express"), "hero-truck"},
      {"shipping", gettext("Shipping"), "hero-paper-airplane"},
      {"local_pickup", gettext("Pickup"), "hero-map-pin"},
      {"in_person", gettext("In Person"), "hero-user-group"}
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container class="relative overflow-visible">
      <%!-- Background Elements --%>
      <div class="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div class="absolute top-0 left-0 w-full h-[600px] bg-gradient-to-b from-primary/5 via-base-100/50 to-base-100 z-0">
        </div>
        <div class="absolute top-[-10%] right-[-5%] w-[600px] h-[600px] rounded-full bg-secondary/5 blur-[120px]">
        </div>
        <div class="absolute top-[10%] left-[-10%] w-[500px] h-[500px] rounded-full bg-primary/5 blur-[100px]">
        </div>
      </div>

      <div class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        <%!-- Extended Header --%>
        <div class="flex flex-col items-center justify-center text-center mb-8 sm:mb-12">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-base-100/50 border border-base-content/5 text-primary text-xs font-semibold mb-6 animate-fade-in backdrop-blur-sm">
            <.icon name="hero-sparkles" class="w-3.5 h-3.5" />
            <span>{gettext("Community Marketplace")}</span>
          </div>

          <h1
            class="text-4xl sm:text-5xl lg:text-6xl font-display font-bold text-base-content mb-4 tracking-tight animate-fade-in"
            style="animation-delay: 100ms;"
          >
            {gettext("SahajStore")}
          </h1>
          <p
            class="text-lg text-base-content/60 max-w-xl mx-auto animate-fade-in font-light leading-relaxed"
            style="animation-delay: 200ms;"
          >
            {gettext(
              "Discover unique items from our community. From meditation essentials to handcrafted goods."
            )}
          </p>
        </div>

        <%!-- Action & Filter Section (Condensed) --%>
        <div
          class="sticky top-4 z-40 mb-8 animate-fade-in mx-auto max-w-5xl"
          style="animation-delay: 300ms;"
        >
          <div class="bg-base-100/80 backdrop-blur-xl rounded-2xl shadow-xl shadow-base-content/5 ring-1 ring-base-content/5 p-2 flex flex-col sm:flex-row items-center gap-2 sm:gap-4">
            <%!-- Search Input (Integrated) --%>
            <div class="relative flex-1 w-full">
              <form phx-change="search" phx-submit="search" class="relative group w-full">
                <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <.icon name="hero-magnifying-glass" class="w-5 h-5 text-base-content/40" />
                </div>
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder={gettext("Search items...")}
                  class="w-full pl-10 pr-4 py-2.5 bg-transparent border-0 focus:ring-0 text-base-content placeholder-base-content/40 text-sm sm:text-base"
                  phx-debounce="300"
                  autocomplete="off"
                />
                <%= if @search_query != "" do %>
                  <button
                    type="button"
                    phx-click="clear_search"
                    class="absolute inset-y-0 right-0 pr-3 flex items-center text-base-content/40 hover:text-base-content transition-colors"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                <% end %>
              </form>
            </div>

            <%!-- Vertical Divider (Desktop) --%>
            <div class="hidden sm:block w-px h-8 bg-base-content/10"></div>

            <%!-- Filters --%>
            <div class="flex items-center gap-1 w-full sm:w-auto flex-wrap sm:flex-nowrap justify-between sm:justify-start">
              <%!-- Pricing Filter --%>
              <div class="dropdown sm:dropdown-bottom">
                <div
                  tabindex="0"
                  role="button"
                  class={"btn btn-sm h-9 px-3 rounded-xl gap-2 font-normal border-0 " <> if(@pricing_filter != "all", do: "bg-primary/10 text-primary hover:bg-primary/20", else: "btn-ghost hover:bg-base-content/5")}
                >
                  <.icon name="hero-banknotes" class="w-4 h-4 opacity-70" />
                  <span class="whitespace-nowrap">
                    {Enum.find_value(pricing_filter_options(), "Pricing", fn {v, l, _} ->
                      if v == @pricing_filter, do: l
                    end)}
                  </span>
                  <.icon name="hero-chevron-down" class="w-3 h-3 opacity-40 ml-1" />
                </div>
                <ul
                  tabindex="0"
                  class="dropdown-content z-[1] menu p-1 shadow-xl bg-base-100 rounded-xl border border-base-content/10 w-48 mt-2"
                >
                  <%= for {value, label, icon} <- pricing_filter_options() do %>
                    <li>
                      <button
                        class={if @pricing_filter == value, do: "active font-medium", else: ""}
                        phx-click="filter_pricing"
                        phx-value-type={value}
                      >
                        <.icon name={icon} class="w-4 h-4" /> {label}
                      </button>
                    </li>
                  <% end %>
                </ul>
              </div>

              <%!-- Delivery Filter --%>
              <div class="dropdown dropdown-end sm:dropdown-start sm:dropdown-bottom">
                <div
                  tabindex="0"
                  role="button"
                  class={"btn btn-sm h-9 px-3 rounded-xl gap-2 font-normal border-0 " <> if(@delivery_filter != "all", do: "bg-primary/10 text-primary hover:bg-primary/20", else: "btn-ghost hover:bg-base-content/5")}
                >
                  <.icon name="hero-truck" class="w-4 h-4 opacity-70" />
                  <span class="whitespace-nowrap">
                    {Enum.find_value(delivery_filter_options(), "Delivery", fn {v, l, _} ->
                      if v == @delivery_filter, do: l
                    end)}
                  </span>
                  <.icon name="hero-chevron-down" class="w-3 h-3 opacity-40 ml-1" />
                </div>
                <ul
                  tabindex="0"
                  class="dropdown-content z-[1] menu p-1 shadow-xl bg-base-100 rounded-xl border border-base-content/10 w-48 mt-2"
                >
                  <%= for {value, label, icon} <- delivery_filter_options() do %>
                    <li>
                      <button
                        class={if @delivery_filter == value, do: "active font-medium", else: ""}
                        phx-click="filter_delivery"
                        phx-value-type={value}
                      >
                        <.icon name={icon} class="w-4 h-4" /> {label}
                      </button>
                    </li>
                  <% end %>
                </ul>
              </div>
            </div>

            <%!-- Action Buttons --%>
            <div class="flex-shrink-0 ml-auto sm:ml-2 flex gap-2">
              <%!-- Per Page Selector --%>
              <div class="dropdown dropdown-end">
                <div
                  tabindex="0"
                  role="button"
                  class="btn btn-ghost btn-sm h-9 px-3 rounded-xl gap-2 hover:bg-base-content/5 transition-all"
                >
                  <.icon name="hero-view-columns" class="w-4 h-4" />
                  <span class="hidden sm:inline">{@per_page}</span>
                  <.icon name="hero-chevron-down" class="w-3 h-3 opacity-40" />
                </div>
                <ul
                  tabindex="0"
                  class="dropdown-content z-[1] menu p-1 shadow-xl bg-base-100 rounded-xl border border-base-content/10 w-32 mt-2"
                >
                  <%= for count <- [12, 24, 48] do %>
                    <li>
                      <button
                        class={if @per_page == count, do: "active font-medium", else: ""}
                        phx-click="change_per_page"
                        phx-value-per_page={count}
                      >
                        {count} {gettext("items")}
                      </button>
                    </li>
                  <% end %>
                </ul>
              </div>

              <%!-- My Items Button (only show if user is logged in and has items) --%>
              <%= if @current_scope && @current_scope.user && @user_has_items do %>
                <.link navigate="/store/my-items">
                  <button class="btn btn-ghost btn-sm h-9 px-4 rounded-xl gap-2 hover:bg-base-content/5 transition-all">
                    <.icon name="hero-shopping-bag" class="w-4 h-4" />
                    <span class="hidden sm:inline">{gettext("My Items")}</span>
                  </button>
                </.link>
              <% end %>

              <%!-- List Item Button --%>
              <.link navigate="/store/new">
                <button class="btn btn-primary btn-sm h-9 px-5 rounded-xl gap-2 shadow-lg shadow-primary/20 hover:shadow-primary/30 hover:scale-105 active:scale-95 transition-all">
                  <.icon name="hero-plus" class="w-4 h-4" />
                  <span class="hidden sm:inline">{gettext("List Item")}</span>
                  <span class="sm:hidden">{gettext("List")}</span>
                </button>
              </.link>
            </div>
          </div>

          <%= if @total_results > 0 do %>
            <div class="text-center mt-3 animate-fade-in">
              <span class="text-xs font-medium text-base-content/40 px-3 py-1 rounded-full bg-base-100/50 backdrop-blur-sm border border-base-content/5">
                {@total_results} {ngettext("result found", "results found", @total_results)}
              </span>
            </div>
          <% end %>
        </div>

        <%!-- Items Grid --%>
        <%= if @loading do %>
          <.store_skeleton_grid count={8} />
        <% else %>
          <%= if @items != nil and @items == [] do %>
            <div class="flex flex-col items-center justify-center py-20 text-center animate-fade-in border border-dashed border-base-content/10 rounded-3xl bg-base-50/50">
              <div class="w-16 h-16 bg-base-200/50 rounded-full flex items-center justify-center mb-6 ring-8 ring-base-100">
                <.icon name="hero-shopping-bag" class="w-8 h-8 text-base-content/20" />
              </div>
              <h3 class="text-lg font-bold text-base-content mb-2">{gettext("No items found")}</h3>
              <p class="text-base-content/60 max-w-md mb-6 text-sm">
                <%= if @search_query != "" or @pricing_filter != "all" or @delivery_filter != "all" do %>
                  {gettext("We couldn't find any items matching your filters.")}
                <% else %>
                  {gettext("The marketplace is empty. Be the first to list an item!")}
                <% end %>
              </p>
              <div class="flex gap-3">
                <%= if @search_query != "" or @pricing_filter != "all" or @delivery_filter != "all" do %>
                  <button phx-click="clear_search" class="btn btn-sm btn-ghost">
                    {gettext("Clear Filters")}
                  </button>
                <% end %>
                <.link navigate="/store/new" class="btn btn-sm btn-primary">
                  {gettext("List Item")}
                </.link>
              </div>
            </div>
          <% else %>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <div
                :for={{item, index} <- Enum.with_index(@items)}
                class="group relative bg-transparent hover:bg-base-100/50 rounded-2xl transition-all duration-300 animate-fade-in"
                style={"animation-delay: #{rem(index, 4) * 100}ms; animation-fill-mode: backwards;"}
              >
                <.link navigate={~p"/store/#{item.id}"} class="flex flex-col h-full p-2">
                  <%!-- Image Container --%>
                  <div class="aspect-[4/3] overflow-hidden relative bg-base-200 rounded-xl shadow-sm group-hover:shadow-md transition-all">
                    <%= if thumbnail_url = get_thumbnail_url(item) do %>
                      <img
                        src={thumbnail_url}
                        alt={item.name}
                        class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-in-out"
                      />
                    <% else %>
                      <div class="w-full h-full flex items-center justify-center bg-base-200">
                        <.icon name="hero-photo" class="w-12 h-12 text-base-content/10" />
                      </div>
                    <% end %>

                    <%!-- Price Badge --%>
                    <div class="absolute top-2 right-2 z-10">
                      <div class={"backdrop-blur-md px-2.5 py-1 rounded-lg text-[10px] font-bold shadow-sm border border-white/10 #{if item.pricing_type == "fixed_price", do: "bg-base-content/90 text-base-100", else: "bg-primary/90 text-white"}"}>
                        <%= if item.pricing_type == "fixed_price" do %>
                          {format_price(item.price, item.currency)}
                        <% else %>
                          {gettext("Donation")}
                        <% end %>
                      </div>
                    </div>
                  </div>

                  <%!-- Content --%>
                  <div class="px-2 pt-3 flex-1 flex flex-col relative">
                    <div class="flex-1">
                      <h3
                        class="text-base font-bold text-base-content mb-1 group-hover:text-primary transition-colors line-clamp-1"
                        title={item.name}
                      >
                        {item.name}
                      </h3>
                      <%= if item.description do %>
                        <p class="text-xs text-base-content/60 line-clamp-1 mb-2">
                          {truncate_text(item.description, 80)}
                        </p>
                      <% else %>
                        <div class="mb-2 h-4"></div>
                      <% end %>
                    </div>

                    <div class="flex items-center justify-between mt-auto">
                      <div class="flex items-center gap-1.5 text-[10px] font-medium text-base-content/40 uppercase tracking-wider">
                        <span>{item.quantity} {gettext("left")}</span>
                      </div>
                      <div class="flex -space-x-1 opacity-60 group-hover:opacity-100 transition-opacity">
                        <%= for method <- Enum.take(item.delivery_methods, 3) do %>
                          <div
                            class="w-6 h-6 rounded-full bg-base-100 ring-1 ring-base-content/5 flex items-center justify-center"
                            title={Phoenix.Naming.humanize(method)}
                          >
                            <.icon name={delivery_icon(method)} class="w-3 h-3 text-base-content/60" />
                          </div>
                        <% end %>
                      </div>
                    </div>
                  </div>
                </.link>
              </div>
            </div>

            <%!-- Modern Pagination --%>
            <%= if @total_results > @per_page do %>
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
                  {ngettext("item", "items", @total_results)}
                </p>

                <%!-- Pagination controls --%>
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
              </div>
            <% end %>
          <% end %>
        <% end %>
      </div>
    </.page_container>
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
