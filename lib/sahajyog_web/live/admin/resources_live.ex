defmodule SahajyogWeb.Admin.ResourcesLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Resources
  alias Sahajyog.Resources.Resource
  alias Sahajyog.Resources.R2Storage

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Manage Resources")
     |> assign(:uploaded_files, [])
     |> assign(:resources, list_resources())
     |> allow_upload(:file,
       accept: :any,
       max_entries: 1,
       max_file_size: 500_000_000
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:resource, nil)
  end

  defp apply_action(socket, :new, _params) do
    resource = %Resource{}
    changeset = Resources.change_resource(resource)

    socket
    |> assign(:resource, resource)
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    resource = Resources.get_resource!(id)
    changeset = Resources.change_resource(resource)

    socket
    |> assign(:resource, resource)
    |> assign(:form, to_form(changeset))
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
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    resource = Resources.get_resource!(id)

    case Resources.delete_resource(resource) do
      {:ok, _} ->
        R2Storage.delete(resource.r2_key)

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
      uploaded_files =
        consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
          level = Map.get(resource_params, "level", "Level1")
          resource_type = Map.get(resource_params, "resource_type", "Books")
          key = R2Storage.generate_unique_key(entry.client_name, level, resource_type)

          require Logger

          Logger.info("Uploading file: #{entry.client_name} to key: #{key}")

          case R2Storage.upload(path, key, content_type: entry.client_type) do
            {:ok, ^key} ->
              Logger.info("Successfully uploaded: #{key}")

              {:ok,
               %{
                 key: key,
                 file_name: entry.client_name,
                 file_size: entry.client_size,
                 content_type: entry.client_type
               }}

            {:error, reason} ->
              Logger.error("Failed to upload: #{inspect(reason)}")
              {:postpone, {:error, reason}}
          end
        end)

      case uploaded_files do
        [%{key: _} = file_info | _] ->
          resource_params =
            resource_params
            |> Map.put("r2_key", file_info.key)
            |> Map.put("file_name", file_info.file_name)
            |> Map.put("file_size", file_info.file_size)
            |> Map.put("content_type", file_info.content_type)
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

        errors when is_list(errors) ->
          require Logger
          Logger.error("Upload errors: #{inspect(errors)}")
          {:noreply, put_flash(socket, :error, "Failed to upload file to storage")}

        [] ->
          {:noreply, put_flash(socket, :error, "File upload was cancelled or failed")}
      end
    end
  end

  defp save_resource(socket, :edit, resource_params) do
    case Resources.update_resource(socket.assigns.resource, resource_params) do
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 py-6 sm:py-8 lg:py-12 px-4">
      <div class="max-w-7xl mx-auto">
        <%= if @live_action in [:new, :edit] do %>
          <div class="mb-6 sm:mb-8">
            <.link
              navigate={~p"/admin/resources"}
              class="text-orange-400 hover:text-orange-300 mb-4 inline-flex items-center gap-1 text-sm sm:text-base"
            >
              ← {gettext("Back to Resources")}
            </.link>
            <.resource_form
              form={@form}
              uploads={@uploads}
              live_action={@live_action}
            />
          </div>
        <% else %>
          <div class="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4 mb-6 sm:mb-8">
            <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-white">
              {gettext("Resources")}
            </h1>
            <.link
              navigate={~p"/admin/resources/new"}
              class="px-4 sm:px-6 py-2 sm:py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold shadow-lg text-sm sm:text-base text-center"
            >
              {gettext("+ Upload New Resource")}
            </.link>
          </div>

          <div class="bg-gray-800 rounded-xl shadow-lg overflow-x-auto border border-gray-700">
            <table class="min-w-full divide-y divide-gray-700">
              <thead class="bg-gray-900">
                <tr>
                  <th class="px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Title")}
                  </th>
                  <th class="hidden md:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Level")}
                  </th>
                  <th class="hidden lg:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Type")}
                  </th>
                  <th class="hidden sm:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Size")}
                  </th>
                  <th class="hidden lg:table-cell px-3 sm:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase">
                    {gettext("Downloads")}
                  </th>
                  <th class="px-3 sm:px-6 py-3 text-right text-xs font-medium text-gray-300 uppercase">
                    {gettext("Actions")}
                  </th>
                </tr>
              </thead>
              <tbody class="bg-gray-800 divide-y divide-gray-700">
                <tr :for={resource <- @resources} class="hover:bg-gray-700 transition-colors">
                  <td class="px-3 sm:px-6 py-4">
                    <div class="text-sm font-medium text-white break-words">{resource.title}</div>
                    <div class="text-xs sm:text-sm text-gray-400 truncate max-w-xs">
                      {resource.file_name}
                    </div>
                    <div class="md:hidden text-xs text-gray-400 mt-1">
                      {resource.level} · {resource.resource_type}
                    </div>
                  </td>
                  <td class="hidden md:table-cell px-3 sm:px-6 py-4 text-sm text-gray-300">
                    {resource.level}
                  </td>
                  <td class="hidden lg:table-cell px-3 sm:px-6 py-4 text-sm text-gray-300">
                    {resource.resource_type}
                  </td>
                  <td class="hidden sm:table-cell px-3 sm:px-6 py-4 text-sm text-gray-300">
                    {format_file_size(resource.file_size)}
                  </td>
                  <td class="hidden lg:table-cell px-3 sm:px-6 py-4 text-sm text-gray-300">
                    {resource.downloads_count}
                  </td>
                  <td class="px-3 sm:px-6 py-4 text-right text-sm font-medium">
                    <div class="flex flex-col sm:flex-row sm:justify-end gap-2">
                      <.link
                        navigate={~p"/admin/resources/#{resource}/edit"}
                        class="text-blue-400 hover:text-blue-300 text-xs sm:text-sm"
                      >
                        {gettext("Edit")}
                      </.link>
                      <.link
                        phx-click="delete"
                        phx-value-id={resource.id}
                        data-confirm={gettext("Are you sure?")}
                        class="text-red-400 hover:text-red-300 text-xs sm:text-sm"
                      >
                        {gettext("Delete")}
                      </.link>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp resource_form(assigns) do
    ~H"""
    <div class="bg-gray-800 rounded-xl shadow-lg p-8 border border-gray-700">
      <h2 class="text-2xl font-bold text-white mb-6">
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

          <%= if @live_action == :new do %>
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">
                {gettext("File")}
              </label>
              <div
                class="border-2 border-dashed border-gray-600 rounded-lg p-6 text-center bg-gray-700 hover:bg-gray-650 transition-colors"
                phx-drop-target={@uploads.file.ref}
              >
                <.live_file_input upload={@uploads.file} class="hidden" />
                <label for={@uploads.file.ref} class="cursor-pointer">
                  <.icon name="hero-arrow-up-tray" class="w-12 h-12 mx-auto text-gray-400" />
                  <p class="mt-2 text-sm text-gray-300">
                    {gettext("Click to upload or drag and drop")}
                  </p>
                  <p class="text-xs text-gray-400">{gettext("Max 500MB")}</p>
                </label>
              </div>

              <%= for entry <- @uploads.file.entries do %>
                <div class="mt-4 bg-gray-700 p-4 rounded-lg">
                  <div class="flex items-start justify-between mb-3">
                    <div class="flex-1">
                      <p class="text-sm font-medium text-white">{entry.client_name}</p>
                      <p class="text-xs text-gray-400 mt-1">
                        {format_file_size(entry.client_size)}
                      </p>
                    </div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      class="text-red-400 hover:text-red-300 ml-4"
                    >
                      <.icon name="hero-x-mark" class="w-5 h-5" />
                    </button>
                  </div>

                  <%!-- File type indicator --%>
                  <div class="mt-3 flex items-center gap-2 text-gray-400">
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
                    <div class="w-full bg-gray-600 rounded-full h-2">
                      <div
                        class="bg-orange-600 h-2 rounded-full transition-all duration-300"
                        style={"width: #{entry.progress}%"}
                      >
                      </div>
                    </div>
                    <p class="text-xs text-gray-400 mt-1">{entry.progress}%</p>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="flex gap-4 pt-4">
            <button
              type="submit"
              class="px-6 py-3 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors font-semibold"
            >
              {if @live_action == :new,
                do: gettext("Upload Resource"),
                else: gettext("Update Resource")}
            </button>
            <.link
              navigate={~p"/admin/resources"}
              class="px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold"
            >
              {gettext("Cancel")}
            </.link>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end
