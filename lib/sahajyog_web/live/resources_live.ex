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

  defp list_resources(user, "all"), do: Resources.list_resources_for_user(user)

  defp list_resources(user, resource_type),
    do: Resources.list_resources_for_user(user, %{resource_type: resource_type})

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white">
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
            class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden hover:border-gray-600 transition-colors"
          >
            <div class="p-4 sm:p-6">
              <div class="flex items-start justify-between mb-3">
                <div style="color: #D4A574;">
                  <.icon name={type_icon(resource.resource_type)} class="w-10 h-10 sm:w-12 sm:h-12" />
                </div>
                <span class="px-2 py-1 text-xs font-medium bg-gray-700 text-gray-300 rounded whitespace-nowrap">
                  {resource.resource_type}
                </span>
              </div>

              <h3 class="text-lg sm:text-xl font-semibold text-white mb-2 break-words">
                {resource.title}
              </h3>

              <%= if resource.description do %>
                <p class="text-gray-400 text-sm mb-4 line-clamp-3">{resource.description}</p>
              <% end %>

              <div class="flex items-center justify-between text-xs sm:text-sm text-gray-400 mb-4">
                <span>{format_file_size(resource.file_size)}</span>
                <span class="flex items-center gap-1">
                  <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                  {resource.downloads_count}
                </span>
              </div>

              <.link
                href={~p"/resources/#{resource.id}/download"}
                class="block w-full text-center px-4 py-2 sm:py-2.5 text-white rounded-lg hover:opacity-90 transition-opacity font-medium text-sm sm:text-base"
                style="background-color: #D4A574;"
              >
                {gettext("Download")}
              </.link>
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
