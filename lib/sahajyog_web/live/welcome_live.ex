defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  def mount(_params, _session, socket) do
    welcome_videos = Content.list_videos_by_category("Welcome")
    current_video = List.first(welcome_videos)

    # Get current locale
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:current_video, current_video)
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

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(SahajyogWeb.Gettext, locale)
    {:noreply, assign(socket, :locale, locale)}
  end

  def render(assigns) do
    ~H"""
    <.page_container>
      <div
        id="daily-update-hook"
        phx-hook="ScheduleNotification"
        data-key="daily_update_seen_v5"
        class="hidden"
      >
      </div>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <.page_header title={gettext("Welcome to Sahaja Yoga")} centered>
          <:subtitle>{gettext("Discover inner peace through meditation")}</:subtitle>
        </.page_header>

        <%!-- Video Player --%>
        <div :if={@current_video} class="mb-12">
          <div
            class={[
              "mb-6 mx-auto w-fit max-w-2xl bg-blue-600 text-white rounded-full px-6 py-2.5 flex items-center gap-3 shadow-lg animate-fade-in-down",
              !@show_schedule_info && "hidden"
            ]}
            role="alert"
          >
            <.icon name="hero-information-circle" class="w-5 h-5 shrink-0" />
            <p class="text-sm font-medium">
              <span class="font-bold">{gettext("Daily Update")}:</span>
              <span class="opacity-90">
                {gettext("The video on this page is replaced every day.")}
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
          <.card class="overflow-hidden p-0">
            <div class="aspect-video bg-black">
              <.video_player
                video_id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                provider={:youtube}
                locale={@locale}
              />
            </div>
            <div class="p-6">
              <h2 class="text-2xl font-bold text-base-content mb-2">{@current_video.title}</h2>
              <p :if={@current_video.description} class="text-base-content/60">
                {@current_video.description}
              </p>
            </div>
          </.card>
        </div>

        <%!-- Call to Action --%>
        <div class="bg-gradient-to-r from-primary to-secondary rounded-lg p-8 text-center">
          <h3 class="text-3xl font-bold text-primary-content mb-4">
            {gettext("Ready to Begin Your Journey?")}
          </h3>
          <p class="text-xl text-primary-content/80 mb-6">
            {gettext("Explore our complete collection of talks and guided meditations")}
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <.link
              navigate="/steps"
              class="px-8 py-3 bg-purple-200 text-purple-900 rounded-lg font-semibold hover:bg-purple-100 transition-colors inline-flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-purple-200 focus:ring-offset-2 focus:ring-offset-primary shadow-lg"
            >
              <span>{gettext("Start Learning")}</span>
              <.icon name="hero-arrow-right" class="w-5 h-5" />
            </.link>
            <.link
              navigate="/talks"
              class="px-8 py-3 bg-primary/80 text-primary-content rounded-lg font-semibold hover:bg-primary/70 transition-colors inline-flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-primary-content/50 focus:ring-offset-2 focus:ring-offset-primary"
            >
              <span>{gettext("Browse All Talks")}</span>
              <.icon name="hero-magnifying-glass" class="w-5 h-5" />
            </.link>
            <%= if @current_scope do %>
              <.link
                navigate="/topics"
                class="px-8 py-3 bg-secondary/80 text-secondary-content rounded-lg font-semibold hover:bg-secondary/70 transition-colors inline-flex items-center justify-center gap-2 focus:outline-none focus:ring-2 focus:ring-secondary-content/50 focus:ring-offset-2 focus:ring-offset-secondary"
              >
                <span>{gettext("Explore Topics")}</span>
                <.icon name="hero-document-text" class="w-5 h-5" />
              </.link>
            <% end %>
          </div>
        </div>
      </div>
    </.page_container>
    """
  end
end
