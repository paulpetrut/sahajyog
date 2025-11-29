defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  @shri_mataji_images [
    "/images/ShriMataji_585x500_1.jpg",
    "/images/ShriMataji_585x500_2.jpg",
    "/images/ShriMataji_585x500_3.jpg"
  ]

  def mount(_params, _session, socket) do
    # Get today's video from the Welcome pool rotation
    # Returns nil if the pool is empty
    current_video = Content.get_daily_video()

    # Get current locale
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    # Pick a random image on each page load
    shri_mataji_image = Enum.random(@shri_mataji_images)

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:current_video, current_video)
      |> assign(:locale, locale)
      |> assign(:show_schedule_info, false)
      |> assign(:shri_mataji_image, shri_mataji_image)

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

        <%!-- Banner container with fixed height to prevent layout shift --%>
        <div class="h-12 flex items-center justify-center mb-4 px-4">
          <div
            class={[
              "w-fit max-w-full sm:max-w-2xl bg-blue-600 text-white rounded-full px-4 sm:px-6 py-2 sm:py-2.5 flex items-center gap-2 sm:gap-3 shadow-lg transition-all duration-300",
              if(@show_schedule_info,
                do: "opacity-100 scale-100",
                else: "opacity-0 scale-95 pointer-events-none"
              )
            ]}
            role="alert"
          >
            <.icon name="hero-information-circle" class="w-4 h-4 sm:w-5 sm:h-5 shrink-0" />
            <p class="text-xs sm:text-sm font-medium">
              <span class="font-bold">{gettext("Daily Update")}:</span>
              <span class="opacity-90 hidden sm:inline">
                {gettext("The video on this page is replaced every day.")}
              </span>
              <span class="opacity-90 sm:hidden">
                {gettext("Video changes daily.")}
              </span>
            </p>
            <button
              phx-click="dismiss_notification"
              class="ml-1 sm:ml-2 p-0.5 sm:p-1 hover:bg-white/20 rounded-full transition-colors shrink-0"
              aria-label={gettext("Close")}
            >
              <.icon name="hero-x-mark" class="w-3 h-3 sm:w-4 sm:h-4" />
            </button>
          </div>
        </div>

        <%!-- Video Player --%>
        <div :if={@current_video} class="mb-12">
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

        <%!-- About Sahaja Yoga Section --%>
        <div class="mb-16">
          <h2 class="text-3xl font-bold text-base-content text-center mb-8">
            {gettext("What is Sahaja Yoga?")}
          </h2>

          <div class="grid md:grid-cols-2 gap-8 items-center mb-12">
            <div>
              <.card>
                <p class="text-base-content/80 leading-relaxed mb-4">
                  {gettext(
                    "Sahaja Yoga is a form of yoga initiated by Shri Mataji Nirmala Devi on May 5th, 1970. Through her profound meditation, she made the breakthrough that integrated the spiritual and physical dimensions, making Self Realisation accessible to all mankind."
                  )}
                </p>
                <p class="text-base-content/80 leading-relaxed mb-4">
                  {gettext(
                    "In Sanskrit, Sahaja (सहज) means 'born with' and Yoga means union. The name translates to 'the union which one is born with' - the union between your true self and the all-pervading power that permeates all elements of life."
                  )}
                </p>
                <p class="text-base-content/80 leading-relaxed">
                  {gettext(
                    "This union is achieved through awakening the dormant Kundalini energy within each human being, leading to a blissful state of thoughtless awareness where the mind is silent and you simply witness the present moment."
                  )}
                </p>
              </.card>
            </div>
            <div class="flex justify-center">
              <img
                src={@shri_mataji_image}
                alt={gettext("Shri Mataji Nirmala Devi")}
                class="rounded-2xl shadow-2xl max-w-md w-full object-cover"
              />
            </div>
          </div>

          <%!-- Benefits Grid --%>
          <div class="grid md:grid-cols-3 gap-6 mb-12">
            <.card hover class="text-center">
              <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-primary/10 flex items-center justify-center">
                <.icon name="hero-heart" class="w-8 h-8 text-primary" />
              </div>
              <h3 class="text-xl font-bold text-base-content mb-2">
                {gettext("Inner Peace")}
              </h3>
              <p class="text-base-content/70 text-sm">
                {gettext("Experience a blissful state of thoughtless awareness and mental silence")}
              </p>
            </.card>

            <.card hover class="text-center">
              <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-secondary/10 flex items-center justify-center">
                <.icon name="hero-users" class="w-8 h-8 text-secondary" />
              </div>
              <h3 class="text-xl font-bold text-base-content mb-2">
                {gettext("For Everyone")}
              </h3>
              <p class="text-base-content/70 text-sm mb-3">
                {gettext("Available to all regardless of age, background, or experience.")}
              </p>
              <span class="inline-flex items-center gap-1.5 px-3 py-1.5 bg-green-500/20 text-green-600 dark:text-green-400 rounded-full text-xs font-semibold">
                <.icon name="hero-check-badge" class="w-4 h-4" />
                {gettext("Always Free")}
              </span>
            </.card>

            <.card hover class="text-center">
              <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-accent/10 flex items-center justify-center">
                <.icon name="hero-globe-alt" class="w-8 h-8 text-accent" />
              </div>
              <h3 class="text-xl font-bold text-base-content mb-2">
                {gettext("Worldwide")}
              </h3>
              <p class="text-base-content/70 text-sm">
                {gettext("Practiced in over 90 countries by hundreds of thousands of people")}
              </p>
            </.card>
          </div>

          <%!-- Chakra System --%>
          <div class="mb-8">
            <h3 class="text-2xl font-bold text-base-content text-center mb-6">
              {gettext("The Subtle System")}
            </h3>
            <div class="grid md:grid-cols-2 gap-8 items-center">
              <div class="flex justify-center">
                <img
                  src={~p"/images/chakra_system.jpg"}
                  alt={gettext("Chakra System")}
                  class="rounded-xl shadow-lg max-w-sm"
                />
              </div>
              <div>
                <.card>
                  <p class="text-base-content/80 leading-relaxed mb-4">
                    {gettext(
                      "Sahaja Yoga meditation works directly on the central nervous system that controls all of our mental, physical and emotional activity. It, therefore, has the potential to dramatically improve our wellbeing by going directly to the source of any problem."
                    )}
                  </p>
                  <p class="text-base-content/80 leading-relaxed mb-4">
                    {gettext(
                      "The immediate effects of raising the Kundalini, and going into thoughtless awareness, can be felt as a gentle release from our mind and a spontaneous state of bliss where one merely witnesses and enjoys the present moment. However, the effects of reaching this state go far beyond those moments of mental silence."
                    )}
                  </p>
                  <p class="text-base-content/80 leading-relaxed">
                    {gettext(
                      "When the Kundalini rises, she removes the tensions occurring on our central nervous system that cause negative mental, emotional, or physical sensations, and brings our system into balance. Without any concentrated effort, we are relieved from any stress, weight or pain that we may be feeling."
                    )}
                  </p>
                </.card>
              </div>
            </div>
          </div>
        </div>

        <%!-- Quotes from Shri Mataji - Mobile/Tablet (single quote) --%>
        <div class="mb-16 lg:hidden">
          <h2 class="text-2xl sm:text-3xl font-bold text-base-content text-center mb-6">
            {gettext("Quotes from Shri Mataji")}
          </h2>
          <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-6 text-center max-w-lg mx-auto">
            <div class="flex justify-center mb-4">
              <img
                src={~p"/images/home_img_Quotes_1.png"}
                alt={gettext("Shri Mataji")}
                class="w-20 h-20 rounded-full object-cover border-4 border-primary/20 shadow-lg"
              />
            </div>
            <p class="text-xs text-primary-content/90 font-medium mb-3 bg-primary/20 rounded-full px-3 py-1 inline-block">
              03 January 1988, Ganapatipule, India
            </p>
            <blockquote class="text-sm sm:text-base text-base-content/80 italic leading-relaxed">
              "{gettext(
                "Sahaja Yoga is a very subtle happening within us. It's a very subtle happening. And this subtler happening gives you sensitivity to divine joy."
              )}"
            </blockquote>
          </div>
        </div>

        <%!-- Quotes from Shri Mataji - Desktop Carousel --%>
        <div class="mb-16 hidden lg:block">
          <h2 class="text-3xl font-bold text-base-content text-center mb-8">
            {gettext("Quotes from Shri Mataji")}
          </h2>

          <div
            id="quotes-carousel"
            phx-hook="QuotesCarousel"
            class="relative max-w-4xl mx-auto"
          >
            <%!-- Carousel Container --%>
            <div class="overflow-hidden rounded-2xl">
              <div class="carousel-track flex transition-transform duration-700 ease-in-out">
                <%!-- Quote 1 --%>
                <div class="carousel-slide min-w-full flex-shrink-0">
                  <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-4 sm:p-6 md:p-8 text-center">
                    <div class="flex justify-center mb-3 sm:mb-6">
                      <img
                        src={~p"/images/home_img_Quotes_1.png"}
                        alt={gettext("Shri Mataji")}
                        class="w-20 h-20 sm:w-28 sm:h-28 md:w-32 md:h-32 rounded-full object-cover border-4 border-primary/20 shadow-lg"
                      />
                    </div>
                    <p class="text-xs sm:text-sm text-primary-content/90 font-medium mb-3 sm:mb-4 bg-primary/20 rounded-full px-3 py-1 inline-block">
                      03 January 1988, Ganapatipule, India
                    </p>
                    <blockquote class="text-sm sm:text-base md:text-lg lg:text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto px-2">
                      "{gettext(
                        "Sahaja Yoga is a very subtle happening within us. It's a very subtle happening. And this subtler happening gives you sensitivity to divine joy."
                      )}"
                    </blockquote>
                  </div>
                </div>

                <%!-- Quote 2 --%>
                <div class="carousel-slide min-w-full flex-shrink-0">
                  <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-4 sm:p-6 md:p-8 text-center">
                    <div class="flex justify-center mb-3 sm:mb-6">
                      <img
                        src={~p"/images/home_img_Quotes_2.png"}
                        alt={gettext("Shri Mataji")}
                        class="w-20 h-20 sm:w-28 sm:h-28 md:w-32 md:h-32 rounded-full object-cover border-4 border-secondary/20 shadow-lg"
                      />
                    </div>
                    <p class="text-xs sm:text-sm text-secondary-content/90 font-medium mb-3 sm:mb-4 bg-secondary/20 rounded-full px-3 py-1 inline-block">
                      10 November 1980, Caxton Hall, UK
                    </p>
                    <blockquote class="text-sm sm:text-base md:text-lg lg:text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto px-2">
                      "{gettext(
                        "What is yoga? In simple words, it is taking your attention to the Spirit. This is yoga. What does the Kundalini do? She raises your attention and takes it to the Spirit."
                      )}"
                    </blockquote>
                  </div>
                </div>

                <%!-- Quote 3 --%>
                <div class="carousel-slide min-w-full flex-shrink-0">
                  <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-4 sm:p-6 md:p-8 text-center">
                    <div class="flex justify-center mb-3 sm:mb-6">
                      <img
                        src={~p"/images/home_img_Quotes_3.png"}
                        alt={gettext("Shri Mataji")}
                        class="w-20 h-20 sm:w-28 sm:h-28 md:w-32 md:h-32 rounded-full object-cover border-4 border-accent/20 shadow-lg"
                      />
                    </div>
                    <p class="text-xs sm:text-sm text-accent-content/90 font-medium mb-3 sm:mb-4 bg-accent/20 rounded-full px-3 py-1 inline-block">
                      27 July 1988, Armonk, New York
                    </p>
                    <blockquote class="text-sm sm:text-base md:text-lg lg:text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto px-2">
                      "{gettext(
                        "Meditation is the only way you can grow. Because when you meditate, you are in silence, you are in thoughtless awareness. Then the growth of awareness takes place."
                      )}"
                    </blockquote>
                  </div>
                </div>
              </div>
            </div>

            <%!-- Carousel Indicators --%>
            <div class="flex justify-center gap-2 mt-6">
              <button
                class="carousel-indicator w-3 h-3 rounded-full bg-base-content/30 transition-all duration-300"
                data-slide="0"
                aria-label={gettext("Go to quote 1")}
              >
              </button>
              <button
                class="carousel-indicator w-3 h-3 rounded-full bg-base-content/30 transition-all duration-300"
                data-slide="1"
                aria-label={gettext("Go to quote 2")}
              >
              </button>
              <button
                class="carousel-indicator w-3 h-3 rounded-full bg-base-content/30 transition-all duration-300"
                data-slide="2"
                aria-label={gettext("Go to quote 3")}
              >
              </button>
            </div>

            <%!-- Navigation Arrows --%>
            <button
              class="carousel-prev absolute left-2 sm:left-0 top-1/2 -translate-y-1/2 sm:-translate-x-4 md:-translate-x-12 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-base-100/90 sm:bg-base-100 shadow-lg flex items-center justify-center hover:bg-primary hover:text-primary-content transition-all duration-300 opacity-80 hover:opacity-100"
              aria-label={gettext("Previous quote")}
            >
              <.icon name="hero-chevron-left" class="w-5 h-5 sm:w-6 sm:h-6" />
            </button>
            <button
              class="carousel-next absolute right-2 sm:right-0 top-1/2 -translate-y-1/2 sm:translate-x-4 md:translate-x-12 w-10 h-10 sm:w-12 sm:h-12 rounded-full bg-base-100/90 sm:bg-base-100 shadow-lg flex items-center justify-center hover:bg-primary hover:text-primary-content transition-all duration-300 opacity-80 hover:opacity-100"
              aria-label={gettext("Next quote")}
            >
              <.icon name="hero-chevron-right" class="w-5 h-5 sm:w-6 sm:h-6" />
            </button>
          </div>
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
