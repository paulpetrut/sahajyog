defmodule SahajyogWeb.MyStoreItemsLive do
  @moduledoc """
  LiveView for seller dashboard to manage their store items.
  Displays all items with status badges, edit/delete/mark sold actions,
  and shows inquiries received.
  """
  use SahajyogWeb, :live_view

  alias Sahajyog.Store
  alias Sahajyog.Resources.R2Storage

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    socket =
      socket
      |> assign(:page_title, gettext("My Store Items"))
      |> assign(:user, user)
      |> assign(:status_filter, "all")
      |> assign(:show_inquiries_for, nil)
      |> assign(:delete_confirm_item, nil)

    socket =
      if connected?(socket) do
        items = Store.list_user_items(user.id)
        inquiries = Store.list_inquiries_for_seller(user.id)

        socket
        |> assign(:items, items)
        |> assign(:inquiries, inquiries)
        |> assign(:loading, false)
      else
        socket
        |> assign(:items, nil)
        |> assign(:inquiries, [])
        |> assign(:loading, true)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, :status_filter, status)}
  end

  @impl true
  def handle_event("show_inquiries", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    {:noreply, assign(socket, :show_inquiries_for, item_id)}
  end

  @impl true
  def handle_event("close_inquiries", _params, socket) do
    {:noreply, assign(socket, :show_inquiries_for, nil)}
  end

  @impl true
  def handle_event("confirm_delete", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    {:noreply, assign(socket, :delete_confirm_item, item_id)}
  end

  @impl true
  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, :delete_confirm_item, nil)}
  end

  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    user = socket.assigns.user

    item = Enum.find(socket.assigns.items, &(&1.id == item_id))

    if item && item.user_id == user.id do
      case Store.delete_item(item) do
        {:ok, _} ->
          items = Enum.reject(socket.assigns.items, &(&1.id == item_id))
          inquiries = Enum.reject(socket.assigns.inquiries, &(&1.store_item_id == item_id))

          {:noreply,
           socket
           |> assign(:items, items)
           |> assign(:inquiries, inquiries)
           |> assign(:delete_confirm_item, nil)
           |> put_flash(:info, gettext("Item deleted successfully."))}

        {:error, _} ->
          {:noreply,
           socket
           |> assign(:delete_confirm_item, nil)
           |> put_flash(:error, gettext("Failed to delete item."))}
      end
    else
      {:noreply,
       socket
       |> assign(:delete_confirm_item, nil)
       |> put_flash(:error, gettext("Item not found."))}
    end
  end

  @impl true
  def handle_event("mark_sold", %{"id" => id}, socket) do
    item_id = String.to_integer(id)
    user = socket.assigns.user

    item = Enum.find(socket.assigns.items, &(&1.id == item_id))

    if item && item.user_id == user.id do
      case Store.mark_item_sold(item) do
        {:ok, updated_item} ->
          items =
            Enum.map(socket.assigns.items, fn i ->
              if i.id == item_id, do: %{i | status: updated_item.status}, else: i
            end)

          {:noreply,
           socket
           |> assign(:items, items)
           |> put_flash(:info, gettext("Item marked as sold."))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to mark item as sold."))}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("Item not found."))}
    end
  end

  defp filtered_items(items, "all"), do: items
  defp filtered_items(items, status), do: Enum.filter(items, &(&1.status == status))

  defp get_thumbnail_url(item) do
    case Enum.find(item.media, fn m -> m.media_type == "photo" end) do
      nil -> nil
      media -> R2Storage.generate_store_media_url(media.r2_key)
    end
  end

  defp format_price(nil, _currency), do: nil

  defp format_price(price, currency) do
    symbol = Sahajyog.Store.StoreItem.currency_symbol(currency)
    "#{symbol}#{Decimal.round(price, 2)}"
  end

  defp status_badge_class("pending"), do: "bg-warning/10 text-warning border-warning/20"
  defp status_badge_class("approved"), do: "bg-success/10 text-success border-success/20"
  defp status_badge_class("rejected"), do: "bg-error/10 text-error border-error/20"
  defp status_badge_class("sold"), do: "bg-info/10 text-info border-info/20"
  defp status_badge_class(_), do: "bg-base-content/10 text-base-content/60 border-base-content/20"

  defp status_icon("pending"), do: "hero-clock"
  defp status_icon("approved"), do: "hero-check-circle"
  defp status_icon("rejected"), do: "hero-x-circle"
  defp status_icon("sold"), do: "hero-shopping-bag"
  defp status_icon(_), do: "hero-question-mark-circle"

  defp status_label("pending"), do: gettext("Pending Review")
  defp status_label("approved"), do: gettext("Approved")
  defp status_label("rejected"), do: gettext("Rejected")
  defp status_label("sold"), do: gettext("Sold")
  defp status_label(_), do: gettext("Unknown")

  defp status_filter_options do
    [
      {"all", gettext("All"), "hero-view-columns"},
      {"pending", gettext("Pending"), "hero-clock"},
      {"approved", gettext("Approved"), "hero-check-circle"},
      {"rejected", gettext("Rejected"), "hero-x-circle"},
      {"sold", gettext("Sold"), "hero-shopping-bag"}
    ]
  end

  defp count_inquiries_for_item(inquiries, item_id) do
    Enum.count(inquiries, &(&1.store_item_id == item_id))
  end

  defp get_inquiries_for_item(inquiries, item_id) do
    Enum.filter(inquiries, &(&1.store_item_id == item_id))
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %H:%M")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 class="text-3xl sm:text-4xl font-bold text-base-content mb-2">
              {gettext("My Store Items")}
            </h1>
            <p class="text-base-content/70">
              {gettext("Manage your listings and view inquiries")}
            </p>
          </div>
          <.primary_button navigate="/store/new" icon="hero-plus">
            {gettext("List New Item")}
          </.primary_button>
        </div>

        <%!-- Status Filter --%>
        <.filter_tabs
          options={status_filter_options()}
          selected={@status_filter}
          on_select="filter_status"
          param_name="status"
        />

        <%!-- Loading State --%>
        <%= if @loading do %>
          <.my_items_skeleton_grid count={4} />
        <% else %>
          <% filtered = filtered_items(@items, @status_filter) %>

          <%!-- Items Grid --%>
          <%= if filtered != [] do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
              <%= for item <- filtered do %>
                <.card hover class="overflow-hidden flex flex-col">
                  <div class="flex gap-4">
                    <%!-- Thumbnail --%>
                    <div class="w-24 h-24 sm:w-32 sm:h-32 flex-shrink-0 bg-gradient-to-br from-base-200 to-base-300 rounded-lg overflow-hidden">
                      <%= if thumbnail_url = get_thumbnail_url(item) do %>
                        <img
                          src={thumbnail_url}
                          alt={item.name}
                          class="w-full h-full object-cover"
                        />
                      <% else %>
                        <div class="w-full h-full flex items-center justify-center">
                          <.icon name="hero-shopping-bag" class="w-10 h-10 text-base-content/20" />
                        </div>
                      <% end %>
                    </div>

                    <%!-- Item Info --%>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-start justify-between gap-2 mb-2">
                        <h3 class="text-lg font-bold text-base-content line-clamp-1">
                          {item.name}
                        </h3>
                        <span class={[
                          "px-2 py-1 rounded-lg text-xs font-semibold border flex-shrink-0 flex items-center gap-1",
                          status_badge_class(item.status)
                        ]}>
                          <.icon name={status_icon(item.status)} class="w-3 h-3" />
                          {status_label(item.status)}
                        </span>
                      </div>

                      <div class="space-y-1 text-sm text-base-content/70">
                        <%= if item.pricing_type == "fixed_price" do %>
                          <p class="font-semibold text-primary">
                            {format_price(item.price, item.currency)}
                          </p>
                        <% else %>
                          <p class="text-secondary">{gettext("Accepts Donation")}</p>
                        <% end %>
                        <p>
                          {ngettext("%{count} available", "%{count} available", item.quantity,
                            count: item.quantity
                          )}
                        </p>
                        <p class="text-xs text-base-content/50">
                          {gettext("Posted")} {Calendar.strftime(item.inserted_at, "%b %d, %Y")}
                        </p>
                      </div>
                    </div>
                  </div>

                  <%!-- Review Notes (for rejected items) --%>
                  <%= if item.status == "rejected" and item.review_notes do %>
                    <div class="mt-3 p-3 bg-error/10 rounded-lg border border-error/20">
                      <p class="text-sm text-error font-medium flex items-center gap-2">
                        <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                        {gettext("Rejection reason:")}
                      </p>
                      <p class="text-sm text-base-content/80 mt-1">{item.review_notes}</p>
                    </div>
                  <% end %>

                  <%!-- Actions --%>
                  <div class="mt-4 pt-4 border-t border-base-content/10 flex flex-wrap items-center gap-2">
                    <%!-- Inquiries Button --%>
                    <% inquiry_count = count_inquiries_for_item(@inquiries, item.id) %>
                    <button
                      type="button"
                      phx-click="show_inquiries"
                      phx-value-id={item.id}
                      class={[
                        "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors",
                        inquiry_count > 0 &&
                          "bg-primary/10 text-primary hover:bg-primary/20 border border-primary/20",
                        inquiry_count == 0 &&
                          "bg-base-200 text-base-content/60 hover:bg-base-300 border border-base-content/10"
                      ]}
                    >
                      <.icon name="hero-chat-bubble-left-right" class="w-4 h-4" />
                      {ngettext("%{count} inquiry", "%{count} inquiries", inquiry_count,
                        count: inquiry_count
                      )}
                    </button>

                    <div class="flex-1"></div>

                    <%!-- Edit Button --%>
                    <.link
                      navigate={~p"/store/#{item.id}/edit"}
                      class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-base-200 hover:bg-base-300 rounded-lg text-sm font-medium transition-colors"
                    >
                      <.icon name="hero-pencil" class="w-4 h-4" />
                      {gettext("Edit")}
                    </.link>

                    <%!-- Mark Sold Button (only for approved items) --%>
                    <%= if item.status == "approved" do %>
                      <button
                        type="button"
                        phx-click="mark_sold"
                        phx-value-id={item.id}
                        class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-success/10 hover:bg-success/20 text-success rounded-lg text-sm font-medium transition-colors border border-success/20"
                      >
                        <.icon name="hero-check" class="w-4 h-4" />
                        {gettext("Mark Sold")}
                      </button>
                    <% end %>

                    <%!-- Delete Button --%>
                    <button
                      type="button"
                      phx-click="confirm_delete"
                      phx-value-id={item.id}
                      class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-error/10 hover:bg-error/20 text-error rounded-lg text-sm font-medium transition-colors border border-error/20"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                      {gettext("Delete")}
                    </button>
                  </div>
                </.card>
              <% end %>
            </div>
          <% else %>
            <%!-- Empty State --%>
            <.empty_state
              icon="hero-shopping-bag"
              title={
                if @status_filter == "all",
                  do: gettext("No items yet"),
                  else: gettext("No %{status} items", status: @status_filter)
              }
              description={
                if @status_filter == "all",
                  do: gettext("Start by listing your first item"),
                  else: gettext("Try selecting a different filter")
              }
            >
              <:actions>
                <%= if @status_filter == "all" do %>
                  <.primary_button navigate="/store/new" icon="hero-plus">
                    {gettext("List New Item")}
                  </.primary_button>
                <% end %>
              </:actions>
            </.empty_state>
          <% end %>
        <% end %>
      </div>

      <%!-- Inquiries Modal --%>
      <.modal
        :if={@show_inquiries_for}
        id="inquiries-modal"
        on_close="close_inquiries"
        size="lg"
      >
        <:title>
          <span class="flex items-center gap-2">
            <.icon name="hero-chat-bubble-left-right" class="w-5 h-5 text-primary" />
            {gettext("Inquiries")}
          </span>
        </:title>

        <% item = Enum.find(@items || [], &(&1.id == @show_inquiries_for)) %>
        <% item_inquiries = get_inquiries_for_item(@inquiries, @show_inquiries_for) %>

        <%= if item do %>
          <div class="mb-4 p-3 bg-base-200/50 rounded-lg">
            <p class="text-sm text-base-content/70">{gettext("Item:")}</p>
            <p class="font-semibold text-base-content">{item.name}</p>
          </div>
        <% end %>

        <%= if item_inquiries == [] do %>
          <div class="text-center py-8">
            <.icon name="hero-inbox" class="w-12 h-12 mx-auto text-base-content/30 mb-3" />
            <p class="text-base-content/60">{gettext("No inquiries yet for this item.")}</p>
          </div>
        <% else %>
          <div class="space-y-4 max-h-96 overflow-y-auto">
            <%= for inquiry <- item_inquiries do %>
              <div class="p-4 bg-base-200/50 rounded-lg border border-base-content/10">
                <div class="flex items-start justify-between gap-3 mb-3">
                  <div>
                    <p class="font-semibold text-base-content">
                      {inquiry.buyer.first_name} {inquiry.buyer.last_name}
                    </p>
                    <a
                      href={"mailto:#{inquiry.buyer.email}"}
                      class="text-sm text-primary hover:underline"
                    >
                      {inquiry.buyer.email}
                    </a>
                  </div>
                  <span class="text-xs text-base-content/50 flex-shrink-0">
                    {format_datetime(inquiry.inserted_at)}
                  </span>
                </div>

                <div class="flex items-center gap-2 mb-2">
                  <span class="px-2 py-1 bg-primary/10 text-primary rounded text-xs font-medium">
                    {ngettext(
                      "Wants %{count} item",
                      "Wants %{count} items",
                      inquiry.requested_quantity,
                      count: inquiry.requested_quantity
                    )}
                  </span>
                </div>

                <p class="text-sm text-base-content whitespace-pre-wrap">{inquiry.message}</p>

                <div class="mt-3 flex gap-2">
                  <a
                    href={"mailto:#{inquiry.buyer.email}?subject=Re: #{item && item.name}"}
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-primary text-primary-content rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
                  >
                    <.icon name="hero-envelope" class="w-4 h-4" />
                    {gettext("Reply")}
                  </a>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </.modal>

      <%!-- Delete Confirmation Modal --%>
      <.modal
        :if={@delete_confirm_item}
        id="delete-confirm-modal"
        on_close="cancel_delete"
        size="sm"
      >
        <:title>
          <span class="flex items-center gap-2 text-error">
            <.icon name="hero-exclamation-triangle" class="w-5 h-5" />
            {gettext("Delete Item")}
          </span>
        </:title>

        <% item_to_delete = Enum.find(@items || [], &(&1.id == @delete_confirm_item)) %>

        <p class="text-base-content mb-4">
          {gettext("Are you sure you want to delete this item? This action cannot be undone.")}
        </p>

        <%= if item_to_delete do %>
          <div class="p-3 bg-base-200/50 rounded-lg mb-4">
            <p class="font-semibold text-base-content">{item_to_delete.name}</p>
          </div>
        <% end %>

        <:footer>
          <button
            type="button"
            phx-click="cancel_delete"
            class="px-4 py-2 bg-base-200 hover:bg-base-300 rounded-lg font-medium transition-colors"
          >
            {gettext("Cancel")}
          </button>
          <button
            type="button"
            phx-click="delete_item"
            phx-value-id={@delete_confirm_item}
            class="px-4 py-2 bg-error text-error-content hover:bg-error/90 rounded-lg font-medium transition-colors"
          >
            {gettext("Delete")}
          </button>
        </:footer>
      </.modal>
    </.page_container>
    """
  end

  defp my_items_skeleton_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
      <.my_item_card_skeleton :for={_ <- 1..@count} />
    </div>
    """
  end

  defp my_item_card_skeleton(assigns) do
    ~H"""
    <div
      class="bg-gradient-to-br from-base-200 to-base-300 rounded-xl border border-base-content/10 p-4"
      aria-hidden="true"
    >
      <div class="flex gap-4">
        <div class="skeleton w-24 h-24 sm:w-32 sm:h-32 rounded-lg"></div>
        <div class="flex-1">
          <div class="skeleton h-6 w-3/4 mb-2 rounded"></div>
          <div class="skeleton h-4 w-1/2 mb-2 rounded"></div>
          <div class="skeleton h-4 w-1/3 mb-2 rounded"></div>
          <div class="skeleton h-3 w-1/4 rounded"></div>
        </div>
      </div>
      <div class="mt-4 pt-4 border-t border-base-content/10 flex gap-2">
        <div class="skeleton h-8 w-24 rounded-lg"></div>
        <div class="flex-1"></div>
        <div class="skeleton h-8 w-16 rounded-lg"></div>
        <div class="skeleton h-8 w-16 rounded-lg"></div>
      </div>
    </div>
    """
  end
end
