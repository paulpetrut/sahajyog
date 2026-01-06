defmodule SahajyogWeb.StoreItemCreateLive do
  @moduledoc """
  LiveView for creating and editing store items in the SahajStore marketplace.
  Supports multi-step form with item details, media upload, and delivery options.
  """
  use SahajyogWeb, :live_view

  alias Sahajyog.Accounts.User
  alias Sahajyog.Resources.R2Storage
  alias Sahajyog.Store
  alias Sahajyog.Store.StoreItem

  # File size limits
  @max_photo_size 50_000_000
  @max_video_size 500_000_000

  @impl true
  def mount(params, _session, socket) do
    user = socket.assigns.current_scope.user

    # Check if user profile is complete
    if User.profile_complete?(user) do
      socket = setup_uploads(socket)

      case params do
        %{"id" => id} ->
          mount_edit(socket, id, user)

        _ ->
          mount_new(socket)
      end
    else
      encoded_return = URI.encode_www_form(~p"/store/new")

      {:ok,
       socket
       |> put_flash(
         :error,
         gettext("Please complete your profile before listing an item.")
       )
       |> push_navigate(to: ~p"/users/settings?return_to=#{encoded_return}")}
    end
  end

  defp mount_new(socket) do
    item = %StoreItem{}
    changeset = Store.change_item(item)

    {:ok,
     socket
     |> assign(:page_title, gettext("List New Item"))
     |> assign(:item, item)
     |> assign(:form, to_form(changeset))
     |> assign(:editing, false)
     |> assign(:current_step, 1)
     |> assign(:existing_photos, [])
     |> assign(:existing_video, nil)
     |> assign(:photo_urls, %{})
     |> assign(:video_url, nil)
     |> assign(:photos_to_delete, [])
     |> assign(:video_to_delete, false)}
  end

  defp mount_edit(socket, id, user) do
    item = Store.get_item_with_media!(id)

    # Verify ownership
    if item.user_id != user.id do
      {:ok,
       socket
       |> put_flash(:error, gettext("You can only edit your own items."))
       |> push_navigate(to: ~p"/store")}
    else
      changeset = Store.change_item(item)
      photos = Enum.filter(item.media, &(&1.media_type == "photo"))
      video = Enum.find(item.media, &(&1.media_type == "video"))

      # Generate presigned URLs for existing media
      photo_urls =
        photos
        |> Enum.map(fn p -> {p.id, R2Storage.generate_store_media_url(p.r2_key)} end)
        |> Map.new()

      video_url = if video, do: R2Storage.generate_store_media_url(video.r2_key), else: nil

      {:ok,
       socket
       |> assign(:page_title, gettext("Edit Item"))
       |> assign(:item, item)
       |> assign(:form, to_form(changeset))
       |> assign(:editing, true)
       |> assign(:current_step, 1)
       |> assign(:existing_photos, photos)
       |> assign(:existing_video, video)
       |> assign(:photo_urls, photo_urls)
       |> assign(:video_url, video_url)
       |> assign(:photos_to_delete, [])
       |> assign(:video_to_delete, false)}
    end
  end

  defp setup_uploads(socket) do
    socket
    |> allow_upload(:photos,
      accept: ~w(.jpg .jpeg .png .webp .gif),
      max_entries: 5,
      max_file_size: @max_photo_size,
      auto_upload: true
    )
    |> allow_upload(:video,
      accept: ~w(.mp4 .webm .mov),
      max_entries: 1,
      max_file_size: @max_video_size,
      auto_upload: true
    )
  end

  @impl true
  def handle_event("validate", %{"store_item" => item_params}, socket) do
    changeset =
      socket.assigns.item
      |> Store.change_item(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step

    if current_step < 3 do
      {:noreply, assign(socket, :current_step, current_step + 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_step", _params, socket) do
    current_step = socket.assigns.current_step

    if current_step > 1 do
      {:noreply, assign(socket, :current_step, current_step - 1)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("goto_step", %{"step" => step}, socket) do
    step_num = String.to_integer(step)
    {:noreply, assign(socket, :current_step, step_num)}
  end

  @impl true
  def handle_event("cancel-photo-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  @impl true
  def handle_event("cancel-video-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :video, ref)}
  end

  @impl true
  def handle_event("delete_existing_photo", %{"id" => id}, socket) do
    photo_id = String.to_integer(id)
    photos_to_delete = [photo_id | socket.assigns.photos_to_delete]
    existing_photos = Enum.reject(socket.assigns.existing_photos, &(&1.id == photo_id))

    {:noreply,
     socket
     |> assign(:photos_to_delete, photos_to_delete)
     |> assign(:existing_photos, existing_photos)}
  end

  @impl true
  def handle_event("delete_existing_video", _params, socket) do
    {:noreply,
     socket
     |> assign(:video_to_delete, true)
     |> assign(:existing_video, nil)}
  end

  @impl true
  def handle_event("save", %{"store_item" => item_params}, socket) do
    user = socket.assigns.current_scope.user

    if socket.assigns.editing do
      update_item(socket, item_params, user)
    else
      create_item(socket, item_params, user)
    end
  end

  defp create_item(socket, item_params, user) do
    case Store.create_item(item_params, user) do
      {:ok, item} ->
        # Upload photos and video
        socket = upload_media(socket, item)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item submitted for review!"))
         |> push_navigate(to: ~p"/store/my-items")}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Determine which step has errors
        step = determine_error_step(changeset)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:current_step, step)}
    end
  end

  defp update_item(socket, item_params, user) do
    item = socket.assigns.item

    # Delete marked photos
    Enum.each(socket.assigns.photos_to_delete, fn photo_id ->
      case Enum.find(item.media, &(&1.id == photo_id)) do
        nil -> :ok
        media -> Store.delete_media(media)
      end
    end)

    # Delete video if marked
    if socket.assigns.video_to_delete do
      case Enum.find(item.media, &(&1.media_type == "video")) do
        nil -> :ok
        media -> Store.delete_media(media)
      end
    end

    case Store.update_item(item, item_params, user) do
      {:ok, updated_item} ->
        # Upload new photos and video
        socket = upload_media(socket, updated_item)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item updated and submitted for review!"))
         |> push_navigate(to: ~p"/store/my-items")}

      {:error, %Ecto.Changeset{} = changeset} ->
        # Determine which step has errors
        step = determine_error_step(changeset)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> assign(:current_step, step)}
    end
  end

  # Determine which step contains validation errors
  defp determine_error_step(changeset) do
    errors = changeset.errors |> Keyword.keys()

    # Step 3 fields: delivery_methods, shipping_cost, shipping_time
    if Enum.any?(errors, &(&1 in [:delivery_methods, :shipping_cost, :shipping_time])) do
      3
    else
      # Step 1 fields: everything else
      1
    end
  end

  defp upload_media(socket, item) do
    # Upload photos
    consume_uploaded_entries(socket, :photos, fn %{path: path}, entry ->
      key = R2Storage.generate_store_item_key(item.id, entry.client_name, "photo")
      content_type = entry.client_type || "image/jpeg"

      case R2Storage.upload(path, key, content_type: content_type) do
        {:ok, ^key} ->
          Store.add_media(item, %{
            file_name: entry.client_name,
            content_type: content_type,
            file_size: entry.client_size,
            r2_key: key,
            media_type: "photo"
          })

          {:ok, key}

        {:error, reason} ->
          {:postpone, {:error, reason}}
      end
    end)

    # Upload video
    consume_uploaded_entries(socket, :video, fn %{path: path}, entry ->
      key = R2Storage.generate_store_item_key(item.id, entry.client_name, "video")
      content_type = entry.client_type || "video/mp4"

      case R2Storage.upload(path, key, content_type: content_type) do
        {:ok, ^key} ->
          Store.add_media(item, %{
            file_name: entry.client_name,
            content_type: content_type,
            file_size: entry.client_size,
            r2_key: key,
            media_type: "video"
          })

          {:ok, key}

        {:error, reason} ->
          {:postpone, {:error, reason}}
      end
    end)

    socket
  end

  # Helper functions
  defp photo_error_to_string(:too_large), do: gettext("Photo is too large. Maximum size is 50MB.")

  defp photo_error_to_string(:not_accepted),
    do: gettext("Invalid file type. Please upload JPG, PNG, WebP, or GIF.")

  defp photo_error_to_string(:too_many_files), do: gettext("Maximum 5 photos can be uploaded.")
  defp photo_error_to_string(err), do: inspect(err)

  defp video_error_to_string(:too_large),
    do: gettext("Video is too large. Maximum size is 500MB.")

  defp video_error_to_string(:not_accepted),
    do: gettext("Invalid file type. Please upload MP4, WebM, or MOV.")

  defp video_error_to_string(:too_many_files), do: gettext("Only one video can be uploaded.")
  defp video_error_to_string(err), do: inspect(err)

  defp total_photo_count(socket) do
    existing = length(Map.get(socket.assigns, :existing_photos, []))

    uploading =
      case Map.get(socket.assigns, :uploads) do
        nil -> 0
        uploads -> length(uploads.photos.entries)
      end

    existing + uploading
  end

  defp has_video?(socket) do
    has_existing = Map.get(socket.assigns, :existing_video) != nil

    has_uploading =
      case Map.get(socket.assigns, :uploads) do
        nil -> false
        uploads -> uploads.video.entries != []
      end

    has_existing or has_uploading
  end

  defp pricing_type_options do
    [
      {gettext("Fixed Price"), "fixed_price"},
      {gettext("Accepts Donation"), "accepts_donation"}
    ]
  end

  defp currency_options do
    [
      {"US Dollar ($)", "USD"},
      {"Euro (€)", "EUR"},
      {"British Pound (£)", "GBP"},
      {"Indian Rupee (₹)", "INR"},
      {"Romanian Leu (lei)", "RON"},
      {"Japanese Yen (¥)", "JPY"},
      {"Chinese Yuan (¥)", "CNY"},
      {"Australian Dollar (A$)", "AUD"},
      {"Canadian Dollar (C$)", "CAD"},
      {"Swiss Franc (CHF)", "CHF"}
    ]
  end

  defp delivery_method_options do
    [
      {"express_delivery", gettext("Express Delivery"), "hero-truck"},
      {"shipping", gettext("Shipping"), "hero-paper-airplane"},
      {"local_pickup", gettext("Local Pickup"), "hero-map-pin"},
      {"in_person", gettext("In Person"), "hero-user-group"}
    ]
  end

  defp step_title(1), do: gettext("Item Details")
  defp step_title(2), do: gettext("Photos & Video")
  defp step_title(3), do: gettext("Delivery Options")

  defp step_icon(1), do: "hero-document-text"
  defp step_icon(2), do: "hero-photo"
  defp step_icon(3), do: "hero-truck"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Link --%>
        <.link
          navigate={~p"/store"}
          class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary mb-6 transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Store")}
        </.link>

        <.card size="lg">
          <div class="mb-6">
            <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
              {if @editing, do: gettext("Edit Item"), else: gettext("List New Item")}
            </h1>
            <p class="text-sm sm:text-base text-base-content/60">
              {gettext("Fill in the details to list your item on SahajStore.")}
            </p>
          </div>

          <%!-- Step Indicator --%>
          <div class="mb-8">
            <div class="flex items-center justify-between">
              <%= for step <- 1..3 do %>
                <button
                  type="button"
                  phx-click="goto_step"
                  phx-value-step={step}
                  class={[
                    "flex flex-col items-center gap-2 flex-1 transition-all",
                    @current_step == step && "text-primary",
                    @current_step != step && "text-base-content/50 hover:text-base-content/70"
                  ]}
                >
                  <div class={[
                    "w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all",
                    @current_step == step && "bg-primary border-primary text-primary-content",
                    @current_step > step && "bg-success border-success text-success-content",
                    @current_step < step && "bg-base-200 border-base-content/20"
                  ]}>
                    <%= if @current_step > step do %>
                      <.icon name="hero-check" class="w-5 h-5" />
                    <% else %>
                      <.icon name={step_icon(step)} class="w-5 h-5" />
                    <% end %>
                  </div>
                  <span class="text-xs sm:text-sm font-medium hidden sm:block">
                    {step_title(step)}
                  </span>
                </button>
                <%= if step < 3 do %>
                  <div class={[
                    "flex-1 h-0.5 mx-2",
                    @current_step > step && "bg-success",
                    @current_step <= step && "bg-base-content/20"
                  ]}>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <.form for={@form} id="store-item-form" phx-change="validate" phx-submit="save">
            <%!-- Step 1: Item Details --%>
            <div class={[@current_step != 1 && "hidden"]}>
              <div class="space-y-6">
                <div>
                  <.input
                    field={@form[:name]}
                    type="text"
                    label={gettext("Item Name")}
                    placeholder={gettext("e.g., Handmade Meditation Cushion")}
                    required
                  />
                  <p class="mt-1 text-xs text-base-content/60">
                    {gettext("Maximum 200 characters")}
                  </p>
                </div>

                <div>
                  <.input
                    field={@form[:description]}
                    type="textarea"
                    label={gettext("Description")}
                    placeholder={gettext("Describe your item in detail...")}
                    rows="5"
                  />
                  <p class="mt-1 text-xs text-base-content/60">
                    {gettext("Maximum 2000 characters")}
                  </p>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <.input
                      field={@form[:quantity]}
                      type="number"
                      label={gettext("Quantity Available")}
                      min="1"
                      required
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:currency]}
                      type="select"
                      label={gettext("Currency")}
                      options={currency_options()}
                      required
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:production_cost]}
                      type="number"
                      label={gettext("Production Cost")}
                      min="0"
                      step="0.01"
                      placeholder="0.00"
                    />
                    <p class="mt-1 text-xs text-base-content/60">
                      {gettext("Optional")}
                    </p>
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:pricing_type]}
                      type="select"
                      label={gettext("Pricing Type")}
                      options={pricing_type_options()}
                      required
                    />
                  </div>
                  <% pricing_type = Ecto.Changeset.get_field(@form.source, :pricing_type) %>
                  <div class={[pricing_type != "fixed_price" && "opacity-50"]}>
                    <.input
                      field={@form[:price]}
                      type="number"
                      label={gettext("Price")}
                      min="0.01"
                      step="0.01"
                      placeholder="0.00"
                      disabled={pricing_type != "fixed_price"}
                      required={pricing_type == "fixed_price"}
                    />
                    <p class="mt-1 text-xs text-base-content/60">
                      {if pricing_type == "fixed_price",
                        do: gettext("Required for fixed price items"),
                        else: gettext("Optional for donation-based items")}
                    </p>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <.input
                    field={@form[:phone_visible]}
                    type="checkbox"
                    label={gettext("Show my phone number on the listing")}
                  />
                </div>
              </div>
            </div>

            <%!-- Step 2: Photos & Video --%>
            <div class={[@current_step != 2 && "hidden"]}>
              <div class="space-y-6">
                <%!-- Photos Section --%>
                <div>
                  <h3 class="text-sm font-medium text-base-content mb-3 flex items-center gap-2">
                    <.icon name="hero-photo" class="w-5 h-5 text-primary" />
                    {gettext("Photos")}
                    <span class="text-base-content/50">
                      ({total_photo_count(@socket)}/5)
                    </span>
                  </h3>

                  <%!-- Existing Photos --%>
                  <%= if @existing_photos != [] do %>
                    <div class="grid grid-cols-3 sm:grid-cols-5 gap-3 mb-4">
                      <%= for photo <- @existing_photos do %>
                        <div class="relative group aspect-square">
                          <img
                            src={@photo_urls[photo.id]}
                            alt={photo.file_name}
                            class="w-full h-full object-cover rounded-lg border border-base-content/20"
                          />
                          <button
                            type="button"
                            phx-click="delete_existing_photo"
                            phx-value-id={photo.id}
                            class="absolute top-1 right-1 p-1 bg-error text-error-content rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                            aria-label={gettext("Delete photo")}
                          >
                            <.icon name="hero-x-mark" class="w-4 h-4" />
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% end %>

                  <%!-- Photo Upload Area --%>
                  <%= if total_photo_count(@socket) < 5 do %>
                    <div
                      id="photo-upload-area"
                      class="border-2 border-dashed border-base-content/30 rounded-lg p-6 text-center bg-base-100 hover:bg-base-200 transition-colors"
                      phx-drop-target={@uploads.photos.ref}
                    >
                      <.live_file_input upload={@uploads.photos} class="hidden" />
                      <label for={@uploads.photos.ref} class="cursor-pointer">
                        <.icon name="hero-photo" class="w-12 h-12 mx-auto text-base-content/40" />
                        <p class="mt-2 text-sm text-base-content/80">
                          {gettext("Click to upload or drag and drop")}
                        </p>
                        <p class="text-xs text-base-content/60">
                          {gettext("JPG, PNG, WebP, GIF - Max 50MB each (up to 5 photos)")}
                        </p>
                      </label>
                    </div>
                  <% end %>

                  <%!-- Photo Upload Progress --%>
                  <%= for entry <- @uploads.photos.entries do %>
                    <div class="mt-3 bg-base-100 p-3 rounded-lg border border-base-content/10">
                      <div class="flex items-center justify-between mb-2">
                        <div class="flex items-center gap-2 flex-1 min-w-0">
                          <.icon name="hero-photo" class="w-5 h-5 text-primary/70 flex-shrink-0" />
                          <span class="text-sm text-base-content truncate">{entry.client_name}</span>
                        </div>
                        <button
                          type="button"
                          phx-click="cancel-photo-upload"
                          phx-value-ref={entry.ref}
                          class="text-error hover:text-error/80 ml-2"
                        >
                          <.icon name="hero-x-mark" class="w-5 h-5" />
                        </button>
                      </div>
                      <div class="w-full bg-base-300 rounded-full h-2">
                        <div
                          class="bg-primary h-2 rounded-full transition-all duration-300"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                      <%= for err <- upload_errors(@uploads.photos, entry) do %>
                        <p class="mt-1 text-xs text-error">{photo_error_to_string(err)}</p>
                      <% end %>
                    </div>
                  <% end %>

                  <%= for err <- upload_errors(@uploads.photos) do %>
                    <p class="mt-2 text-xs text-error">{photo_error_to_string(err)}</p>
                  <% end %>
                </div>

                <%!-- Video Section --%>
                <div>
                  <h3 class="text-sm font-medium text-base-content mb-3 flex items-center gap-2">
                    <.icon name="hero-video-camera" class="w-5 h-5 text-primary" />
                    {gettext("Video")}
                    <span class="text-base-content/50">
                      ({if has_video?(@socket), do: "1", else: "0"}/1)
                    </span>
                    <span class="text-xs text-base-content/50">({gettext("Optional")})</span>
                  </h3>

                  <%!-- Existing Video --%>
                  <%= if @existing_video do %>
                    <div class="relative mb-4">
                      <video
                        controls
                        class="w-full max-h-64 rounded-lg border border-base-content/20"
                      >
                        <source src={@video_url} type={@existing_video.content_type} />
                      </video>
                      <button
                        type="button"
                        phx-click="delete_existing_video"
                        class="absolute top-2 right-2 p-2 bg-error text-error-content rounded-full"
                        aria-label={gettext("Delete video")}
                      >
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                      </button>
                    </div>
                  <% end %>

                  <%!-- Video Upload Area --%>
                  <%= if !has_video?(@socket) do %>
                    <div
                      id="video-upload-area"
                      class="border-2 border-dashed border-base-content/30 rounded-lg p-6 text-center bg-base-100 hover:bg-base-200 transition-colors"
                      phx-drop-target={@uploads.video.ref}
                    >
                      <.live_file_input upload={@uploads.video} class="hidden" />
                      <label for={@uploads.video.ref} class="cursor-pointer">
                        <.icon
                          name="hero-video-camera"
                          class="w-12 h-12 mx-auto text-base-content/40"
                        />
                        <p class="mt-2 text-sm text-base-content/80">
                          {gettext("Click to upload or drag and drop")}
                        </p>
                        <p class="text-xs text-base-content/60">
                          {gettext("MP4, WebM, MOV - Max 500MB")}
                        </p>
                      </label>
                    </div>
                  <% end %>

                  <%!-- Video Upload Progress --%>
                  <%= for entry <- @uploads.video.entries do %>
                    <div class="mt-3 bg-base-100 p-3 rounded-lg border border-base-content/10">
                      <div class="flex items-center justify-between mb-2">
                        <div class="flex items-center gap-2 flex-1 min-w-0">
                          <.icon
                            name="hero-video-camera"
                            class="w-5 h-5 text-primary/70 flex-shrink-0"
                          />
                          <span class="text-sm text-base-content truncate">{entry.client_name}</span>
                        </div>
                        <button
                          type="button"
                          phx-click="cancel-video-upload"
                          phx-value-ref={entry.ref}
                          class="text-error hover:text-error/80 ml-2"
                        >
                          <.icon name="hero-x-mark" class="w-5 h-5" />
                        </button>
                      </div>
                      <div class="w-full bg-base-300 rounded-full h-2">
                        <div
                          class="bg-warning h-2 rounded-full transition-all duration-300"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                      <p class="text-xs text-base-content/60 mt-1">{entry.progress}%</p>
                      <%= for err <- upload_errors(@uploads.video, entry) do %>
                        <p class="mt-1 text-xs text-error">{video_error_to_string(err)}</p>
                      <% end %>
                    </div>
                  <% end %>

                  <%= for err <- upload_errors(@uploads.video) do %>
                    <p class="mt-2 text-xs text-error">{video_error_to_string(err)}</p>
                  <% end %>
                </div>
              </div>
            </div>

            <%!-- Step 3: Delivery Options --%>
            <div class={[@current_step != 3 && "hidden"]}>
              <div class="space-y-6">
                <div>
                  <label class="block text-sm font-medium text-base-content/80 mb-3">
                    {gettext("Delivery Methods")}
                    <span class="text-error">*</span>
                  </label>
                  <p class="text-xs text-base-content/60 mb-4">
                    {gettext("Select at least one delivery method")}
                  </p>

                  <% selected_methods =
                    Ecto.Changeset.get_field(@form.source, :delivery_methods) || [] %>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <%= for {value, label, icon} <- delivery_method_options() do %>
                      <label class={[
                        "flex items-center gap-3 p-4 rounded-lg border-2 cursor-pointer transition-all",
                        value in selected_methods && "border-primary bg-primary/10",
                        value not in selected_methods &&
                          "border-base-content/20 hover:border-primary/50"
                      ]}>
                        <input
                          type="checkbox"
                          name="store_item[delivery_methods][]"
                          value={value}
                          checked={value in selected_methods}
                          class="checkbox checkbox-primary"
                        />
                        <.icon name={icon} class="w-5 h-5 text-primary" />
                        <span class="font-medium">{label}</span>
                      </label>
                    <% end %>
                  </div>
                  <%!-- Hidden input to ensure empty array is sent when nothing selected --%>
                  <input type="hidden" name="store_item[delivery_methods][]" value="" />

                  <%!-- Show validation error --%>
                  <%= if @form[:delivery_methods].errors != [] do %>
                    <p class="mt-2 text-sm text-error flex items-center gap-2">
                      <.icon name="hero-exclamation-circle" class="w-4 h-4" />
                      {gettext("Please select at least one delivery method")}
                    </p>
                  <% end %>
                </div>

                <% selected_methods = Ecto.Changeset.get_field(@form.source, :delivery_methods) || [] %>

                <%!-- Shipping Options --%>
                <%= if "shipping" in selected_methods or "express_delivery" in selected_methods do %>
                  <div class="bg-base-200/50 rounded-lg p-4 border border-base-content/10">
                    <h4 class="text-sm font-medium text-base-content mb-3 flex items-center gap-2">
                      <.icon name="hero-paper-airplane" class="w-4 h-4 text-primary" />
                      {gettext("Shipping Details")}
                    </h4>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <% currency = Ecto.Changeset.get_field(@form.source, :currency) || "EUR" %>
                        <% currency_symbol = Sahajyog.Store.StoreItem.currency_symbol(currency) %>
                        <.input
                          field={@form[:shipping_cost]}
                          type="number"
                          label={gettext("Shipping Cost (%{symbol})", symbol: currency_symbol)}
                          min="0"
                          step="0.01"
                          placeholder="0.00"
                        />
                      </div>
                      <div>
                        <.input
                          field={@form[:shipping_regions]}
                          type="text"
                          label={gettext("Ships To")}
                          placeholder={gettext("e.g., All India, Maharashtra only")}
                        />
                      </div>
                    </div>
                  </div>
                <% end %>

                <%!-- In Person Options --%>
                <%= if "in_person" in selected_methods do %>
                  <div class="bg-base-200/50 rounded-lg p-4 border border-base-content/10">
                    <h4 class="text-sm font-medium text-base-content mb-3 flex items-center gap-2">
                      <.icon name="hero-user-group" class="w-4 h-4 text-primary" />
                      {gettext("In Person Details")}
                    </h4>
                    <.input
                      field={@form[:meeting_location]}
                      type="text"
                      label={gettext("Meeting Location / City")}
                      placeholder={gettext("e.g., Mumbai, Pune")}
                    />
                  </div>
                <% end %>

                <%!-- Info Box --%>
                <div class="bg-info/10 border border-info/20 rounded-lg p-4">
                  <div class="flex items-start gap-3">
                    <.icon name="hero-information-circle" class="w-5 h-5 text-info mt-0.5" />
                    <div class="text-sm text-base-content/70">
                      <p class="font-medium text-base-content mb-1">
                        {gettext("What happens next?")}
                      </p>
                      <ul class="list-disc list-inside space-y-1">
                        <li>{gettext("Your item will be submitted for admin review")}</li>
                        <li>{gettext("Once approved, it will appear in the store")}</li>
                        <li>{gettext("You'll receive an email notification")}</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Navigation Buttons --%>
            <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-6 mt-6 border-t border-base-content/10">
              <%= if @current_step > 1 do %>
                <.secondary_button type="button" phx-click="prev_step" icon="hero-arrow-left">
                  {gettext("Previous")}
                </.secondary_button>
              <% end %>

              <div class="flex-1"></div>

              <%= if @current_step < 3 do %>
                <.primary_button type="button" phx-click="next_step" icon="hero-arrow-right">
                  {gettext("Next")}
                </.primary_button>
              <% else %>
                <.primary_button type="submit" icon="hero-check">
                  {if @editing, do: gettext("Update Item"), else: gettext("Submit for Review")}
                </.primary_button>
              <% end %>
            </div>
          </.form>
        </.card>
      </div>
    </.page_container>
    """
  end
end
