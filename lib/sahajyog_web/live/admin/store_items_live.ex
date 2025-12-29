defmodule SahajyogWeb.Admin.StoreItemsLive do
  @moduledoc """
  Admin LiveView for reviewing and managing SahajStore item submissions.
  """
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Store
  alias Sahajyog.Store.StoreNotifier
  alias Sahajyog.Resources.R2Storage

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Store Items"))
     |> assign(:filter, "pending")
     |> assign(:items, Store.list_pending_items())
     |> assign(:reviewing_item, nil)
     |> assign(:reject_notes, "")
     |> assign(:show_reject_modal, false)}
  end

  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    items =
      case filter do
        "pending" -> Store.list_pending_items()
        "all" -> list_all_items()
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:items, items)}
  end

  @impl true
  def handle_event("review", %{"id" => id}, socket) do
    item = Store.get_item_with_media!(String.to_integer(id))

    {:noreply, assign(socket, :reviewing_item, item)}
  end

  @impl true
  def handle_event("cancel_review", _, socket) do
    {:noreply,
     socket
     |> assign(:reviewing_item, nil)
     |> assign(:show_reject_modal, false)
     |> assign(:reject_notes, "")}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    item = Store.get_item_with_media!(String.to_integer(id))
    admin = socket.assigns.current_scope.user

    case Store.approve_item(item, admin) do
      {:ok, approved_item} ->
        # Send notification email
        seller = item.user
        StoreNotifier.deliver_item_approved(approved_item, seller)

        {:noreply,
         socket
         |> assign(:items, refresh_items(socket.assigns.filter))
         |> assign(:reviewing_item, nil)
         |> put_flash(:info, gettext("Item approved successfully"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to approve item"))}
    end
  end

  @impl true
  def handle_event("show_reject_modal", %{"id" => id}, socket) do
    item = Store.get_item_with_media!(String.to_integer(id))

    {:noreply,
     socket
     |> assign(:reviewing_item, item)
     |> assign(:show_reject_modal, true)
     |> assign(:reject_notes, "")}
  end

  @impl true
  def handle_event("update_reject_notes", %{"notes" => notes}, socket) do
    {:noreply, assign(socket, :reject_notes, notes)}
  end

  @impl true
  def handle_event("reject", _, socket) do
    item = socket.assigns.reviewing_item
    admin = socket.assigns.current_scope.user
    notes = socket.assigns.reject_notes

    if String.trim(notes) == "" do
      {:noreply, put_flash(socket, :error, gettext("Review notes are required for rejection"))}
    else
      case Store.reject_item(item, admin, notes) do
        {:ok, rejected_item} ->
          # Send notification email
          seller = item.user
          StoreNotifier.deliver_item_rejected(rejected_item, seller, notes)

          {:noreply,
           socket
           |> assign(:items, refresh_items(socket.assigns.filter))
           |> assign(:reviewing_item, nil)
           |> assign(:show_reject_modal, false)
           |> assign(:reject_notes, "")
           |> put_flash(:info, gettext("Item rejected"))}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, gettext("Failed to reject item"))}
      end
    end
  end

  @impl true
  def handle_event("cancel_reject", _, socket) do
    {:noreply,
     socket
     |> assign(:show_reject_modal, false)
     |> assign(:reject_notes, "")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = Store.get_item!(String.to_integer(id))
    {:ok, _} = Store.delete_item(item)

    {:noreply,
     socket
     |> assign(:items, refresh_items(socket.assigns.filter))
     |> put_flash(:info, gettext("Item deleted successfully"))}
  end

  # Private helpers

  defp list_all_items do
    import Ecto.Query
    alias Sahajyog.Repo
    alias Sahajyog.Store.StoreItem

    StoreItem
    |> order_by([i], desc: i.inserted_at)
    |> preload([:media, :user])
    |> Repo.all()
  end

  defp refresh_items("pending"), do: Store.list_pending_items()
  defp refresh_items("all"), do: list_all_items()
  defp refresh_items(_), do: Store.list_pending_items()

  defp status_class("pending"), do: "bg-warning/10 text-warning border border-warning/20"
  defp status_class("approved"), do: "bg-success/10 text-success border border-success/20"
  defp status_class("rejected"), do: "bg-error/10 text-error border border-error/20"
  defp status_class("sold"), do: "bg-info/10 text-info border border-info/20"

  defp status_class(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  defp border_class("pending"), do: "border-warning/30"
  defp border_class("approved"), do: "border-success/30"
  defp border_class("rejected"), do: "border-error/30"
  defp border_class("sold"), do: "border-info/30"
  defp border_class(_), do: "border-base-content/20"

  defp format_pricing(%{pricing_type: "fixed_price", price: price}) when not is_nil(price) do
    "$#{price}"
  end

  defp format_pricing(%{pricing_type: "accepts_donation"}) do
    gettext("Accepts Donation")
  end

  defp format_pricing(_), do: "-"

  defp format_delivery_methods(methods) when is_list(methods) do
    methods
    |> Enum.map(&format_delivery_method/1)
    |> Enum.join(", ")
  end

  defp format_delivery_methods(_), do: "-"

  defp format_delivery_method("express_delivery"), do: gettext("Express Delivery")
  defp format_delivery_method("in_person"), do: gettext("In Person")
  defp format_delivery_method("local_pickup"), do: gettext("Local Pickup")
  defp format_delivery_method("shipping"), do: gettext("Shipping")
  defp format_delivery_method(method), do: method

  defp get_first_photo(media) when is_list(media) do
    Enum.find(media, fn m -> m.media_type == "photo" end)
  end

  defp get_first_photo(_), do: nil

  defp get_thumbnail_url(item) do
    case get_first_photo(item.media) do
      nil -> nil
      photo -> R2Storage.generate_store_media_url(photo.r2_key)
    end
  end

  defp get_media_url(media) do
    R2Storage.generate_store_media_url(media.r2_key)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.page_container>
        <.admin_nav current_page={:store_items} />

        <div class="max-w-7xl mx-auto px-4 py-8">
          <.page_header title={gettext("Store Items Review")} />

          <%!-- Filter Tabs --%>
          <div class="flex gap-2 mb-6 border-b border-base-content/10">
            <button
              phx-click="set_filter"
              phx-value-filter="pending"
              class={[
                "px-4 py-2 text-sm font-medium border-b-2 transition-colors",
                @filter == "pending" && "border-primary text-primary",
                @filter != "pending" &&
                  "border-transparent text-base-content/60 hover:text-base-content"
              ]}
            >
              {gettext("Pending Review")}
              <span class={[
                "ml-2 px-1.5 py-0.5 rounded-full text-xs",
                @filter == "pending" && "bg-primary/10 text-primary",
                @filter != "pending" && "bg-base-content/10 text-base-content/60"
              ]}>
                {Enum.count(@items, &(&1.status == "pending"))}
              </span>
            </button>
            <button
              phx-click="set_filter"
              phx-value-filter="all"
              class={[
                "px-4 py-2 text-sm font-medium border-b-2 transition-colors",
                @filter == "all" && "border-primary text-primary",
                @filter != "all" &&
                  "border-transparent text-base-content/60 hover:text-base-content"
              ]}
            >
              {gettext("All Items")}
            </button>
          </div>

          <%!-- Review Modal --%>
          <.modal
            :if={@reviewing_item && !@show_reject_modal}
            id="review-modal"
            on_close="cancel_review"
            size="lg"
          >
            <:title>{gettext("Review Store Item")}</:title>

            <div class="space-y-6">
              <%!-- Item Details --%>
              <div class="p-4 bg-base-100/50 rounded-lg border border-base-content/10">
                <div class="flex gap-4">
                  <%!-- Thumbnail --%>
                  <%= if thumbnail_url = get_thumbnail_url(@reviewing_item) do %>
                    <div class="w-24 h-24 rounded-lg overflow-hidden bg-base-200 flex-shrink-0">
                      <img
                        src={thumbnail_url}
                        alt={@reviewing_item.name}
                        class="w-full h-full object-cover"
                      />
                    </div>
                  <% else %>
                    <div class="w-24 h-24 rounded-lg bg-base-200 flex items-center justify-center flex-shrink-0">
                      <.icon name="hero-photo" class="w-8 h-8 text-base-content/30" />
                    </div>
                  <% end %>

                  <div class="flex-1">
                    <h3 class="font-semibold text-lg text-base-content mb-1">
                      {@reviewing_item.name}
                    </h3>
                    <p class="text-base-content/60 text-sm mb-2 line-clamp-2">
                      {@reviewing_item.description}
                    </p>
                    <div class="flex flex-wrap gap-3 text-xs text-base-content/50">
                      <span class="flex items-center gap-1">
                        <.icon name="hero-user" class="w-3 h-3" />
                        {@reviewing_item.user.email}
                      </span>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-calendar" class="w-3 h-3" />
                        {Calendar.strftime(@reviewing_item.inserted_at, "%b %d, %Y")}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Item Info Grid --%>
              <div class="grid grid-cols-2 gap-4">
                <div class="p-3 bg-base-100/30 rounded-lg">
                  <p class="text-xs text-base-content/50 mb-1">{gettext("Quantity")}</p>
                  <p class="font-semibold text-base-content">{@reviewing_item.quantity}</p>
                </div>
                <div class="p-3 bg-base-100/30 rounded-lg">
                  <p class="text-xs text-base-content/50 mb-1">{gettext("Price")}</p>
                  <p class="font-semibold text-base-content">{format_pricing(@reviewing_item)}</p>
                </div>
                <div class="p-3 bg-base-100/30 rounded-lg">
                  <p class="text-xs text-base-content/50 mb-1">{gettext("Production Cost")}</p>
                  <p class="font-semibold text-base-content">
                    <%= if @reviewing_item.production_cost do %>
                      ${@reviewing_item.production_cost}
                    <% else %>
                      -
                    <% end %>
                  </p>
                </div>
                <div class="p-3 bg-base-100/30 rounded-lg">
                  <p class="text-xs text-base-content/50 mb-1">{gettext("Delivery Methods")}</p>
                  <p class="font-semibold text-base-content text-sm">
                    {format_delivery_methods(@reviewing_item.delivery_methods)}
                  </p>
                </div>
              </div>

              <%!-- Media Preview --%>
              <%= if @reviewing_item.media && length(@reviewing_item.media) > 0 do %>
                <div>
                  <p class="text-sm font-medium text-base-content/70 mb-2">
                    {gettext("Media")} ({length(@reviewing_item.media)})
                  </p>
                  <div class="flex gap-2 flex-wrap">
                    <%= for media <- @reviewing_item.media do %>
                      <div class="w-16 h-16 rounded-lg overflow-hidden bg-base-200">
                        <%= if media.media_type == "photo" do %>
                          <img
                            src={get_media_url(media)}
                            alt={media.file_name}
                            class="w-full h-full object-cover"
                          />
                        <% else %>
                          <div class="w-full h-full flex items-center justify-center bg-base-300">
                            <.icon name="hero-video-camera" class="w-6 h-6 text-base-content/50" />
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>

              <%!-- Seller Contact Info --%>
              <div class="p-4 bg-base-100/30 rounded-lg border border-base-content/10">
                <p class="text-sm font-medium text-base-content/70 mb-2">
                  {gettext("Seller Information")}
                </p>
                <div class="space-y-1 text-sm">
                  <p>
                    <span class="text-base-content/50">{gettext("Name")}:</span> {@reviewing_item.user.first_name} {@reviewing_item.user.last_name}
                  </p>
                  <p>
                    <span class="text-base-content/50">{gettext("Email")}:</span> {@reviewing_item.user.email}
                  </p>
                  <%= if @reviewing_item.phone_visible && @reviewing_item.user.phone_number do %>
                    <p>
                      <span class="text-base-content/50">{gettext("Phone")}:</span> {@reviewing_item.user.phone_number}
                      <span class="text-success text-xs">({gettext("visible to buyers")})</span>
                    </p>
                  <% else %>
                    <p class="text-base-content/50 text-xs">{gettext("Phone hidden from buyers")}</p>
                  <% end %>
                </div>
              </div>

              <%!-- Previous Rejection Notes (if any) --%>
              <%= if @reviewing_item.status == "rejected" && @reviewing_item.review_notes do %>
                <div class="p-4 bg-error/10 rounded-lg border border-error/20">
                  <p class="text-sm font-medium text-error mb-2 flex items-center gap-2">
                    <.icon name="hero-exclamation-triangle" class="w-4 h-4" />
                    {gettext("Previous Rejection Notes")}
                  </p>
                  <p class="text-sm text-base-content/80">{@reviewing_item.review_notes}</p>
                </div>
              <% end %>

              <%!-- Action Buttons --%>
              <div class="flex gap-3 pt-4 border-t border-base-content/10">
                <button
                  type="button"
                  phx-click="approve"
                  phx-value-id={@reviewing_item.id}
                  disabled={@reviewing_item.status == "approved"}
                  class={[
                    "px-6 py-3 rounded-lg transition-colors font-semibold focus:outline-none focus:ring-2 focus:ring-success focus:ring-offset-2 focus:ring-offset-base-300",
                    @reviewing_item.status == "approved" &&
                      "bg-success/50 text-success-content/50 cursor-not-allowed",
                    @reviewing_item.status != "approved" &&
                      "bg-success text-success-content hover:bg-success/90"
                  ]}
                >
                  <.icon name="hero-check" class="w-4 h-4 inline mr-1" />
                  <%= if @reviewing_item.status == "approved" do %>
                    {gettext("Already Approved")}
                  <% else %>
                    {gettext("Approve")}
                  <% end %>
                </button>
                <button
                  type="button"
                  phx-click="show_reject_modal"
                  phx-value-id={@reviewing_item.id}
                  disabled={@reviewing_item.status == "rejected"}
                  class={[
                    "px-6 py-3 rounded-lg transition-colors font-semibold focus:outline-none focus:ring-2 focus:ring-error focus:ring-offset-2 focus:ring-offset-base-300",
                    @reviewing_item.status == "rejected" &&
                      "bg-error/50 text-error-content/50 cursor-not-allowed",
                    @reviewing_item.status != "rejected" &&
                      "bg-error text-error-content hover:bg-error/90"
                  ]}
                >
                  <.icon name="hero-x-mark" class="w-4 h-4 inline mr-1" />
                  <%= if @reviewing_item.status == "rejected" do %>
                    {gettext("Already Rejected")}
                  <% else %>
                    {gettext("Reject")}
                  <% end %>
                </button>
                <.secondary_button type="button" phx-click="cancel_review">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.modal>

          <%!-- Reject Modal with Notes --%>
          <.modal :if={@show_reject_modal} id="reject-modal" on_close="cancel_reject" size="md">
            <:title>{gettext("Reject Store Item")}</:title>

            <div class="space-y-4">
              <p class="text-base-content/70">
                {gettext(
                  "Please provide feedback for the seller explaining why this item was rejected."
                )}
              </p>

              <div>
                <label class="block text-sm font-medium text-base-content/70 mb-2">
                  {gettext("Review Notes")} <span class="text-error">*</span>
                </label>
                <form phx-change="update_reject_notes">
                  <textarea
                    id="reject-notes"
                    name="notes"
                    rows="4"
                    class="w-full px-3 py-2 bg-base-100 border border-base-content/20 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent text-base-content"
                    placeholder={gettext("Explain why this item is being rejected...")}
                    phx-debounce="300"
                  ><%= @reject_notes %></textarea>
                </form>
              </div>

              <div class="flex gap-3 pt-4">
                <button
                  type="button"
                  phx-click="reject"
                  class="px-6 py-3 bg-error text-error-content rounded-lg hover:bg-error/90 transition-colors font-semibold focus:outline-none focus:ring-2 focus:ring-error focus:ring-offset-2 focus:ring-offset-base-300"
                >
                  {gettext("Confirm Rejection")}
                </button>
                <.secondary_button type="button" phx-click="cancel_reject">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.modal>

          <%!-- Items List --%>
          <%= if @items == [] do %>
            <.card>
              <.empty_state
                icon="hero-shopping-bag"
                title={gettext("No items")}
                description={gettext("No store items to review")}
              />
            </.card>
          <% else %>
            <div class="space-y-4">
              <.card :for={item <- @items} class={["border", border_class(item.status)]}>
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                  <div class="flex gap-4 flex-1">
                    <%!-- Thumbnail --%>
                    <%= if thumbnail_url = get_thumbnail_url(item) do %>
                      <div class="w-20 h-20 rounded-lg overflow-hidden bg-base-200 flex-shrink-0">
                        <img
                          src={thumbnail_url}
                          alt={item.name}
                          class="w-full h-full object-cover"
                        />
                      </div>
                    <% else %>
                      <div class="w-20 h-20 rounded-lg bg-base-200 flex items-center justify-center flex-shrink-0">
                        <.icon name="hero-photo" class="w-6 h-6 text-base-content/30" />
                      </div>
                    <% end %>

                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-3 mb-2 flex-wrap">
                        <h3 class="text-lg font-bold text-base-content truncate">{item.name}</h3>
                        <span class={[
                          "px-3 py-1 rounded-full text-xs font-semibold",
                          status_class(item.status)
                        ]}>
                          {item.status}
                        </span>
                      </div>

                      <%= if item.description do %>
                        <p class="text-base-content/60 mb-2 line-clamp-2 text-sm">
                          {item.description}
                        </p>
                      <% end %>

                      <div class="flex flex-wrap items-center gap-4 text-sm text-base-content/50">
                        <span class="flex items-center gap-1">
                          <.icon name="hero-user" class="w-4 h-4" />
                          {item.user.email}
                        </span>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-cube" class="w-4 h-4" />
                          {gettext("Qty")}: {item.quantity}
                        </span>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-currency-dollar" class="w-4 h-4" />
                          {format_pricing(item)}
                        </span>
                        <span class="flex items-center gap-1">
                          <.icon name="hero-calendar" class="w-4 h-4" />
                          {Calendar.strftime(item.inserted_at, "%b %d, %Y")}
                        </span>
                      </div>

                      <%= if item.review_notes do %>
                        <div class="mt-3 p-3 bg-base-100/50 rounded-lg border border-base-content/10">
                          <p class="text-sm text-base-content/60">
                            <span class="font-semibold text-base-content/80">
                              {gettext("Review notes")}:
                            </span>
                            {item.review_notes}
                          </p>
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <div class="flex flex-row sm:flex-col gap-2 w-full sm:w-auto">
                    <%= if item.status == "pending" do %>
                      <.primary_button
                        phx-click="review"
                        phx-value-id={item.id}
                        class="flex-1 sm:flex-none px-4 py-2 text-sm"
                      >
                        {gettext("Review")}
                      </.primary_button>
                    <% else %>
                      <.secondary_button
                        phx-click="review"
                        phx-value-id={item.id}
                        class="flex-1 sm:flex-none px-4 py-2 text-sm"
                      >
                        {gettext("View Item")}
                      </.secondary_button>
                    <% end %>
                    <.danger_button
                      phx-click="delete"
                      phx-value-id={item.id}
                      data-confirm={gettext("Are you sure you want to delete this item?")}
                      class="flex-1 sm:flex-none px-4 py-2 text-sm"
                    >
                      {gettext("Delete")}
                    </.danger_button>
                  </div>
                </div>
              </.card>
            </div>
          <% end %>
        </div>
      </.page_container>
    </Layouts.app>
    """
  end
end
