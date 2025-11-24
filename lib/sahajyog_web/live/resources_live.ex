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

    socket =
      socket
      |> assign(:selected_type, resource_type)
      |> assign(:resources, list_resources(user, resource_type))

    # Auto-open preview if preview parameter is present
    socket =
      case Map.get(params, "preview") do
        nil ->
          socket

        resource_id ->
          try do
            resource = Resources.get_resource!(String.to_integer(resource_id))
            preview_url = Sahajyog.Resources.R2Storage.generate_download_url(resource.r2_key)

            socket
            |> assign(preview_resource: resource, preview_url: preview_url)
          rescue
            _ ->
              socket
              |> put_flash(:error, gettext("Resource not found or preview unavailable"))
          end
      end

    {:noreply, socket}
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
      class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900"
      phx-hook="PreviewHandler"
      id="resources-container"
    >
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8 text-center">
          <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-3">
            {gettext("Resources")}
          </h1>
        </div>

        <%!-- Filter Tabs --%>
        <div class="mb-6 sm:mb-8">
          <div class="bg-gradient-to-br from-gray-800/80 to-gray-900/80 backdrop-blur-sm rounded-xl p-2 border border-gray-700/50 shadow-xl inline-flex flex-wrap gap-2 w-full sm:w-auto">
            <button
              phx-click="filter"
              phx-value-type="all"
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@selected_type == "all",
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name="hero-squares-2x2" class="w-4 h-4" />
              {gettext("All")}
            </button>
            <button
              :for={type <- Resource.types()}
              phx-click="filter"
              phx-value-type={type}
              class={[
                "px-4 py-2.5 rounded-lg transition-all duration-200 font-semibold text-sm sm:text-base flex items-center gap-2",
                if(@selected_type == type,
                  do: "bg-gray-700 text-white border-2 border-white",
                  else:
                    "bg-gray-700/50 text-gray-300 hover:bg-gray-700 hover:text-white border-2 border-transparent"
                )
              ]}
            >
              <.icon name={type_icon(type)} class="w-4 h-4" />
              {type}
            </button>
          </div>
        </div>

        <%!-- Resources Grid --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <div
            :for={resource <- @resources}
            class="group relative bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl overflow-hidden border border-gray-700/50 hover:border-amber-500/50 transition-all duration-300 hover:shadow-2xl hover:shadow-amber-500/10 hover:-translate-y-1 flex flex-col"
          >
            <%!-- Decorative gradient overlay --%>
            <div class="absolute inset-0 bg-gradient-to-br from-amber-500/5 to-orange-500/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            </div>

            <%!-- Thumbnail/Icon --%>
            <%= if resource.thumbnail_r2_key do %>
              <div class="relative w-full h-56 bg-gradient-to-br from-gray-800 to-gray-900 overflow-hidden flex items-center justify-center">
                <img
                  src={Resources.thumbnail_url(resource)}
                  alt={resource.title}
                  class="w-full h-full object-contain group-hover:scale-105 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-gray-900/60 via-transparent to-transparent opacity-60 pointer-events-none">
                </div>
              </div>
            <% else %>
              <div class="relative w-full h-56 bg-gradient-to-br from-gray-800 to-gray-900 flex items-center justify-center">
                <.icon
                  name={type_icon(resource.resource_type)}
                  class="w-24 h-24 text-gray-700 group-hover:text-blue-500/30 transition-colors duration-300"
                />
              </div>
            <% end %>

            <%!-- Content --%>
            <div class="relative p-5 flex flex-col flex-1">
              <%!-- Type Badge & Stats --%>
              <div class="flex items-center justify-between mb-3">
                <span class={[
                  "px-3 py-1.5 font-semibold rounded-lg text-xs border",
                  type_badge_class(resource.resource_type)
                ]}>
                  {resource.resource_type}
                </span>
                <div class="flex items-center gap-3 text-xs text-gray-400">
                  <span class="font-medium">{format_file_size(resource.file_size)}</span>
                  <span class="flex items-center gap-1">
                    <.icon name="hero-arrow-down-tray" class="w-3.5 h-3.5" />
                    {resource.downloads_count}
                  </span>
                </div>
              </div>

              <%!-- Title --%>
              <h3 class="text-lg sm:text-xl font-bold text-white mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-amber-400 transition-colors">
                {resource.title}
              </h3>

              <%!-- Description --%>
              <%= if resource.description do %>
                <p class="text-gray-400 text-sm mb-4 line-clamp-2 flex-1">{resource.description}</p>
              <% else %>
                <div class="flex-1"></div>
              <% end %>

              <%!-- Action Buttons --%>
              <div class="flex gap-2 mt-auto pt-4 border-t border-gray-700/50">
                <button
                  phx-click="preview"
                  phx-value-id={resource.id}
                  class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-gray-700/50 text-white rounded-lg hover:bg-gray-700 transition-all duration-200 font-medium text-sm border border-gray-600/50"
                >
                  <.icon name="hero-eye" class="w-4 h-4" />
                  {gettext("Preview")}
                </button>
                <.link
                  href={~p"/resources/#{resource.id}/download"}
                  class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all duration-200 font-semibold text-sm shadow-lg shadow-blue-600/20"
                >
                  <.icon name="hero-arrow-down-tray" class="w-4 h-4" />
                  {gettext("Download")}
                </.link>
              </div>
            </div>
          </div>
        </div>

        <%!-- Empty State --%>
        <%= if @resources == [] do %>
          <div class="text-center py-16">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gray-800 border border-gray-700 mb-4">
              <.icon name="hero-folder-open" class="w-10 h-10 text-gray-600" />
            </div>
            <h3 class="text-xl font-semibold text-gray-300 mb-2">
              {gettext("No resources available")}
            </h3>
            <p class="text-gray-500">{gettext("No resources available for your level")}</p>
          </div>
        <% end %>
      </div>

      <%!-- Preview Modal --%>
      <%= if @preview_resource do %>
        <div
          class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in"
          phx-click="close_preview"
        >
          <div
            class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl max-w-6xl w-full max-h-[90vh] overflow-hidden border border-gray-700/50 shadow-2xl"
            phx-click={JS.exec("phx-remove", to: "#modal-content")}
          >
            <%!-- Modal Header --%>
            <div class="flex items-center justify-between p-5 border-b border-gray-700/50 bg-gray-800/50">
              <div class="flex items-center gap-3">
                <div class="p-2 bg-amber-500/10 rounded-lg border border-amber-500/20">
                  <.icon
                    name={type_icon(@preview_resource.resource_type)}
                    class="w-5 h-5 text-amber-400"
                  />
                </div>
                <div>
                  <h3 class="text-lg font-bold text-white">{@preview_resource.title}</h3>
                  <p class="text-sm text-gray-400">
                    {format_file_size(@preview_resource.file_size)} • {@preview_resource.resource_type}
                  </p>
                </div>
              </div>
              <button
                phx-click="close_preview"
                class="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-all"
              >
                <.icon name="hero-x-mark" class="w-6 h-6" />
              </button>
            </div>

            <%!-- Modal Content --%>
            <div class="p-6 overflow-auto max-h-[calc(90vh-100px)] bg-black/20">
              <%= cond do %>
                <% String.starts_with?(@preview_resource.content_type, "image/") -> %>
                  <div class="flex items-center justify-center">
                    <img
                      src={@preview_url}
                      alt={@preview_resource.title}
                      class="max-w-full max-h-[70vh] rounded-lg shadow-2xl"
                    />
                  </div>
                <% String.contains?(@preview_resource.content_type, "pdf") -> %>
                  <iframe
                    src={@preview_url}
                    class="w-full h-[70vh] rounded-lg border border-gray-700"
                  />
                <% String.starts_with?(@preview_resource.content_type, "audio/") -> %>
                  <div class="max-w-2xl mx-auto">
                    <div class="bg-gradient-to-br from-pink-500/10 to-purple-500/10 rounded-xl p-8 border border-pink-500/20">
                      <div class="flex items-center justify-center mb-6">
                        <div class="p-6 bg-pink-500/10 rounded-full border border-pink-500/20">
                          <.icon name="hero-musical-note" class="w-16 h-16 text-pink-400" />
                        </div>
                      </div>
                      <audio controls class="w-full">
                        <source src={@preview_url} type={@preview_resource.content_type} />
                      </audio>
                    </div>
                  </div>
                <% String.starts_with?(@preview_resource.content_type, "video/") -> %>
                  <video controls class="w-full max-h-[70vh] rounded-lg shadow-2xl">
                    <source src={@preview_url} type={@preview_resource.content_type} />
                  </video>
                <% true -> %>
                  <div class="text-center py-16">
                    <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gray-800 border border-gray-700 mb-4">
                      <.icon name="hero-document" class="w-10 h-10 text-gray-500" />
                    </div>
                    <h4 class="text-xl font-semibold text-gray-300 mb-2">
                      {gettext("Preview not available")}
                    </h4>
                    <p class="text-gray-500 mb-6">
                      {gettext("Preview not available for this file type")}
                    </p>
                    <.link
                      href={~p"/resources/#{@preview_resource.id}/download"}
                      class="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all font-semibold shadow-lg shadow-blue-600/20"
                    >
                      <.icon name="hero-arrow-down-tray" class="w-5 h-5" />
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

  defp type_badge_class("Books"),
    do: "bg-blue-500/10 text-blue-400 border-blue-500/20"

  defp type_badge_class("Photos"),
    do: "bg-purple-500/10 text-purple-400 border-purple-500/20"

  defp type_badge_class("Music"),
    do: "bg-pink-500/10 text-pink-400 border-pink-500/20"

  defp type_badge_class(_), do: "bg-gray-500/10 text-gray-400 border-gray-500/20"

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  defp format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"
end
