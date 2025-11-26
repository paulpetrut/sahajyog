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

  defp filter_options do
    base = [{"all", gettext("All"), "hero-squares-2x2"}]
    types = Enum.map(Resource.types(), fn type -> {type, type, type_icon(type)} end)
    base ++ types
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container phx-hook="PreviewHandler" id="resources-container">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-6 lg:py-8">
        <%!-- Header --%>
        <.page_header title={gettext("Resources")} centered />

        <%!-- Filter Tabs --%>
        <.filter_tabs
          options={filter_options()}
          selected={@selected_type}
          on_select="filter"
          param_name="type"
        />

        <%!-- Resources Grid --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <.card
            :for={resource <- @resources}
            hover
            class="group relative overflow-hidden flex flex-col hover:-translate-y-1"
          >
            <%!-- Decorative gradient overlay --%>
            <div class="absolute inset-0 bg-gradient-to-br from-warning/5 to-accent/5 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            </div>

            <%!-- Thumbnail/Icon --%>
            <%= if resource.thumbnail_r2_key do %>
              <div class="relative w-full h-56 bg-gradient-to-br from-base-200 to-base-300 overflow-hidden flex items-center justify-center">
                <img
                  src={Resources.thumbnail_url(resource)}
                  alt={resource.title}
                  class="w-full h-full object-contain group-hover:scale-105 transition-transform duration-300"
                />
                <div class="absolute inset-0 bg-gradient-to-t from-base-300/60 via-transparent to-transparent opacity-60 pointer-events-none">
                </div>
              </div>
            <% else %>
              <div class="relative w-full h-56 bg-gradient-to-br from-base-200 to-base-300 flex items-center justify-center">
                <.icon
                  name={type_icon(resource.resource_type)}
                  class="w-24 h-24 text-base-content/20 group-hover:text-primary/30 transition-colors duration-300"
                />
              </div>
            <% end %>

            <%!-- Content --%>
            <div class="relative p-5 flex flex-col flex-1">
              <%!-- Type Badge & Stats --%>
              <div class="flex items-center justify-between mb-3">
                <.type_badge type={resource.resource_type} />
                <div class="flex items-center gap-3 text-xs text-base-content/60">
                  <span class="font-medium">{format_file_size(resource.file_size)}</span>
                  <span class="flex items-center gap-1">
                    <.icon name="hero-arrow-down-tray" class="w-3.5 h-3.5" />
                    {resource.downloads_count}
                  </span>
                </div>
              </div>

              <%!-- Title --%>
              <h3 class="text-lg sm:text-xl font-bold text-base-content mb-2 line-clamp-2 min-h-[3.5rem] group-hover:text-warning transition-colors">
                {resource.title}
              </h3>

              <%!-- Description --%>
              <%= if resource.description do %>
                <p class="text-base-content/60 text-sm mb-4 line-clamp-2 flex-1">
                  {resource.description}
                </p>
              <% else %>
                <div class="flex-1"></div>
              <% end %>

              <%!-- Action Buttons --%>
              <div class="flex gap-2 mt-auto pt-4 border-t border-base-content/10">
                <.secondary_button
                  phx-click="preview"
                  phx-value-id={resource.id}
                  icon="hero-eye"
                  class="flex-1 px-4 py-2.5 text-sm"
                >
                  {gettext("Preview")}
                </.secondary_button>
                <.primary_button
                  href={~p"/resources/#{resource.id}/download"}
                  icon="hero-arrow-down-tray"
                  class="flex-1 px-4 py-2.5 text-sm"
                >
                  {gettext("Download")}
                </.primary_button>
              </div>
            </div>
          </.card>
        </div>

        <%!-- Empty State --%>
        <%= if @resources == [] do %>
          <.empty_state
            icon="hero-folder-open"
            title={gettext("No resources available")}
            description={gettext("No resources available for your level")}
          />
        <% end %>
      </div>

      <%!-- Preview Modal --%>
      <.modal
        :if={@preview_resource}
        id="preview-modal"
        on_close="close_preview"
        size="xl"
      >
        <:title>
          <div class="flex items-center gap-3">
            <div class="p-2 bg-warning/10 rounded-lg border border-warning/20">
              <.icon name={type_icon(@preview_resource.resource_type)} class="w-5 h-5 text-warning" />
            </div>
            <div>
              <div class="font-bold">{@preview_resource.title}</div>
              <div class="text-sm text-base-content/60 font-normal">
                {format_file_size(@preview_resource.file_size)} • {@preview_resource.resource_type}
              </div>
            </div>
          </div>
        </:title>

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
              class="w-full h-[70vh] rounded-lg border border-base-content/20"
            />
          <% String.starts_with?(@preview_resource.content_type, "audio/") -> %>
            <div class="max-w-2xl mx-auto">
              <div class="bg-gradient-to-br from-accent/10 to-secondary/10 rounded-xl p-8 border border-accent/20">
                <div class="flex items-center justify-center mb-6">
                  <div class="p-6 bg-accent/10 rounded-full border border-accent/20">
                    <.icon name="hero-musical-note" class="w-16 h-16 text-accent" />
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
            <.empty_state
              icon="hero-document"
              title={gettext("Preview not available")}
              description={gettext("Preview not available for this file type")}
            >
              <:actions>
                <.primary_button
                  href={~p"/resources/#{@preview_resource.id}/download"}
                  icon="hero-arrow-down-tray"
                >
                  {gettext("Download")}
                </.primary_button>
              </:actions>
            </.empty_state>
        <% end %>
      </.modal>
    </.page_container>
    """
  end
end
