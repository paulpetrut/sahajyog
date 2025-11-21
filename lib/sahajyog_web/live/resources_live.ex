defmodule SahajyogWeb.ResourcesLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Resources
  alias Sahajyog.Resources.Resource

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:page_title, "Resources")
     |> assign(:selected_type, "all")
     |> assign(:user_level, user.level)
     |> assign(:preview_resource, nil)
     |> assign(:preview_url, nil)
     |> assign(:resources, Resources.list_resources_for_user(user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    resource_type = Map.get(params, "type", "all")
    user = socket.assigns.current_scope.user

    {:noreply,
     socket
     |> assign(:selected_type, resource_type)
     |> assign(:resources, list_resources(user, resource_type))}
  end

  @impl true
  def handle_event("filter", %{"type" => resource_type}, socket) do
    {:noreply, push_patch(socket, to: ~p"/resources?type=#{resource_type}")}
  end

  @impl true
  def handle_event("preview", %{"id" => id}, socket) do
    resource = Resources.get_resource!(id)

    try do
      preview_url = Sahajyog.Resources.R2Storage.generate_download_url(resource.r2_key)

      {:noreply,
       socket
       |> assign(preview_resource: resource, preview_url: preview_url)}
    rescue
      e ->
        require Logger
        Logger.error("Preview failed: #{inspect(e)}")

        {:noreply,
         socket
         |> put_flash(:error, "Preview not available. Please check R2 configuration.")
         |> assign(preview_resource: nil, preview_url: nil)}
    end
  end

  @impl true
  def handle_event("close_preview", _, socket) do
    {:noreply, assign(socket, preview_resource: nil, preview_url: nil)}
  end

  defp list_resources(user, "all"), do: Resources.list_resources_for_user(user)

  defp list_resources(user, resource_type),
    do: Resources.list_resources_for_user(user, %{resource_type: resource_type})

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-gray-900 text-white"
      phx-hook="PreviewHandler"
      id="resources-container"
    >
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
        <div class="mb-6 sm:mb-8">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-white mb-2">
                {gettext("Resources")}
              </h1>
              <p class="text-base sm:text-lg text-gray-300">
                {gettext("Your Level")}:
                <span class="font-semibold" style="color: #D4A574;">{@user_level}</span>
              </p>
            </div>
          </div>
        </div>

        <div class="mb-4 sm:mb-6 flex flex-wrap gap-2">
          <button
            phx-click="filter"
            phx-value-type="all"
            class={[
              "px-3 py-2 sm:px-4 rounded-lg transition-colors font-medium text-sm sm:text-base",
              if(@selected_type == "all",
                do: "text-white",
                else: "bg-gray-800 text-gray-300 hover:bg-gray-700"
              )
            ]}
            style={if @selected_type == "all", do: "background-color: #D4A574;"}
          >
            {gettext("All")}
          </button>
          <button
            :for={type <- Resource.types()}
            phx-click="filter"
            phx-value-type={type}
            class={[
              "px-3 py-2 sm:px-4 rounded-lg transition-colors font-medium text-sm sm:text-base",
              if(@selected_type == type,
                do: "text-white",
                else: "bg-gray-800 text-gray-300 hover:bg-gray-700"
              )
            ]}
            style={if @selected_type == type, do: "background-color: #D4A574;"}
          >
            {type}
          </button>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <div
            :for={resource <- @resources}
            class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden hover:border-gray-600 transition-colors flex flex-col"
          >
            <%= if resource.thumbnail_r2_key do %>
              <div class="w-full h-48 bg-gray-900 overflow-hidden flex items-center justify-center">
                <img
                  src={Resources.thumbnail_url(resource)}
                  alt={resource.title}
                  class="w-full h-full object-contain"
                />
              </div>
            <% else %>
              <div class="w-full h-48 bg-gray-900 flex items-center justify-center">
                <.icon
                  name={type_icon(resource.resource_type)}
                  class="w-20 h-20 text-gray-700"
                />
              </div>
            <% end %>

            <div class="p-4 sm:p-6 flex flex-col flex-1">
              <div class="flex items-center justify-between mb-3 text-xs sm:text-sm">
                <span class="px-2 py-1 font-medium bg-gray-700 text-gray-300 rounded whitespace-nowrap">
                  {resource.resource_type}
                </span>
                <div class="flex items-center gap-3 text-gray-400">
                  <span>{format_file_size(resource.file_size)}</span>
                  <span class="flex items-center gap-1">
                    <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                    {resource.downloads_count}
                  </span>
                </div>
              </div>

              <h3 class="text-lg sm:text-xl font-semibold text-white mb-2 break-words">
                {resource.title}
              </h3>

              <%= if resource.description do %>
                <p class="text-gray-400 text-sm mb-4 line-clamp-3">{resource.description}</p>
              <% end %>

              <div class="flex gap-2 mt-auto">
                <button
                  phx-click="preview"
                  phx-value-id={resource.id}
                  class="flex-1 text-center px-4 py-2 sm:py-2.5 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-medium text-sm sm:text-base"
                >
                  {gettext("Preview")}
                </button>
                <.link
                  href={~p"/resources/#{resource.id}/download"}
                  class="flex-1 text-center px-4 py-2 sm:py-2.5 text-white rounded-lg hover:opacity-90 transition-opacity font-medium text-sm sm:text-base"
                  style="background-color: #D4A574;"
                >
                  {gettext("Download")}
                </.link>
              </div>
            </div>
          </div>
        </div>

        <%= if @resources == [] do %>
          <div class="text-center py-12">
            <.icon name="hero-folder-open" class="w-16 h-16 mx-auto text-gray-600 mb-4" />
            <p class="text-gray-400 text-lg">{gettext("No resources available for your level")}</p>
          </div>
        <% end %>
      </div>

      <%!-- Preview Modal --%>
      <%= if @preview_resource do %>
        <div
          class="fixed inset-0 bg-black bg-opacity-75 z-50 flex items-center justify-center p-4"
          phx-click="close_preview"
        >
          <div class="bg-gray-800 rounded-lg max-w-6xl w-full max-h-[90vh] overflow-hidden">
            <div class="flex items-center justify-between p-4 border-b border-gray-700">
              <h3 class="text-xl font-semibold text-white">{@preview_resource.title}</h3>
              <button
                phx-click="close_preview"
                class="text-gray-400 hover:text-white transition-colors"
              >
                <.icon name="hero-x-mark" class="w-6 h-6" />
              </button>
            </div>
            <div class="p-4 overflow-auto max-h-[calc(90vh-80px)]">
              <%= cond do %>
                <% String.starts_with?(@preview_resource.content_type, "image/") -> %>
                  <img src={@preview_url} alt={@preview_resource.title} class="max-w-full mx-auto" />
                <% String.contains?(@preview_resource.content_type, "pdf") -> %>
                  <iframe src={@preview_url} class="w-full h-[70vh]" />
                <% String.starts_with?(@preview_resource.content_type, "audio/") -> %>
                  <audio controls class="w-full">
                    <source src={@preview_url} type={@preview_resource.content_type} />
                  </audio>
                <% String.starts_with?(@preview_resource.content_type, "video/") -> %>
                  <video controls class="w-full max-h-[70vh]">
                    <source src={@preview_url} type={@preview_resource.content_type} />
                  </video>
                <% true -> %>
                  <div class="text-center py-12">
                    <.icon name="hero-document" class="w-16 h-16 mx-auto text-gray-400 mb-4" />
                    <p class="text-gray-400 mb-4">
                      {gettext("Preview not available for this file type")}
                    </p>
                    <.link
                      href={~p"/resources/#{@preview_resource.id}/download"}
                      class="inline-block px-6 py-3 text-white rounded-lg hover:opacity-90 transition-opacity font-medium"
                      style="background-color: #D4A574;"
                    >
                      {gettext("Download")}
                    </.link>
                  </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp type_icon("Books"), do: "hero-book-open"
  defp type_icon("Photos"), do: "hero-photo"
  defp type_icon("Music"), do: "hero-musical-note"
  defp type_icon(_), do: "hero-document"

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end
