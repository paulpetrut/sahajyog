defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content

  def mount(_params, _session, socket) do
    welcome_videos = Content.list_videos_by_category("Welcome")
    current_video = List.first(welcome_videos)

    socket =
      socket
      |> assign(:current_video, current_video)

    {:ok, socket}
  end

  def handle_event("change_locale", %{"locale" => locale}, socket) do
    Gettext.put_locale(SahajyogWeb.Gettext, locale)
    {:noreply, assign(socket, :locale, locale)}
  end

  defp extract_youtube_id(url) do
    cond do
      String.contains?(url, "youtube.com/watch?v=") ->
        url |> String.split("v=") |> List.last() |> String.split("&") |> List.first()

      String.contains?(url, "youtu.be/") ->
        url |> String.split("youtu.be/") |> List.last() |> String.split("?") |> List.first()

      true ->
        nil
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-8 text-center">
          <h1 class="text-5xl font-bold text-white mb-4">{gettext("Welcome to Sahaja Yoga")}</h1>
          <p class="text-xl text-gray-300">
            {gettext("Discover inner peace through meditation")}
          </p>
        </div>

        <%!-- Video Player --%>
        <div :if={@current_video} class="mb-12">
          <div class="bg-gray-800 rounded-lg overflow-hidden border border-gray-700 shadow-2xl">
            <div class="aspect-video bg-black">
              <iframe
                src={"https://www.youtube.com/embed/#{extract_youtube_id(@current_video.url)}?rel=0&modestbranding=1&showinfo=0&controls=1"}
                class="w-full h-full"
                frameborder="0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                allowfullscreen
              >
              </iframe>
            </div>
            <div class="p-6">
              <h2 class="text-2xl font-bold text-white mb-2">{@current_video.title}</h2>
              <p :if={@current_video.description} class="text-gray-400">
                {@current_video.description}
              </p>
            </div>
          </div>
        </div>

        <%!-- Call to Action --%>
        <div class="bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-8 text-center">
          <h3 class="text-3xl font-bold text-white mb-4">
            {gettext("Ready to Begin Your Journey?")}
          </h3>
          <p class="text-xl text-blue-100 mb-6">
            {gettext("Explore our complete collection of talks and guided meditations")}
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <.link
              navigate="/steps"
              class="px-8 py-3 bg-white text-blue-600 rounded-lg font-semibold hover:bg-blue-50 transition-colors inline-flex items-center justify-center gap-2"
            >
              <span>{gettext("Start Learning")}</span>
              <.icon name="hero-arrow-right" class="w-5 h-5" />
            </.link>
            <.link
              navigate="/talks"
              class="px-8 py-3 bg-blue-700 text-white rounded-lg font-semibold hover:bg-blue-800 transition-colors inline-flex items-center justify-center gap-2"
            >
              <span>{gettext("Browse All Talks")}</span>
              <.icon name="hero-magnifying-glass" class="w-5 h-5" />
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
