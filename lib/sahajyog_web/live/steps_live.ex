defmodule SahajyogWeb.StepsLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Progress
  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, "Steps")

    # Get the current user from socket assigns (may be nil for unauthenticated users)
    user =
      case socket.assigns[:current_scope] do
        %{user: user} -> user
        _ -> nil
      end

    # Get current locale
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    # Get accessible categories for this user
    accessible_categories = Content.accessible_categories(user)

    # Build videos list based on category type:
    # - "Getting Started": Show all videos in the category
    # - "Advanced Topics" / "Excerpts": Show only weekly assigned videos for current week
    db_videos = build_videos_for_user(user, accessible_categories)

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

    # Build folders, including empty categories for Advanced Topics/Excerpts
    # when user has access but no videos are assigned for the current week
    folders = build_folders(videos, accessible_categories, folder_order)

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

  # Build the list of videos for a user based on their access level
  # - "Getting Started": All videos in the category
  # - "Advanced Topics" / "Excerpts": Only weekly assigned videos for current week
  defp build_videos_for_user(user, accessible_categories) do
    Enum.flat_map(accessible_categories, fn category ->
      case category do
        "Getting Started" ->
          # Show all Getting Started videos
          Content.list_videos_for_user(user, category)

        category when category in ["Advanced Topics", "Excerpts"] ->
          # Show only weekly assigned videos for current week
          Content.get_videos_for_current_week(category)

        _ ->
          # Other categories (like Welcome) are not shown in steps
          []
      end
    end)
  end

  # Build folders list, including empty folders for categories with no videos
  # This allows showing empty state messages for Advanced Topics/Excerpts
  defp build_folders(videos, accessible_categories, folder_order) do
    # Group videos by folder
    videos_by_folder = Enum.group_by(videos, & &1.folder)

    # Build folders for all accessible categories (except Welcome)
    accessible_categories
    |> Enum.reject(&(&1 == "Welcome"))
    |> Enum.map(fn category ->
      folder_videos = Map.get(videos_by_folder, category, [])
      {category, folder_videos, folder_videos != []}
    end)
    |> Enum.sort_by(fn {folder_name, _, _} ->
      Enum.find_index(folder_order, &(&1 == folder_name)) || 999
    end)
  end

  defp translate_category(category) do
    case category do
      "Getting Started" -> gettext("Getting Started")
      "Advanced Topics" -> gettext("Advanced Topics")
      "Excerpts" -> gettext("Excerpts")
      _ -> category
    end
  end

  # Empty state message for mobile view
  defp empty_folder_message(assigns) do
    ~H"""
    <div class="p-4 bg-base-200 rounded-lg border border-base-content/20 text-center">
      <.icon name="hero-calendar" class="w-8 h-8 mx-auto mb-2 text-base-content/40" />
      <p class="text-sm text-base-content/60">
        {gettext("No videos scheduled for this week")}
      </p>
      <p class="text-xs text-base-content/40 mt-1">
        {gettext("Check back later for new content")}
      </p>
    </div>
    """
  end

  # Empty state message for desktop sidebar
  defp empty_folder_message_desktop(assigns) do
    ~H"""
    <div class="px-4 py-6 text-center border-t border-base-content/20">
      <.icon name="hero-calendar" class="w-6 h-6 mx-auto mb-2 text-base-content/40" />
      <p class="text-xs text-base-content/60">
        {gettext("No videos scheduled for this week")}
      </p>
    </div>
    """
  end

  defp video_item(assigns) do
    ~H"""
    <button
      phx-click="select_video"
      phx-value-id={@video.id}
      class={[
        "w-full p-3 rounded-lg text-left transition-colors flex items-start gap-3",
        @current_video && @current_video.id == @video.id &&
          "bg-base-100 border border-primary",
        (!@current_video || @current_video.id != @video.id) &&
          "bg-base-200 hover:bg-base-100 border border-base-content/20"
      ]}
    >
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium mb-1 text-base-content">{@video.title}</div>
        <div class="text-xs text-base-content/60 flex items-center gap-2">
          <.icon name="hero-play-circle" class="w-3 h-3" />
          <span>{@video.duration}</span>
        </div>
      </div>
      <%= cond do %>
        <% MapSet.member?(@watched_videos, @video.id) -> %>
          <.icon name="hero-check-circle" class="w-5 h-5 text-success flex-shrink-0" />
        <% @current_video && @current_video.id == @video.id -> %>
          <.icon name="hero-play" class="w-5 h-5 text-primary flex-shrink-0" />
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
        "w-full px-4 py-3 text-left hover:bg-base-100 transition-colors border-t border-base-content/20 flex items-start gap-3",
        @current_video && @current_video.id == @video.id && "bg-base-100"
      ]}
    >
      <div class="flex-1">
        <div class="text-sm font-medium text-base-content">{@video.title}</div>
        <div class="text-xs text-base-content/60 mt-1 flex items-center gap-2">
          <.icon name="hero-play-circle" class="w-4 h-4" />
          <span>{@video.duration}</span>
        </div>
      </div>
      <%= cond do %>
        <% MapSet.member?(@watched_videos, @video.id) -> %>
          <.icon name="hero-check-circle" class="w-5 h-5 text-success flex-shrink-0" />
        <% @current_video && @current_video.id == @video.id -> %>
          <.icon name="hero-play" class="w-5 h-5 text-primary flex-shrink-0" />
        <% true -> %>
          <div class="w-5 h-5"></div>
      <% end %>
    </button>
    """
  end

  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300 text-base-content noise-overlay"
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
          <div class="sticky top-0 z-10 bg-base-300">
            <div class="aspect-video bg-black">
              <.video_player
                video_id={@current_video.video_id}
                provider={@current_video.provider}
                locale={@current_video.locale}
              />
            </div>
            <div class="p-4 border-b border-base-content/20">
              <h1 class="text-lg font-bold mb-2 text-base-content">{@current_video.title}</h1>

              <%!-- Banner with fixed height container --%>
              <div class="h-10 flex items-center justify-center">
                <div
                  class={[
                    "w-fit max-w-full bg-blue-600 text-white rounded-full px-4 py-2 flex items-center gap-2 shadow-lg transition-all duration-300",
                    if(@show_schedule_info,
                      do: "opacity-100 scale-100",
                      else: "opacity-0 scale-95 pointer-events-none"
                    )
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
              </div>

              <%= if not MapSet.member?(@watched_videos, @current_video.id) do %>
                <button
                  phx-click="mark_watched"
                  phx-value-id={@current_video.id}
                  class="px-3 py-2 bg-success hover:bg-success/80 text-success-content rounded-lg transition-colors flex items-center gap-2 text-sm"
                >
                  <.icon name="hero-check-circle" class="w-4 h-4" />
                  <span>{gettext("Mark as Watched")}</span>
                </button>
              <% end %>
            </div>
          </div>

          <%!-- Video list --%>
          <div class="p-4">
            <%= for {folder_name, folder_videos, has_videos} <- @folders do %>
              <%!-- Category header --%>
              <div class="mb-4">
                <h2 class="text-lg font-semibold mb-3 text-primary">
                  {translate_category(folder_name)}
                </h2>
                <%= if has_videos do %>
                  <div class="space-y-2">
                    <%= for video <- folder_videos do %>
                      <.video_item
                        video={video}
                        current_video={@current_video}
                        watched_videos={@watched_videos}
                      />
                    <% end %>
                  </div>
                <% else %>
                  <.empty_folder_message folder_name={folder_name} />
                <% end %>
              </div>
            <% end %>
          </div>
        <% else %>
          <div class="flex items-center justify-center min-h-screen">
            <div class="text-center text-base-content/60 p-4">
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
              <h1 class="text-2xl md:text-3xl font-bold text-base-content">{@current_video.title}</h1>
              <button
                phx-click="toggle_sidebar_visibility"
                class="p-2 hover:bg-base-200 rounded-lg transition-colors"
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

            <%!-- Banner with fixed height container --%>
            <div class="h-12 flex items-center justify-center mb-4">
              <div
                class={[
                  "w-fit max-w-2xl bg-blue-600 text-white rounded-full px-6 py-2.5 flex items-center gap-3 shadow-lg transition-all duration-300",
                  if(@show_schedule_info,
                    do: "opacity-100 scale-100",
                    else: "opacity-0 scale-95 pointer-events-none"
                  )
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
            </div>

            <%!-- Video player --%>
            <div class="flex-1 flex items-start justify-center">
              <div class="w-full max-w-5xl aspect-video bg-black rounded-lg overflow-hidden">
                <.video_player
                  video_id={@current_video.video_id}
                  provider={@current_video.provider}
                  locale={@current_video.locale}
                />
              </div>
            </div>

            <%!-- Mark as watched button --%>
            <%= if not MapSet.member?(@watched_videos, @current_video.id) do %>
              <div class="mt-4">
                <button
                  phx-click="mark_watched"
                  phx-value-id={@current_video.id}
                  class="px-4 py-2 bg-success hover:bg-success/80 text-success-content rounded-lg transition-colors flex items-center gap-2"
                >
                  <.icon name="hero-check-circle" class="w-5 h-5" />
                  <span>{gettext("Mark as Watched")}</span>
                </button>
              </div>
            <% end %>
          <% else %>
            <div class="flex-1 flex items-center justify-center">
              <div class="text-center text-base-content/60">
                <.icon name="hero-video-camera-slash" class="w-16 h-16 mx-auto mb-4" />
                <p class="text-xl">{gettext("No videos available")}</p>
                <p class="mt-2">{gettext("Please add videos to get started")}</p>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Desktop Sidebar --%>
        <div class={[
          "bg-base-200 border-l border-base-content/20 overflow-y-auto transition-all duration-300",
          @sidebar_visible && "w-80",
          !@sidebar_visible && "w-0 border-0 overflow-hidden"
        ]}>
          <div class="p-4">
            <%!-- Desktop title --%>
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-xl font-semibold text-base-content">{gettext("SahajYog Content")}</h2>
              <%= if MapSet.size(@watched_videos) > 0 do %>
                <button
                  phx-click="reset_progress"
                  class="text-xs text-base-content/60 hover:text-error transition-colors"
                  title={gettext("Reset all progress")}
                >
                  <.icon name="hero-arrow-path" class="w-4 h-4" />
                </button>
              <% end %>
            </div>

            <div class="space-y-2">
              <%= for {folder_name, folder_videos, has_videos} <- @folders do %>
                <div class="border border-base-content/20 rounded-lg overflow-hidden">
                  <%!-- Folder header --%>
                  <button
                    phx-click="toggle_folder"
                    phx-value-folder={folder_name}
                    class="w-full px-4 py-3 bg-base-300 hover:bg-base-100 flex items-center justify-between transition-colors text-primary"
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
                    <%= if has_videos do %>
                      <%= for video <- folder_videos do %>
                        <.video_item_desktop
                          video={video}
                          current_video={@current_video}
                          watched_videos={@watched_videos}
                        />
                      <% end %>
                    <% else %>
                      <.empty_folder_message_desktop folder_name={folder_name} />
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
