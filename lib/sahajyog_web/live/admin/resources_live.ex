defmodule SahajyogWeb.Admin.ResourcesLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Resources
  alias Sahajyog.Resources.Resource
  alias Sahajyog.Resources.R2Storage
  alias Sahajyog.Resources.ThumbnailGenerator

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Resources")
     |> assign(:uploaded_files, [])
     |> assign(:resources, list_resources())
     |> assign(:auto_thumbnail_preview, nil)
     |> assign(:generating_thumbnail, false)
     |> allow_upload(:file,
       accept: :any,
       max_entries: 1,
       max_file_size: 500_000_000,
       progress: &handle_progress/3,
       auto_upload: true
     )
     |> allow_upload(:thumbnail,
       accept: ~w(.jpg .jpeg .png .gif .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:resource, nil)
    |> assign(:auto_thumbnail_preview, nil)
    |> assign(:generating_thumbnail, false)
  end

  defp apply_action(socket, :new, _params) do
    resource = %Resource{}
    changeset = Resources.change_resource(resource)

    socket
    |> assign(:resource, resource)
    |> assign(:form, to_form(changeset))
    |> assign(:auto_thumbnail_preview, nil)
    |> assign(:generating_thumbnail, false)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    resource = Resources.get_resource!(id)
    changeset = Resources.change_resource(resource)

    socket
    |> assign(:resource, resource)
    |> assign(:form, to_form(changeset))
    |> assign(:auto_thumbnail_preview, nil)
    |> assign(:generating_thumbnail, false)
  end

  @impl true
  def handle_event("validate", %{"resource" => resource_params}, socket) do
    changeset =
      socket.assigns.resource
      |> Resources.change_resource(resource_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"resource" => resource_params}, socket) do
    save_resource(socket, socket.assigns.live_action, resource_params)
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref, "upload" => "file"}, socket) do
    {:noreply,
     socket
     |> cancel_upload(:file, ref)
     |> assign(:auto_thumbnail_preview, nil)
     |> assign(:generating_thumbnail, false)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref, "upload" => "thumbnail"}, socket) do
    {:noreply, cancel_upload(socket, :thumbnail, ref)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(id)

    case Resources.delete_resource(resource) do
      {:ok, _} ->
        # Delete the main file from R2
        R2Storage.delete(resource.r2_key)

        # Delete the thumbnail from R2 if it exists
        if resource.thumbnail_r2_key do
          R2Storage.delete(resource.thumbnail_r2_key)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Resource deleted successfully")
         |> assign(:resources, list_resources())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete resource")}
    end
  end

  defp save_resource(socket, :new, resource_params) do
    # First validate that we have uploaded files
    if socket.assigns.uploads.file.entries == [] do
      {:noreply, put_flash(socket, :error, "Please select a file to upload")}
    else
      require Logger

      # Upload main file and generate thumbnail
      uploaded_files =
        consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
          level = Map.get(resource_params, "level", "Level1")
          resource_type = Map.get(resource_params, "resource_type", "Books")
          key = R2Storage.generate_unique_key(entry.client_name, level, resource_type)

          Logger.info("Uploading file: #{entry.client_name} to key: #{key}")

          case R2Storage.upload(path, key, content_type: entry.client_type) do
            {:ok, ^key} ->
              Logger.info("Successfully uploaded: #{key}")

              # Generate thumbnail from the uploaded file
              auto_thumbnail_key =
                generate_and_upload_thumbnail(path, entry.client_type, level, resource_type)

              {:ok,
               %{
                 key: key,
                 file_name: entry.client_name,
                 file_size: entry.client_size,
                 content_type: entry.client_type,
                 auto_thumbnail_key: auto_thumbnail_key
               }}

            {:error, reason} ->
              Logger.error("Failed to upload: #{inspect(reason)}")
              {:postpone, {:error, reason}}
          end
        end)

      # Upload manual thumbnail if provided
      uploaded_thumbnails =
        consume_uploaded_entries(socket, :thumbnail, fn %{path: path}, entry ->
          level = Map.get(resource_params, "level", "Level1")
          resource_type = Map.get(resource_params, "resource_type", "Books")
          key = R2Storage.generate_unique_key("thumb_#{entry.client_name}", level, resource_type)

          Logger.info("Uploading thumbnail: #{entry.client_name} to key: #{key}")

          case R2Storage.upload(path, key, content_type: entry.client_type) do
            {:ok, ^key} ->
              Logger.info("Successfully uploaded thumbnail: #{key}")
              {:ok, key}

            {:error, reason} ->
              Logger.error("Failed to upload thumbnail: #{inspect(reason)}")
              {:postpone, {:error, reason}}
          end
        end)

      case uploaded_files do
        [%{key: _} = file_info | _] ->
          # Priority: manual thumbnail > auto-generated thumbnail > none
          thumbnail_key =
            case uploaded_thumbnails do
              [key | _] when is_binary(key) ->
                key

              _ ->
                # Use auto-generated thumbnail from file upload
                file_info[:auto_thumbnail_key]
            end

          resource_params =
            resource_params
            |> Map.put("r2_key", file_info.key)
            |> Map.put("file_name", file_info.file_name)
            |> Map.put("file_size", file_info.file_size)
            |> Map.put("content_type", file_info.content_type)
            |> Map.put("thumbnail_r2_key", thumbnail_key)
            |> Map.put("user_id", socket.assigns.current_scope.user.id)

          case Resources.create_resource(resource_params) do
            {:ok, _resource} ->
              {:noreply,
               socket
               |> put_flash(:info, "Resource uploaded successfully")
               |> push_navigate(to: ~p"/admin/resources")}

            {:error, %Ecto.Changeset{} = changeset} ->
              {:noreply, assign(socket, :form, to_form(changeset))}
          end

        errors ->
          Logger.error("Upload errors: #{inspect(errors)}")
          {:noreply, put_flash(socket, :error, "Failed to upload file to storage")}
      end
    end
  end

  defp save_resource(socket, :edit, resource_params) do
    require Logger
    resource = socket.assigns.resource

    # Upload new thumbnail if provided
    uploaded_thumbnails =
      consume_uploaded_entries(socket, :thumbnail, fn %{path: path}, entry ->
        level = resource.level
        resource_type = resource.resource_type
        key = R2Storage.generate_unique_key("thumb_#{entry.client_name}", level, resource_type)

        Logger.info("Uploading new thumbnail: #{entry.client_name} to key: #{key}")

        case R2Storage.upload(path, key, content_type: entry.client_type) do
          {:ok, ^key} ->
            Logger.info("Successfully uploaded thumbnail: #{key}")
            # Delete old thumbnail if exists
            if resource.thumbnail_r2_key do
              R2Storage.delete(resource.thumbnail_r2_key)
            end

            {:ok, key}

          {:error, reason} ->
            Logger.error("Failed to upload thumbnail: #{inspect(reason)}")
            {:postpone, {:error, reason}}
        end
      end)

    # Update thumbnail_r2_key if new thumbnail was uploaded
    resource_params =
      case uploaded_thumbnails do
        [key | _] when is_binary(key) ->
          Map.put(resource_params, "thumbnail_r2_key", key)

        _ ->
          resource_params
      end

    case Resources.update_resource(resource, resource_params) do
      {:ok, _resource} ->
        {:noreply,
         socket
         |> put_flash(:info, "Resource updated successfully")
         |> push_navigate(to: ~p"/admin/resources")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp list_resources do
    Resources.list_resources()
  end

  defp handle_progress(:file, entry, socket) do
    if entry.done? do
      # File uploaded, generate thumbnail preview
      send(self(), {:generate_thumbnail_preview, entry.client_type})
      {:noreply, assign(socket, :generating_thumbnail, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:generate_thumbnail_preview, content_type}, socket) do
    require Logger

    socket =
      case socket.assigns.uploads.file.entries do
        [_entry | _] ->
          # Consume the entry to get the file path
          results =
            consume_uploaded_entries(socket, :file, fn %{path: path}, _entry ->
              # Generate thumbnail from uploaded file
              case ThumbnailGenerator.generate(path, content_type) do
                {:ok, thumbnail_path} ->
                  case File.read(thumbnail_path) do
                    {:ok, thumbnail_data} ->
                      # Convert to base64 for preview
                      base64_data = Base.encode64(thumbnail_data)
                      preview_url = "data:image/jpeg;base64,#{base64_data}"

                      File.rm(thumbnail_path)
                      Logger.info("Thumbnail preview generated")

                      {:postpone, {:ok, preview_url}}

                    {:error, reason} ->
                      Logger.error("Failed to read thumbnail: #{inspect(reason)}")
                      File.rm(thumbnail_path)
                      {:postpone, {:error, reason}}
                  end

                {:error, reason} ->
                  Logger.info("Thumbnail generation skipped: #{inspect(reason)}")
                  {:postpone, {:error, reason}}
              end
            end)

          case results do
            [{:ok, preview_url}] ->
              socket
              |> assign(:auto_thumbnail_preview, preview_url)
              |> assign(:generating_thumbnail, false)

            _ ->
              socket
              |> assign(:generating_thumbnail, false)
          end

        _ ->
          socket
          |> assign(:generating_thumbnail, false)
      end

    {:noreply, socket}
  end

  defp generate_and_upload_thumbnail(file_path, content_type, level, resource_type) do
    require Logger

    case ThumbnailGenerator.generate(file_path, content_type) do
      {:ok, thumbnail_path} ->
        case File.read(thumbnail_path) do
          {:ok, thumbnail_data} ->
            timestamp = System.system_time(:millisecond)

            key =
              R2Storage.generate_unique_key(
                "thumb_auto_#{timestamp}.jpg",
                level,
                resource_type
              )

            # Write to temp file for upload
            temp_path = Path.join(System.tmp_dir!(), "upload_thumb_#{timestamp}.jpg")
            File.write!(temp_path, thumbnail_data)

            result =
              case R2Storage.upload(temp_path, key, content_type: "image/jpeg") do
                {:ok, ^key} ->
                  Logger.info("Auto-generated thumbnail uploaded: #{key}")
                  key

                {:error, reason} ->
                  Logger.error("Failed to upload auto-thumbnail: #{inspect(reason)}")
                  nil
              end

            # Cleanup
            File.rm(temp_path)
            File.rm(thumbnail_path)
            result

          {:error, reason} ->
            Logger.error("Failed to read thumbnail: #{inspect(reason)}")
            File.rm(thumbnail_path)
            nil
        end

      {:error, reason} ->
        Logger.info("Thumbnail generation skipped: #{inspect(reason)}")
        nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:resources} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <%= if @live_action in [:new, :edit] do %>
          <div class="mb-6 sm:mb-8">
            <.link
              navigate={~p"/admin/resources"}
              class="text-info hover:text-info/80 mb-4 inline-flex items-center gap-1 text-sm sm:text-base focus:outline-none focus:ring-2 focus:ring-info rounded"
            >
              ← {gettext("Back to Resources")}
            </.link>
            <.resource_form
              form={@form}
              uploads={@uploads}
              live_action={@live_action}
              auto_thumbnail_preview={@auto_thumbnail_preview}
              generating_thumbnail={@generating_thumbnail}
            />
          </div>
        <% else %>
          <.page_header title={gettext("Resources")}>
            <:actions>
              <.primary_button navigate={~p"/admin/resources/new"} icon="hero-plus">
                {gettext("Upload New Resource")}
              </.primary_button>
            </:actions>
          </.page_header>

          <.card class="overflow-x-auto p-0">
            <table class="min-w-full divide-y divide-base-content/10">
              <thead class="bg-base-300">
                <tr>
                  <th class="px-3 sm:px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Title")}
                  </th>
                  <th class="hidden md:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Level")}
                  </th>
                  <th class="hidden lg:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Type")}
                  </th>
                  <th class="hidden sm:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Size")}
                  </th>
                  <th class="hidden lg:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Downloads")}
                  </th>
                  <th class="px-3 sm:px-6 py-3 text-right text-xs font-medium text-base-content/70 uppercase">
                    {gettext("Actions")}
                  </th>
                </tr>
              </thead>
              <tbody class="bg-base-200 divide-y divide-base-content/10">
                <tr :for={resource <- @resources} class="hover:bg-base-100 transition-colors">
                  <td class="px-3 sm:px-6 py-4">
                    <div class="flex items-center gap-3">
                      <%= if resource.thumbnail_r2_key do %>
                        <img
                          src={Resources.thumbnail_url(resource)}
                          alt={resource.title}
                          class="w-12 h-12 object-contain rounded"
                        />
                      <% else %>
                        <div class="w-12 h-12 bg-base-300 rounded flex items-center justify-center">
                          <.icon
                            name={type_icon(resource.resource_type)}
                            class="w-6 h-6 text-base-content/40"
                          />
                        </div>
                      <% end %>
                      <div class="flex-1 min-w-0">
                        <div class="text-sm font-medium text-base-content break-words">
                          {resource.title}
                        </div>
                        <div class="text-xs sm:text-sm text-base-content/60 truncate max-w-xs">
                          {resource.file_name}
                        </div>
                        <div class="md:hidden text-xs text-base-content/60 mt-1">
                          {resource.level} · {resource.resource_type}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="hidden md:table-cell px-3 sm:px-6 py-4 text-sm text-base-content/80">
                    {resource.level}
                  </td>
                  <td class="hidden lg:table-cell px-3 sm:px-6 py-4 text-sm text-base-content/80">
                    {resource.resource_type}
                  </td>
                  <td class="hidden sm:table-cell px-3 sm:px-6 py-4 text-sm text-base-content/80">
                    {format_file_size(resource.file_size)}
                  </td>
                  <td class="hidden lg:table-cell px-3 sm:px-6 py-4 text-sm text-base-content/80">
                    {resource.downloads_count}
                  </td>
                  <td class="px-3 sm:px-6 py-4 text-right text-sm font-medium">
                    <div class="flex flex-col sm:flex-row sm:justify-end gap-2">
                      <.link
                        navigate={~p"/admin/resources/#{resource}/edit"}
                        class="text-primary hover:text-primary/80 text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-primary rounded"
                      >
                        {gettext("Edit")}
                      </.link>
                      <.link
                        phx-click="delete"
                        phx-value-id={resource.id}
                        data-confirm={gettext("Are you sure?")}
                        class="text-error/70 hover:text-error text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-error/50 rounded"
                      >
                        {gettext("Delete")}
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </.card>
        <% end %>
      </div>
    </.page_container>
    """
  end

  defp resource_form(assigns) do
    ~H"""
    <.card size="lg">
      <h2 class="text-2xl font-bold text-base-content mb-6">
        {if @live_action == :new, do: gettext("Upload Resource"), else: gettext("Edit Resource")}
      </h2>

      <.form for={@form} id="resource-form" phx-change="validate" phx-submit="save">
        <div class="space-y-6">
          <div>
            <.input field={@form[:title]} type="text" label={gettext("Title")} required />
          </div>

          <div>
            <.input field={@form[:description]} type="textarea" label={gettext("Description")} />
          </div>

          <div>
            <.input
              field={@form[:level]}
              type="select"
              label={gettext("Level")}
              options={Resource.levels()}
              prompt={gettext("Select a level")}
              required
            />
          </div>

          <div>
            <.input
              field={@form[:resource_type]}
              type="select"
              label={gettext("Type")}
              options={Resource.types()}
              prompt={gettext("Select a type")}
              required
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-base-content/80 mb-2">
              {gettext("Thumbnail")}
              <span class="text-base-content/50 text-xs">({gettext("Optional")})</span>
            </label>

            <%!-- Generating thumbnail indicator --%>
            <%= if @live_action == :new && @generating_thumbnail do %>
              <div class="mb-3 p-3 bg-info/10 border border-info/20 rounded-lg">
                <div class="flex items-center gap-2">
                  <div class="animate-spin">
                    <.icon name="hero-arrow-path" class="w-5 h-5 text-info" />
                  </div>
                  <p class="text-sm text-info">
                    {gettext("Generating thumbnail...")}
                  </p>
                </div>
              </div>
            <% end %>
            <%!-- Auto-generated thumbnail preview --%>
            <%= if @live_action == :new && @auto_thumbnail_preview do %>
              <div class="mb-3 p-3 bg-success/10 border border-success/20 rounded-lg">
                <div class="flex items-start gap-3">
                  <img
                    src={@auto_thumbnail_preview}
                    alt="Auto-generated thumbnail"
                    class="w-20 h-20 object-cover rounded"
                  />
                  <div class="flex-1">
                    <div class="flex items-center gap-2 mb-1">
                      <.icon name="hero-sparkles" class="w-4 h-4 text-success" />
                      <p class="text-sm text-success font-medium">
                        {gettext("Thumbnail auto-generated")}
                      </p>
                    </div>
                    <p class="text-xs text-success/80">
                      {gettext("Upload a custom thumbnail below to override")}
                    </p>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if @live_action == :edit && @form.data.thumbnail_r2_key do %>
              <div class="mb-3 flex items-center gap-3 p-3 bg-base-100 rounded-lg">
                <img
                  src={Resources.thumbnail_url(@form.data)}
                  alt="Current thumbnail"
                  class="w-16 h-16 object-cover rounded"
                />
                <div class="flex-1">
                  <p class="text-sm text-base-content/80">{gettext("Current thumbnail")}</p>
                  <p class="text-xs text-base-content/60">
                    {gettext("Upload a new one to replace it")}
                  </p>
                </div>
              </div>
            <% end %>

            <div
              class="border-2 border-dashed border-base-content/30 rounded-lg p-4 text-center bg-base-100 hover:bg-base-200 transition-colors"
              phx-drop-target={@uploads.thumbnail.ref}
            >
              <.live_file_input upload={@uploads.thumbnail} class="hidden" />
              <label for={@uploads.thumbnail.ref} class="cursor-pointer">
                <.icon name="hero-photo" class="w-8 h-8 mx-auto text-base-content/40" />
                <p class="mt-1 text-xs text-base-content/80">
                  {gettext("Upload custom thumbnail")}
                </p>
                <p class="text-xs text-base-content/60">{gettext("JPG, PNG, GIF - Max 5MB")}</p>
              </label>
            </div>

            <%= for entry <- @uploads.thumbnail.entries do %>
              <div class="mt-2 bg-base-100 p-3 rounded-lg flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <.icon name="hero-photo" class="w-5 h-5 text-base-content/60" />
                  <span class="text-sm text-base-content">{entry.client_name}</span>
                </div>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-value-upload="thumbnail"
                  class="text-error hover:text-error/80 focus:outline-none focus:ring-2 focus:ring-error rounded"
                >
                  <.icon name="hero-x-mark" class="w-4 h-4" />
                </button>
              </div>
            <% end %>
          </div>

          <%= if @live_action == :new do %>
            <div>
              <label class="block text-sm font-medium text-base-content/80 mb-2">
                {gettext("File")} <span class="text-error">*</span>
              </label>
              <div
                class="border-2 border-dashed border-base-content/30 rounded-lg p-6 text-center bg-base-100 hover:bg-base-200 transition-colors"
                phx-drop-target={@uploads.file.ref}
              >
                <.live_file_input upload={@uploads.file} class="hidden" />
                <label for={@uploads.file.ref} class="cursor-pointer">
                  <.icon name="hero-arrow-up-tray" class="w-12 h-12 mx-auto text-base-content/40" />
                  <p class="mt-2 text-sm text-base-content/80">
                    {gettext("Click to upload or drag and drop")}
                  </p>
                  <p class="text-xs text-base-content/60">{gettext("Max 500MB")}</p>
                </label>
              </div>

              <%= for entry <- @uploads.file.entries do %>
                <div class="mt-4 bg-base-100 p-4 rounded-lg">
                  <div class="flex items-start justify-between mb-3">
                    <div class="flex-1">
                      <p class="text-sm font-medium text-base-content">{entry.client_name}</p>
                      <p class="text-xs text-base-content/60 mt-1">
                        {format_file_size(entry.client_size)}
                      </p>
                    </div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      phx-value-upload="file"
                      class="text-error hover:text-error/80 ml-4 focus:outline-none focus:ring-2 focus:ring-error rounded"
                    >
                      <.icon name="hero-x-mark" class="w-5 h-5" />
                    </button>
                  </div>

                  <%!-- File type indicator --%>
                  <div class="mt-3 flex items-center gap-2 text-base-content/60">
                    <.icon
                      name={
                        cond do
                          String.starts_with?(entry.client_type, "image/") -> "hero-photo"
                          String.contains?(entry.client_type, "pdf") -> "hero-document-text"
                          String.contains?(entry.client_type, "audio") -> "hero-musical-note"
                          String.contains?(entry.client_type, "video") -> "hero-video-camera"
                          true -> "hero-document"
                        end
                      }
                      class="w-8 h-8"
                    />
                    <span class="text-sm">{entry.client_type}</span>
                  </div>

                  <%!-- Upload progress --%>
                  <div class="mt-3">
                    <div class="w-full bg-base-300 rounded-full h-2">
                      <div
                        class="bg-warning h-2 rounded-full transition-all duration-300"
                        style={"width: #{entry.progress}%"}
                      >
                      </div>
                    </div>
                    <p class="text-xs text-base-content/60 mt-1">{entry.progress}%</p>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="flex gap-4 pt-4">
            <.primary_button type="submit">
              {if @live_action == :new,
                do: gettext("Upload Resource"),
                else: gettext("Update Resource")}
            </.primary_button>
            <.secondary_button navigate={~p"/admin/resources"}>
              {gettext("Cancel")}
            </.secondary_button>
          </div>
        </div>
      </.form>
    </.card>
    """
  end
end
