defmodule SahajyogWeb.StoreItemShowLive do
  @moduledoc """
  LiveView for displaying store item details with photo gallery, video player,
  seller info, and inquiry form.
  """
  use SahajyogWeb, :live_view

  alias Sahajyog.Store
  alias Sahajyog.Store.StoreItemInquiry
  alias Sahajyog.Resources.R2Storage

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    item = Store.get_item_with_media!(id)

    # Only show approved items to the public
    if item.status != "approved" do
      {:ok,
       socket
       |> put_flash(:error, gettext("This item is not available."))
       |> push_navigate(to: ~p"/store")}
    else
      photos = Enum.filter(item.media, &(&1.media_type == "photo"))
      video = Enum.find(item.media, &(&1.media_type == "video"))

      # Generate presigned URLs for media
      photo_urls =
        photos
        |> Enum.map(fn p -> {p.id, R2Storage.generate_store_media_url(p.r2_key)} end)
        |> Map.new()

      video_url = if video, do: R2Storage.generate_store_media_url(video.r2_key), else: nil

      {:ok,
       socket
       |> assign(:page_title, item.name)
       |> assign(:item, item)
       |> assign(:photos, photos)
       |> assign(:video, video)
       |> assign(:photo_urls, photo_urls)
       |> assign(:video_url, video_url)
       |> assign(:selected_photo_index, 0)
       |> assign(:lightbox_open, false)
       |> assign(:inquiry_form, to_form(Store.change_inquiry(%StoreItemInquiry{}, %{})))
       |> assign(:inquiry_submitted, false)}
    end
  end

  @impl true
  def handle_event("select_photo", %{"index" => index}, socket) do
    {:noreply, assign(socket, :selected_photo_index, String.to_integer(index))}
  end

  @impl true
  def handle_event("prev_photo", _, socket) do
    current = socket.assigns.selected_photo_index
    total = length(socket.assigns.photos)
    new_index = if current > 0, do: current - 1, else: total - 1
    {:noreply, assign(socket, :selected_photo_index, new_index)}
  end

  @impl true
  def handle_event("next_photo", _, socket) do
    current = socket.assigns.selected_photo_index
    total = length(socket.assigns.photos)
    new_index = if current < total - 1, do: current + 1, else: 0
    {:noreply, assign(socket, :selected_photo_index, new_index)}
  end

  @impl true
  def handle_event("open_lightbox", _, socket) do
    {:noreply, assign(socket, :lightbox_open, true)}
  end

  @impl true
  def handle_event("close_lightbox", _, socket) do
    {:noreply, assign(socket, :lightbox_open, false)}
  end

  @impl true
  def handle_event("validate_inquiry", %{"store_item_inquiry" => params}, socket) do
    changeset =
      %StoreItemInquiry{}
      |> Store.change_inquiry(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :inquiry_form, to_form(changeset))}
  end

  @impl true
  def handle_event("submit_inquiry", %{"store_item_inquiry" => params}, socket) do
    item = socket.assigns.item
    buyer = socket.assigns.current_scope.user

    case Store.create_inquiry(item, buyer, params) do
      {:ok, inquiry} ->
        # Send notification email to seller
        Sahajyog.Store.StoreNotifier.deliver_inquiry_to_seller(
          inquiry,
          item,
          item.user,
          buyer
        )

        {:noreply,
         socket
         |> assign(:inquiry_submitted, true)
         |> put_flash(:info, gettext("Your inquiry has been sent to the seller!"))}

      {:error, changeset} ->
        {:noreply, assign(socket, :inquiry_form, to_form(changeset))}
    end
  end

  defp format_price(nil, _currency), do: nil

  defp format_price(price, currency) do
    symbol = Sahajyog.Store.StoreItem.currency_symbol(currency)
    "#{symbol}#{Decimal.round(price, 2)}"
  end

  defp delivery_label("express_delivery"), do: gettext("Express Delivery")
  defp delivery_label("shipping"), do: gettext("Shipping")
  defp delivery_label("local_pickup"), do: gettext("Local Pickup")
  defp delivery_label("in_person"), do: gettext("In Person")
  defp delivery_label(_), do: gettext("Other")

  defp delivery_icon("express_delivery"), do: "hero-truck"
  defp delivery_icon("shipping"), do: "hero-paper-airplane"
  defp delivery_icon("local_pickup"), do: "hero-map-pin"
  defp delivery_icon("in_person"), do: "hero-user-group"
  defp delivery_icon(_), do: "hero-cube"

  @doc """
  Returns the public display data for a store item, respecting phone visibility settings.
  This function is used to ensure phone numbers are only shown when phone_visible is true.
  """
  def get_public_seller_info(item) do
    base_info = %{
      first_name: item.user.first_name,
      last_name: item.user.last_name,
      email: item.user.email
    }

    if item.phone_visible do
      Map.put(base_info, :phone, item.user.phone_number)
    else
      base_info
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Link --%>
        <.link
          navigate={~p"/store"}
          class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary mb-6 transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Store")}
        </.link>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <%!-- Left Column: Media Gallery --%>
          <div class="space-y-4">
            <%!-- Main Photo/Video Display --%>
            <div class="relative aspect-square bg-gradient-to-br from-base-200 to-base-300 rounded-2xl overflow-hidden border border-base-content/10">
              <%= if length(@photos) > 0 do %>
                <% selected_photo = Enum.at(@photos, @selected_photo_index) %>
                <img
                  src={@photo_urls[selected_photo.id]}
                  alt={@item.name}
                  class="w-full h-full object-contain cursor-pointer"
                  phx-click="open_lightbox"
                />
                <%!-- Navigation Arrows --%>
                <%= if length(@photos) > 1 do %>
                  <button
                    phx-click="prev_photo"
                    class="absolute left-2 top-1/2 -translate-y-1/2 p-2 bg-base-100/80 hover:bg-base-100 rounded-full transition-colors"
                    aria-label={gettext("Previous photo")}
                  >
                    <.icon name="hero-chevron-left" class="w-6 h-6" />
                  </button>
                  <button
                    phx-click="next_photo"
                    class="absolute right-2 top-1/2 -translate-y-1/2 p-2 bg-base-100/80 hover:bg-base-100 rounded-full transition-colors"
                    aria-label={gettext("Next photo")}
                  >
                    <.icon name="hero-chevron-right" class="w-6 h-6" />
                  </button>
                <% end %>
              <% else %>
                <div class="w-full h-full flex items-center justify-center">
                  <.icon name="hero-shopping-bag" class="w-24 h-24 text-base-content/20" />
                </div>
              <% end %>
            </div>

            <%!-- Thumbnail Navigation --%>
            <%= if length(@photos) > 1 do %>
              <div class="flex gap-2 overflow-x-auto pb-2">
                <%= for {photo, index} <- Enum.with_index(@photos) do %>
                  <button
                    phx-click="select_photo"
                    phx-value-index={index}
                    class={[
                      "flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden border-2 transition-all",
                      if(@selected_photo_index == index,
                        do: "border-primary ring-2 ring-primary/30",
                        else: "border-base-content/20 hover:border-primary/50"
                      )
                    ]}
                  >
                    <img
                      src={@photo_urls[photo.id]}
                      alt={"#{@item.name} thumbnail #{index + 1}"}
                      class="w-full h-full object-cover"
                    />
                  </button>
                <% end %>
              </div>
            <% end %>

            <%!-- Video Player --%>
            <%= if @video do %>
              <div class="mt-4">
                <h3 class="text-sm font-semibold text-base-content/70 mb-2 flex items-center gap-2">
                  <.icon name="hero-video-camera" class="w-4 h-4" />
                  {gettext("Video")}
                </h3>
                <div class="aspect-video bg-black rounded-xl overflow-hidden">
                  <video controls preload="metadata" class="w-full h-full">
                    <source src={@video_url} type={@video.content_type} />
                    {gettext("Your browser does not support the video tag.")}
                  </video>
                </div>
              </div>
            <% end %>
          </div>

          <%!-- Right Column: Item Details --%>
          <div class="space-y-6">
            <%!-- Title and Price --%>
            <div>
              <h1 class="text-3xl font-bold text-base-content mb-2">{@item.name}</h1>
              <div class="flex items-center gap-3">
                <%= if @item.pricing_type == "fixed_price" do %>
                  <span class="text-2xl font-bold text-primary">
                    {format_price(@item.price, @item.currency)}
                  </span>
                <% else %>
                  <span class="px-3 py-1 bg-secondary/10 text-secondary rounded-lg font-semibold">
                    {gettext("Accepts Donation")}
                  </span>
                <% end %>
                <span class="text-base-content/60">
                  {ngettext("%{count} available", "%{count} available", @item.quantity,
                    count: @item.quantity
                  )}
                </span>
              </div>
            </div>

            <%!-- Description --%>
            <%= if @item.description do %>
              <div>
                <h3 class="text-sm font-semibold text-base-content/70 mb-2">
                  {gettext("Description")}
                </h3>
                <p class="text-base-content whitespace-pre-wrap">{@item.description}</p>
              </div>
            <% end %>

            <%!-- Delivery Methods --%>
            <div>
              <h3 class="text-sm font-semibold text-base-content/70 mb-2">
                {gettext("Delivery Options")}
              </h3>
              <div class="flex flex-wrap gap-2">
                <%= for method <- @item.delivery_methods do %>
                  <span class="inline-flex items-center gap-2 px-3 py-2 bg-base-200 rounded-lg text-sm">
                    <.icon name={delivery_icon(method)} class="w-4 h-4 text-primary" />
                    {delivery_label(method)}
                  </span>
                <% end %>
              </div>
              <%= if @item.shipping_cost do %>
                <p class="text-sm text-base-content/60 mt-2">
                  {gettext("Shipping cost:")} {format_price(@item.shipping_cost, @item.currency)}
                </p>
              <% end %>
              <%= if @item.shipping_regions do %>
                <p class="text-sm text-base-content/60 mt-1">
                  {gettext("Ships to:")} {@item.shipping_regions}
                </p>
              <% end %>
              <%= if @item.meeting_location do %>
                <p class="text-sm text-base-content/60 mt-1">
                  {gettext("Meeting location:")} {@item.meeting_location}
                </p>
              <% end %>
            </div>

            <%!-- Seller Info --%>
            <div class="p-4 bg-base-200/50 rounded-xl border border-base-content/10">
              <h3 class="text-sm font-semibold text-base-content/70 mb-3">
                {gettext("Seller Information")}
              </h3>
              <% seller_info = get_public_seller_info(@item) %>
              <div class="space-y-2">
                <div class="flex items-center gap-2">
                  <.icon name="hero-user" class="w-4 h-4 text-base-content/50" />
                  <span class="text-base-content">
                    {seller_info.first_name} {seller_info.last_name}
                  </span>
                </div>
                <div class="flex items-center gap-2">
                  <.icon name="hero-envelope" class="w-4 h-4 text-base-content/50" />
                  <a href={"mailto:#{seller_info.email}"} class="text-primary hover:underline">
                    {seller_info.email}
                  </a>
                </div>
                <%= if Map.has_key?(seller_info, :phone) and seller_info.phone do %>
                  <div class="flex items-center gap-2">
                    <.icon name="hero-phone" class="w-4 h-4 text-base-content/50" />
                    <a href={"tel:#{seller_info.phone}"} class="text-primary hover:underline">
                      {seller_info.phone}
                    </a>
                  </div>
                <% end %>
              </div>
            </div>

            <%!-- Inquiry Form --%>
            <div class="p-4 bg-base-200/50 rounded-xl border border-base-content/10">
              <h3 class="text-lg font-semibold text-base-content mb-4 flex items-center gap-2">
                <.icon name="hero-chat-bubble-left-right" class="w-5 h-5 text-primary" />
                {gettext("Contact Seller")}
              </h3>

              <%= if @inquiry_submitted do %>
                <div class="text-center py-4">
                  <.icon name="hero-check-circle" class="w-12 h-12 text-success mx-auto mb-2" />
                  <p class="text-base-content font-semibold">
                    {gettext("Inquiry sent successfully!")}
                  </p>
                  <p class="text-sm text-base-content/60 mt-1">
                    {gettext("The seller will contact you soon.")}
                  </p>
                </div>
              <% else %>
                <.form
                  for={@inquiry_form}
                  id="inquiry-form"
                  phx-change="validate_inquiry"
                  phx-submit="submit_inquiry"
                  class="space-y-4"
                >
                  <div>
                    <label class="block text-sm font-medium text-base-content/70 mb-1">
                      {gettext("Quantity")}
                    </label>
                    <.input
                      field={@inquiry_form[:requested_quantity]}
                      type="number"
                      min="1"
                      max={@item.quantity}
                      value="1"
                      class="w-full"
                    />
                  </div>

                  <div>
                    <label class="block text-sm font-medium text-base-content/70 mb-1">
                      {gettext("Message")}
                    </label>
                    <.input
                      field={@inquiry_form[:message]}
                      type="textarea"
                      rows="4"
                      placeholder={gettext("Hi, I'm interested in this item...")}
                      class="w-full"
                    />
                  </div>

                  <.primary_button type="submit" class="w-full" icon="hero-paper-airplane">
                    {gettext("Send Inquiry")}
                  </.primary_button>
                </.form>
              <% end %>
            </div>

            <%!-- Posted Date --%>
            <p class="text-sm text-base-content/50">
              {gettext("Posted")} {Calendar.strftime(@item.inserted_at, "%B %d, %Y")}
            </p>
          </div>
        </div>
      </div>

      <%!-- Lightbox Modal --%>
      <.modal :if={@lightbox_open} id="photo-lightbox" on_close="close_lightbox" size="xl">
        <:title>
          <span class="text-base-content/70">
            {gettext("Photo %{current} of %{total}",
              current: @selected_photo_index + 1,
              total: length(@photos)
            )}
          </span>
        </:title>
        <%= if length(@photos) > 0 do %>
          <% selected_photo = Enum.at(@photos, @selected_photo_index) %>
          <div class="relative flex items-center justify-center">
            <img
              src={@photo_urls[selected_photo.id]}
              alt={@item.name}
              class="max-w-full max-h-[70vh] object-contain rounded-lg"
            />
            <%= if length(@photos) > 1 do %>
              <button
                phx-click="prev_photo"
                class="absolute left-2 top-1/2 -translate-y-1/2 p-3 bg-base-100/80 hover:bg-base-100 rounded-full transition-colors"
                aria-label={gettext("Previous photo")}
              >
                <.icon name="hero-chevron-left" class="w-8 h-8" />
              </button>
              <button
                phx-click="next_photo"
                class="absolute right-2 top-1/2 -translate-y-1/2 p-3 bg-base-100/80 hover:bg-base-100 rounded-full transition-colors"
                aria-label={gettext("Next photo")}
              >
                <.icon name="hero-chevron-right" class="w-8 h-8" />
              </button>
            <% end %>
          </div>
        <% end %>
      </.modal>
    </.page_container>
    """
  end
end
