defmodule SahajyogWeb.StepsLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Progress
  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Steps")

    # Fetch videos from database
    db_videos = Content.list_videos_ordered()

    # Get current locale
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    # Transform database videos to match the expected format
    videos =
      Enum.map(db_videos, fn video ->
        provider = String.to_atom(video.provider || "youtube")
        video_id = Sahajyog.VideoProvider.extract_video_id(video.url, provider) || ""

        %{
          id: video.id,
          title: video.title,
          folder: video.category,
          video_id: video_id,
          provider: provider,
          duration: video.duration || "N/A",
          # Store the locale when video is loaded
          locale: locale
        }
      end)

    folder_order = ["Getting Started", "Advanced Topics", "Excerpts"]

    folders =
      videos
      |> Enum.group_by(& &1.folder)
      |> Enum.map(fn {folder, vids} -> {folder, vids, true} end)
      |> Enum.sort_by(fn {folder_name, _, _} ->
        Enum.find_index(folder_order, &(&1 == folder_name)) || 999
      end)

    # Load watched videos from database if user is logged in
    watched_videos =
      if socket.assigns[:current_scope] do
        user_id = socket.assigns.current_scope.user.id
        Progress.list_watched_video_ids(user_id) |> MapSet.new()
      else
        MapSet.new()
      end

    socket =
      socket
      |> assign(:videos, videos)
      |> assign(:folders, folders)
      |> assign(:current_video, List.first(videos))
      |> assign(:expanded_folders, MapSet.new(Enum.map(folders, fn {name, _, _} -> name end)))
      |> assign(:sidebar_open, false)
      |> assign(:watched_videos, watched_videos)
      |> assign(:sidebar_visible, true)
      |> assign(:locale, locale)
      |> assign(:show_schedule_info, false)

    {:ok, socket}
  end

  def handle_info(:clear_schedule_info, socket) do
    {:noreply, assign(socket, :show_schedule_info, false)}
  end

  def handle_event("show_notification", _params, socket) do
    Process.send_after(self(), :clear_schedule_info, 12000)
    {:noreply, assign(socket, :show_schedule_info, true)}
  end

  def handle_event("dismiss_notification", _params, socket) do
    socket = push_event(socket, "permanently_dismiss", %{})
    {:noreply, assign(socket, :show_schedule_info, false)}
  end

  def handle_event("select_video", %{"id" => id}, socket) do
    video = Enum.find(socket.assigns.videos, &(&1.id == String.to_integer(id)))

    # Update the video's locale to current locale when selected
    video = Map.put(video, :locale, socket.assigns.locale)

    {:noreply, assign(socket, :current_video, video)}
  end

  def handle_event("toggle_folder", %{"folder" => folder}, socket) do
    expanded =
      if MapSet.member?(socket.assigns.expanded_folders, folder) do
        MapSet.delete(socket.assigns.expanded_folders, folder)
      else
        MapSet.put(socket.assigns.expanded_folders, folder)
      end

    {:noreply, assign(socket, :expanded_folders, expanded)}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
  end

  def handle_event("close_sidebar", _params, socket) do
    {:noreply, assign(socket, :sidebar_open, false)}
  end

  def handle_event("mark_watched", %{"id" => id}, socket) do
    video_id = String.to_integer(id)

    socket =
      if socket.assigns[:current_scope] do
        user_id = socket.assigns.current_scope.user.id
        Progress.mark_video_watched(user_id, video_id)
        watched = MapSet.put(socket.assigns.watched_videos, video_id)
        assign(socket, :watched_videos, watched)
      else
        # For non-logged-in users, use localStorage
        watched = MapSet.put(socket.assigns.watched_videos, video_id)

        socket
        |> assign(:watched_videos, watched)
        |> push_event("update_storage", %{ids: MapSet.to_list(watched)})
      end

    {:noreply, socket}
  end

  def handle_event("load_watched", %{"ids" => ids}, socket) do
    # Only use localStorage for non-logged-in users
    socket =
      if socket.assigns[:current_scope] do
        socket
      else
        watched = MapSet.new(ids)
        assign(socket, :watched_videos, watched)
      end

    {:noreply, socket}
  end

  def handle_event("reset_progress", _params, socket) do
    socket =
      if socket.assigns[:current_scope] do
        user_id = socket.assigns.current_scope.user.id
        Progress.reset_progress(user_id)
        assign(socket, :watched_videos, MapSet.new())
      else
        # For non-logged-in users, use localStorage
        socket
        |> assign(:watched_videos, MapSet.new())
        |> push_event("update_storage", %{ids: []})
      end

    {:noreply, socket}
  end

  def handle_event("toggle_sidebar_visibility", _params, socket) do
    {:noreply, assign(socket, :sidebar_visible, !socket.assigns.sidebar_visible)}
  end

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(SahajyogWeb.Gettext, locale)
    {:noreply, assign(socket, :locale, locale)}
  end

  defp translate_category(category) do
    case category do
      "Getting Started" -> gettext("Getting Started")
      "Advanced Topics" -> gettext("Advanced Topics")
      "Excerpts" -> gettext("Excerpts")
      _ -> category
    end
  end

  defp video_item(assigns) do
    ~H"""
    <button
      phx-click="select_video"
      phx-value-id={@video.id}
      class={[
        "w-full p-3 rounded-lg text-left transition-colors flex items-start gap-3",
        @current_video && @current_video.id == @video.id &&
          "bg-gray-700 border border-blue-500",
        (!@current_video || @current_video.id != @video.id) &&
          "bg-gray-800 hover:bg-gray-700 border border-gray-700"
      ]}
    >
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium mb-1">{@video.title}</div>
        <div class="text-xs text-gray-400 flex items-center gap-2">
          <.icon name="hero-play-circle" class="w-3 h-3" />
          <span>{@video.duration}</span>
        </div>
      </div>
      <%= cond do %>
        <% MapSet.member?(@watched_videos, @video.id) -> %>
          <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
        <% @current_video && @current_video.id == @video.id -> %>
          <.icon name="hero-play" class="w-5 h-5 text-blue-500 flex-shrink-0" />
        <% true -> %>
          <div class="w-5 h-5"></div>
      <% end %>
    </button>
    """
  end

  defp video_item_desktop(assigns) do
    ~H"""
    <button
      phx-click="select_video"
      phx-value-id={@video.id}
      class={[
        "w-full px-4 py-3 text-left hover:bg-gray-700 transition-colors border-t border-gray-700 flex items-start gap-3",
        @current_video && @current_video.id == @video.id && "bg-gray-700"
      ]}
    >
      <div class="flex-1">
        <div class="text-sm font-medium">{@video.title}</div>
        <div class="text-xs text-gray-400 mt-1 flex items-center gap-2">
          <.icon name="hero-play-circle" class="w-4 h-4" />
          <span>{@video.duration}</span>
        </div>
      </div>
      <%= cond do %>
        <% MapSet.member?(@watched_videos, @video.id) -> %>
          <.icon name="hero-check-circle" class="w-5 h-5 text-green-500 flex-shrink-0" />
        <% @current_video && @current_video.id == @video.id -> %>
          <.icon name="hero-play" class="w-5 h-5 text-blue-500 flex-shrink-0" />
        <% true -> %>
          <div class="w-5 h-5"></div>
      <% end %>
    </button>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      class="bg-gray-900 text-white"
      phx-hook="WatchedVideos"
      id="watched-videos-container"
    >
      <div
        id="weekly-update-hook"
        phx-hook="ScheduleNotification"
        data-key="weekly_update_seen_v4"
        class="hidden"
      >
      </div>
      <%!-- Mobile Layout --%>
      <div class="lg:hidden">
        <%= if @current_video do %>
          <%!-- Current video player --%>
          <div class="sticky top-0 z-10 bg-gray-900">
            <div class="aspect-video bg-black">
              <.video_player
                video_id={@current_video.video_id}
                provider={@current_video.provider}
                locale={@current_video.locale}
              />
            </div>
            <div class="p-4 border-b border-gray-700">
              <h1 class="text-lg font-bold mb-2">{@current_video.title}</h1>

              <div
                class={[
                  "mb-4 mx-auto w-fit max-w-full bg-blue-600 text-white rounded-full px-4 py-2 flex items-center gap-2 shadow-lg animate-fade-in-down",
                  !@show_schedule_info && "hidden"
                ]}
                role="alert"
              >
                <.icon name="hero-information-circle" class="w-4 h-4 shrink-0" />
                <p class="text-xs font-medium truncate max-w-[200px] sm:max-w-none">
                  <span class="font-bold">{gettext("Weekly Update")}:</span>
                  <span class="opacity-90">
                    {gettext("The content on this page is refreshed every Monday.")}
                  </span>
                </p>
                <button
                  phx-click="dismiss_notification"
                  class="ml-1 p-0.5 hover:bg-white/20 rounded-full transition-colors shrink-0"
                  aria-label={gettext("Close")}
                >
                  <.icon name="hero-x-mark" class="w-3 h-3" />
                </button>
              </div>

              <%= if not MapSet.member?(@watched_videos, @current_video.id) do %>
                <button
                  phx-click="mark_watched"
                  phx-value-id={@current_video.id}
                  class="px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors flex items-center gap-2 text-sm"
                >
                  <.icon name="hero-check-circle" class="w-4 h-4" />
                  <span>{gettext("Mark as Watched")}</span>
                </button>
              <% end %>
            </div>
          </div>

          <%!-- Video list --%>
          <div class="p-4">
            <%= for {folder_name, folder_videos, _} <- @folders do %>
              <%!-- Category header --%>
              <div class="mb-4">
                <h2 class="text-lg font-semibold mb-3 text-gray-300">
                  {translate_category(folder_name)}
                </h2>
                <div class="space-y-2">
                  <%= for video <- folder_videos do %>
                    <.video_item
                      video={video}
                      current_video={@current_video}
                      watched_videos={@watched_videos}
                    />
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="flex items-center justify-center min-h-screen">
            <div class="text-center text-gray-400 p-4">
              <.icon name="hero-video-camera-slash" class="w-16 h-16 mx-auto mb-4" />
              <p class="text-xl">{gettext("No videos available")}</p>
              <p class="mt-2">{gettext("Please add videos to get started")}</p>
            </div>
          </div>
        <% end %>
      </div>

      <%!-- Desktop Layout --%>
      <div class="hidden lg:flex lg:flex-row h-screen">
        <%!-- Video player section --%>
        <div class="flex-1 flex flex-col p-4 md:p-6">
          <%= if @current_video do %>
            <%!-- Desktop title with toggle button --%>
            <div class="flex items-center justify-between mb-4">
              <h1 class="text-2xl md:text-3xl font-bold">{@current_video.title}</h1>
              <button
                phx-click="toggle_sidebar_visibility"
                class="p-2 hover:bg-gray-800 rounded-lg transition-colors"
                title={
                  if @sidebar_visible, do: gettext("Hide sidebar"), else: gettext("Show sidebar")
                }
              >
                <.icon
                  name={if @sidebar_visible, do: "hero-chevron-right", else: "hero-chevron-left"}
                  class="w-6 h-6"
                />
              </button>
            </div>

            <%!-- Video player --%>
            <div
              class={[
                "mb-6 mx-auto w-fit max-w-2xl bg-blue-600 text-white rounded-full px-6 py-2.5 flex items-center gap-3 shadow-lg animate-fade-in-down",
                !@show_schedule_info && "hidden"
              ]}
              role="alert"
            >
              <.icon name="hero-information-circle" class="w-5 h-5 shrink-0" />
              <p class="text-sm font-medium">
                <span class="font-bold">{gettext("Weekly Update")}:</span>
                <span class="opacity-90">
                  {gettext("The content on this page is refreshed every Monday.")}
                </span>
              </p>
              <button
                phx-click="dismiss_notification"
                class="ml-2 p-1 hover:bg-white/20 rounded-full transition-colors"
                aria-label={gettext("Close")}
              >
                <.icon name="hero-x-mark" class="w-4 h-4" />
              </button>
            </div>

            <div class="flex-1 bg-black rounded-lg overflow-hidden">
              <.video_player
                video_id={@current_video.video_id}
                provider={@current_video.provider}
                locale={@current_video.locale}
              />
            </div>

            <%!-- Mark as watched button --%>
            <%= if not MapSet.member?(@watched_videos, @current_video.id) do %>
              <div class="mt-4">
                <button
                  phx-click="mark_watched"
                  phx-value-id={@current_video.id}
                  class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors flex items-center gap-2"
                >
                  <.icon name="hero-check-circle" class="w-5 h-5" />
                  <span>{gettext("Mark as Watched")}</span>
                </button>
              </div>
            <% end %>
          <% else %>
            <div class="flex-1 flex items-center justify-center">
              <div class="text-center text-gray-400">
                <.icon name="hero-video-camera-slash" class="w-16 h-16 mx-auto mb-4" />
                <p class="text-xl">{gettext("No videos available")}</p>
                <p class="mt-2">{gettext("Please add videos to get started")}</p>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Desktop Sidebar --%>
        <div class={[
          "bg-gray-800 border-l border-gray-700 overflow-y-auto transition-all duration-300",
          @sidebar_visible && "w-80",
          !@sidebar_visible && "w-0 border-0 overflow-hidden"
        ]}>
          <div class="p-4">
            <%!-- Desktop title --%>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold">{gettext("SahajYog Content")}</h2>
              <%= if MapSet.size(@watched_videos) > 0 do %>
                <button
                  phx-click="reset_progress"
                  class="text-xs text-gray-400 hover:text-red-400 transition-colors"
                  title={gettext("Reset all progress")}
                >
                  <.icon name="hero-arrow-path" class="w-4 h-4" />
                </button>
              <% end %>
            </div>

            <div class="space-y-2">
              <%= for {folder_name, folder_videos, _} <- @folders do %>
                <div class="border border-gray-700 rounded-lg overflow-hidden">
                  <%!-- Folder header --%>
                  <button
                    phx-click="toggle_folder"
                    phx-value-folder={folder_name}
                    class="w-full px-4 py-3 bg-gray-750 hover:bg-gray-700 flex items-center justify-between transition-colors"
                    style="color: #c45e5eff;"
                    #
                    style="color: #D4A574;"
                  >
                    <span class="font-semibold">{translate_category(folder_name)}</span>
                    <.icon
                      name={
                        if MapSet.member?(@expanded_folders, folder_name),
                          do: "hero-chevron-down",
                          else: "hero-chevron-right"
                      }
                      class="w-5 h-5"
                    />
                  </button>

                  <%!-- Folder videos --%>
                  <div class={[
                    "transition-all duration-200",
                    unless(MapSet.member?(@expanded_folders, folder_name), do: "hidden")
                  ]}>
                    <%= for video <- folder_videos do %>
                      <.video_item_desktop
                        video={video}
                        current_video={@current_video}
                        watched_videos={@watched_videos}
                      />
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
