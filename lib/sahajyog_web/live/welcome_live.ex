defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  @shri_mataji_images [
    "/images/ShriMataji_585x500_1.jpg",
    "/images/ShriMataji_585x500_2.jpg",
    "/images/ShriMataji_585x500_3.jpg"
  ]

  @testimonials [
    %{
      name: "Maria",
      location: "Romania",
      text:
        "Sahaja Yoga has transformed my life. The inner peace I've found through meditation is something I never thought possible.",
      avatar: "M"
    },
    %{
      name: "John",
      location: "United Kingdom",
      text:
        "After 20 years of practice, I can say that Sahaja Yoga is the most precious gift. It's free, it's real, and it works.",
      avatar: "J"
    },
    %{
      name: "Priya",
      location: "India",
      text:
        "The collective meditations have helped me connect with wonderful people from all over the world. We are truly one family.",
      avatar: "P"
    }
  ]

  def mount(_params, _session, socket) do
    current_video = Content.get_daily_video()
    locale = Gettext.get_locale(SahajyogWeb.Gettext)
    shri_mataji_image = Enum.random(@shri_mataji_images)

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:current_video, current_video)
      |> assign(:locale, locale)
      |> assign(:show_schedule_info, false)
      |> assign(:shri_mataji_image, shri_mataji_image)
      |> assign(:testimonials, @testimonials)

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
    <div id="welcome-page" phx-hook="WelcomeAnimations" class="overflow-x-hidden">
      <%!-- Scroll Progress Bar --%>
      <div id="scroll-progress" class="scroll-progress" style="width: 0%"></div>

      <%!-- Animated gradient background --%>
      <div class="min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300 animate-gradient overflow-x-hidden">
        <%!-- Hidden hooks --%>
        <div
          id="daily-update-hook"
          phx-hook="ScheduleNotification"
          data-key="daily_update_seen_v5"
          class="hidden"
        >
        </div>

        <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-6 sm:py-8">
          <%!-- Hero Section with entrance animations --%>
          <section id="hero-section" class="text-center mb-12">
            <h1 class="text-2xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-4 animate-hero-fade-up">
              {gettext("Welcome to Sahaja Yoga")}
            </h1>
            <p class="text-base sm:text-xl lg:text-2xl text-base-content/70 mb-6 animate-hero-fade-up-delay-1">
              {gettext("Discover inner peace through meditation")}
            </p>

            <%!-- Daily update banner --%>
            <div class="h-12 flex items-center justify-center mb-4 px-4 animate-hero-fade-up-delay-2">
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
          </section>

          <%!-- Video Player --%>
          <section :if={@current_video} class="mb-32 sm:mb-16">
            <.card class="overflow-hidden p-0">
              <div class="aspect-video bg-black">
                <.video_player
                  video_id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                  provider={:youtube}
                  locale={@locale}
                />
              </div>
              <div class="p-4 sm:p-6">
                <h2 class="text-xl sm:text-2xl font-bold text-base-content mb-2 break-words">
                  {@current_video.title}
                </h2>
                <p :if={@current_video.description} class="text-base-content/60">
                  {@current_video.description}
                </p>
              </div>
            </.card>
          </section>

          <%!-- Scroll Indicator - hidden on mobile --%>
          <div
            id="scroll-indicator"
            class="hidden sm:flex flex-col items-center mb-32 animate-bounce-slow transition-opacity duration-500"
          >
            <p class="text-base-content/50 text-sm mb-2">{gettext("Scroll to explore")}</p>
            <.icon name="hero-chevron-double-down" class="w-6 h-6 text-base-content/40" />
          </div>

          <%!-- About Sahaja Yoga Section --%>
          <section class="mb-16 scroll-reveal">
            <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold text-base-content text-center mb-6 sm:mb-8">
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
                  class="rounded-2xl shadow-2xl max-w-md w-full object-cover animate-float"
                />
              </div>
            </div>
          </section>

          <%!-- Chakra System --%>
          <section class="mb-16 scroll-reveal">
            <h3 class="text-lg sm:text-xl lg:text-2xl font-bold text-base-content text-center mb-4 sm:mb-6">
              {gettext("The Subtle System")}
            </h3>
            <div class="grid md:grid-cols-2 gap-8 items-center">
              <div class="flex justify-center order-2 md:order-1">
                <img
                  src={~p"/images/chakra_system.jpg"}
                  alt={gettext("Chakra System")}
                  class="rounded-xl shadow-lg w-full max-w-sm hover:scale-105 transition-transform duration-500"
                />
              </div>
              <div class="order-1 md:order-2">
                <.card>
                  <p class="text-base-content/80 leading-relaxed mb-4">
                    {gettext(
                      "Sahaja Yoga meditation works directly on the central nervous system that controls all of our mental, physical and emotional activity. It, therefore, has the potential to dramatically improve our wellbeing by going directly to the source of any problem."
                    )}
                  </p>
                  <p class="text-base-content/80 leading-relaxed mb-4">
                    {gettext(
                      "The immediate effects of raising the Kundalini, and going into thoughtless awareness, can be felt as a gentle release from our mind and a spontaneous state of bliss where one merely witnesses and enjoys the present moment."
                    )}
                  </p>
                  <p class="text-base-content/80 leading-relaxed">
                    {gettext(
                      "When the Kundalini rises, she removes the tensions occurring on our central nervous system that cause negative mental, emotional, or physical sensations, and brings our system into balance."
                    )}
                  </p>
                </.card>
              </div>
            </div>
          </section>

          <%!-- Quotes from Shri Mataji - Mobile/Tablet (single quote) --%>
          <section class="mb-16 lg:hidden scroll-reveal">
            <h2 class="text-lg sm:text-2xl font-bold text-base-content text-center mb-4 sm:mb-6">
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
          </section>

          <%!-- Quotes from Shri Mataji - Desktop Carousel --%>
          <section class="mb-16 hidden lg:block scroll-reveal">
            <h2 class="text-3xl font-bold text-base-content text-center mb-8">
              {gettext("Quotes from Shri Mataji")}
            </h2>

            <div
              id="quotes-carousel"
              phx-hook="QuotesCarousel"
              class="relative max-w-4xl mx-auto"
            >
              <div class="overflow-hidden rounded-2xl">
                <div class="carousel-track flex transition-transform duration-700 ease-in-out">
                  <%!-- Quote 1 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-8 text-center">
                      <div class="flex justify-center mb-6">
                        <img
                          src={~p"/images/home_img_Quotes_1.png"}
                          alt={gettext("Shri Mataji")}
                          class="w-32 h-32 rounded-full object-cover border-4 border-primary/20 shadow-lg"
                        />
                      </div>
                      <p class="text-sm text-primary-content/90 font-medium mb-4 bg-primary/20 rounded-full px-3 py-1 inline-block">
                        03 January 1988, Ganapatipule, India
                      </p>
                      <blockquote class="text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto">
                        "{gettext(
                          "Sahaja Yoga is a very subtle happening within us. It's a very subtle happening. And this subtler happening gives you sensitivity to divine joy."
                        )}"
                      </blockquote>
                    </div>
                  </div>

                  <%!-- Quote 2 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-8 text-center">
                      <div class="flex justify-center mb-6">
                        <img
                          src={~p"/images/home_img_Quotes_2.png"}
                          alt={gettext("Shri Mataji")}
                          class="w-32 h-32 rounded-full object-cover border-4 border-secondary/20 shadow-lg"
                        />
                      </div>
                      <p class="text-sm text-secondary-content/90 font-medium mb-4 bg-secondary/20 rounded-full px-3 py-1 inline-block">
                        10 November 1980, Caxton Hall, UK
                      </p>
                      <blockquote class="text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto">
                        "{gettext(
                          "What is yoga? In simple words, it is taking your attention to the Spirit. This is yoga. What does the Kundalini do? She raises your attention and takes it to the Spirit."
                        )}"
                      </blockquote>
                    </div>
                  </div>

                  <%!-- Quote 3 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-8 text-center">
                      <div class="flex justify-center mb-6">
                        <img
                          src={~p"/images/home_img_Quotes_3.png"}
                          alt={gettext("Shri Mataji")}
                          class="w-32 h-32 rounded-full object-cover border-4 border-accent/20 shadow-lg"
                        />
                      </div>
                      <p class="text-sm text-accent-content/90 font-medium mb-4 bg-accent/20 rounded-full px-3 py-1 inline-block">
                        27 July 1988, Armonk, New York
                      </p>
                      <blockquote class="text-xl text-base-content/80 italic leading-relaxed max-w-3xl mx-auto">
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
                class="carousel-prev absolute left-0 top-1/2 -translate-y-1/2 -translate-x-12 w-12 h-12 rounded-full bg-base-100 shadow-lg flex items-center justify-center hover:bg-primary hover:text-primary-content transition-all duration-300"
                aria-label={gettext("Previous quote")}
              >
                <.icon name="hero-chevron-left" class="w-6 h-6" />
              </button>
              <button
                class="carousel-next absolute right-0 top-1/2 -translate-y-1/2 translate-x-12 w-12 h-12 rounded-full bg-base-100 shadow-lg flex items-center justify-center hover:bg-primary hover:text-primary-content transition-all duration-300"
                aria-label={gettext("Next quote")}
              >
                <.icon name="hero-chevron-right" class="w-6 h-6" />
              </button>
            </div>
          </section>

          <%!-- Testimonials Section --%>
          <section class="mb-16 scroll-reveal">
            <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold text-base-content text-center mb-4">
              {gettext("What Practitioners Say")}
            </h2>
            <p class="text-base-content/60 text-center mb-10 max-w-2xl mx-auto">
              {gettext("Join thousands of people who have found peace through Sahaja Yoga")}
            </p>

            <div class="grid md:grid-cols-3 gap-6">
              <%= for {testimonial, idx} <- Enum.with_index(@testimonials) do %>
                <div class="testimonial-card bg-gradient-to-br from-base-200 to-base-300 rounded-2xl p-6 border border-base-content/10">
                  <div class="flex items-center gap-3 mb-4">
                    <div class="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-lg">
                      {testimonial.avatar}
                    </div>
                    <div>
                      <p class="font-semibold text-base-content">{testimonial.name}</p>
                      <p class="text-sm text-base-content/60">{testimonial.location}</p>
                    </div>
                  </div>
                  <p class="text-base-content/80 italic">"{testimonial.text}"</p>
                </div>
              <% end %>
            </div>
          </section>

          <%!-- Statistics Section with animated counters --%>
          <section id="stats-section" class="mb-16 scroll-reveal">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8">
              <div class="text-center p-6 bg-gradient-to-br from-primary/10 to-primary/5 rounded-2xl border border-primary/20">
                <div class="text-4xl md:text-5xl font-bold text-primary mb-2">
                  <span data-counter="90">0</span>+
                </div>
                <p class="text-base-content/70 font-medium">{gettext("Countries")}</p>
              </div>
              <div class="text-center p-6 bg-gradient-to-br from-secondary/10 to-secondary/5 rounded-2xl border border-secondary/20">
                <div class="text-4xl md:text-5xl font-bold text-secondary mb-2">
                  <span data-counter="55">0</span>+
                </div>
                <p class="text-base-content/70 font-medium">{gettext("Years")}</p>
              </div>
              <div class="text-center p-6 bg-gradient-to-br from-success/10 to-success/5 rounded-2xl border border-success/20">
                <div class="text-4xl md:text-5xl font-bold text-success mb-2">
                  100%
                </div>
                <p class="text-base-content/70 font-medium">{gettext("Free Forever")}</p>
              </div>
              <div class="text-center p-6 bg-gradient-to-br from-info/10 to-info/5 rounded-2xl border border-info/20">
                <div class="text-4xl md:text-5xl font-bold text-info mb-2">
                  <span data-counter="1000">0</span>+
                </div>
                <p class="text-base-content/70 font-medium">{gettext("Talks Available")}</p>
              </div>
            </div>
          </section>

          <%!-- How It Works Section --%>
          <section id="how-it-works" class="mb-16 scroll-reveal">
            <h2 class="text-xl sm:text-2xl lg:text-3xl font-bold text-base-content text-center mb-4">
              {gettext("How It Works")}
            </h2>
            <p class="text-base-content/60 text-center mb-10 max-w-2xl mx-auto">
              {gettext("Begin your journey to inner peace in three simple steps")}
            </p>

            <div class="grid md:grid-cols-3 gap-8">
              <%!-- Step 1 --%>
              <div class="relative step-card">
                <div class="text-center p-6 rounded-2xl hover:bg-base-200/50 transition-colors">
                  <div class="step-circle step-circle-1 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                    <span class="text-4xl font-bold text-primary-content">1</span>
                  </div>
                  <h3 class="text-lg sm:text-xl lg:text-2xl font-bold text-base-content mb-3">
                    {gettext("Learn")}
                  </h3>
                  <p class="text-base-content/70 text-lg">
                    {gettext("Watch introductory videos and understand the basics of meditation")}
                  </p>
                </div>
                <%!-- Connector line (hidden on mobile) --%>
                <div class="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-primary/50 to-transparent">
                </div>
              </div>

              <%!-- Step 2 --%>
              <div class="relative step-card">
                <div class="text-center p-6 rounded-2xl hover:bg-base-200/50 transition-colors">
                  <div class="step-circle step-circle-2 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                    <span class="text-4xl font-bold text-primary-content">2</span>
                  </div>
                  <h3 class="text-lg sm:text-xl lg:text-2xl font-bold text-base-content mb-3">
                    {gettext("Practice")}
                  </h3>
                  <p class="text-base-content/70 text-lg">
                    {gettext("Follow guided meditations and experience Self Realization")}
                  </p>
                </div>
                <div class="hidden md:block absolute top-12 left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-primary/50 to-transparent">
                </div>
              </div>

              <%!-- Step 3 --%>
              <div class="step-card">
                <div class="text-center p-6 rounded-2xl hover:bg-base-200/50 transition-colors">
                  <div class="step-circle step-circle-3 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                    <span class="text-4xl font-bold text-primary-content">3</span>
                  </div>
                  <h3 class="text-lg sm:text-xl lg:text-2xl font-bold text-base-content mb-3">
                    {gettext("Experience")}
                  </h3>
                  <p class="text-base-content/70 text-lg">
                    {gettext("Feel the peace within and grow through regular practice")}
                  </p>
                </div>
              </div>
            </div>
          </section>

          <%!-- Call to Action --%>
          <section class="scroll-reveal-scale">
            <%= if @current_scope do %>
              <%!-- Authenticated user CTA --%>
              <div class="bg-gradient-to-r from-primary to-secondary rounded-2xl p-8 md:p-12 text-center animate-gradient">
                <h3 class="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-primary-content mb-4">
                  {gettext("Ready to Begin Your Journey?")}
                </h3>
                <p class="text-base sm:text-lg md:text-xl text-primary-content/80 mb-8 max-w-2xl mx-auto">
                  {gettext("Explore our complete collection of talks and guided meditations")}
                </p>
                <div class="flex flex-col sm:flex-row gap-4 justify-center">
                  <.link
                    navigate="/steps"
                    class="px-8 py-4 bg-white text-primary rounded-full font-semibold hover:bg-white/90 transition-all duration-300 inline-flex items-center justify-center gap-2 shadow-lg hover:shadow-xl hover:scale-105"
                  >
                    <.icon name="hero-play-circle" class="w-5 h-5" />
                    {gettext("Start Learning")}
                  </.link>
                  <.link
                    navigate="/talks"
                    class="px-8 py-4 bg-primary-content/20 text-primary-content rounded-full font-semibold hover:bg-primary-content/30 transition-all duration-300 inline-flex items-center justify-center gap-2 border border-primary-content/30"
                  >
                    <.icon name="hero-magnifying-glass" class="w-5 h-5" />
                    {gettext("Browse All Talks")}
                  </.link>
                  <.link
                    navigate="/topics"
                    class="px-8 py-4 bg-secondary/80 text-secondary-content rounded-full font-semibold hover:bg-secondary/70 transition-all duration-300 inline-flex items-center justify-center gap-2"
                  >
                    <.icon name="hero-document-text" class="w-5 h-5" />
                    {gettext("Explore Topics")}
                  </.link>
                </div>
              </div>
            <% else %>
              <%!-- Unauthenticated user CTA - encourage registration --%>
              <div class="bg-gradient-to-r from-primary to-secondary rounded-2xl p-8 md:p-12 text-center animate-gradient">
                <h3 class="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-primary-content mb-4">
                  {gettext("Unlock Your Full Journey")}
                </h3>
                <p class="text-base sm:text-lg md:text-xl text-primary-content/80 mb-6 max-w-2xl mx-auto">
                  {gettext("Register for free to access exclusive benefits")}
                </p>
                <%!-- Benefits list --%>
                <div class="grid sm:grid-cols-3 gap-4 mb-8 max-w-3xl mx-auto text-left">
                  <div class="bg-black/20 backdrop-blur-sm rounded-xl p-4 border border-white/10">
                    <div class="flex items-center gap-3 mb-2">
                      <div class="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                        <.icon name="hero-academic-cap" class="w-5 h-5 text-primary" />
                      </div>
                      <h4 class="font-semibold text-white">
                        {gettext("Structured Learning")}
                      </h4>
                    </div>
                    <p class="text-sm text-white/80">
                      {gettext("A gradual, step-by-step introduction to Sahaja Yoga meditation")}
                    </p>
                  </div>
                  <div class="bg-black/20 backdrop-blur-sm rounded-xl p-4 border border-white/10">
                    <div class="flex items-center gap-3 mb-2">
                      <div class="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                        <.icon name="hero-book-open" class="w-5 h-5 text-primary" />
                      </div>
                      <h4 class="font-semibold text-white">{gettext("Resources")}</h4>
                    </div>
                    <p class="text-sm text-white/80">
                      {gettext("Access books, meditation photos, and other helpful materials")}
                    </p>
                  </div>
                  <div class="bg-black/20 backdrop-blur-sm rounded-xl p-4 border border-white/10">
                    <div class="flex items-center gap-3 mb-2">
                      <div class="w-10 h-10 rounded-full bg-white flex items-center justify-center">
                        <.icon name="hero-chart-bar" class="w-5 h-5 text-primary" />
                      </div>
                      <h4 class="font-semibold text-white">{gettext("Track Progress")}</h4>
                    </div>
                    <p class="text-sm text-white/80">
                      {gettext("Save your progress and continue where you left off")}
                    </p>
                  </div>
                </div>
                <div class="flex flex-col sm:flex-row gap-4 justify-center">
                  <.link
                    navigate="/users/register"
                    class="px-8 py-4 bg-white text-primary rounded-full font-semibold hover:bg-white/90 transition-all duration-300 inline-flex items-center justify-center gap-2 shadow-lg hover:shadow-xl hover:scale-105"
                  >
                    <.icon name="hero-user-plus" class="w-5 h-5" />
                    {gettext("Register for Free")}
                  </.link>
                  <.link
                    navigate="/talks"
                    class="px-8 py-4 bg-primary-content/20 text-primary-content rounded-full font-semibold hover:bg-primary-content/30 transition-all duration-300 inline-flex items-center justify-center gap-2 border border-primary-content/30"
                  >
                    <.icon name="hero-magnifying-glass" class="w-5 h-5" />
                    {gettext("Browse Talks")}
                  </.link>
                </div>
                <p class="mt-4 text-sm text-primary-content/60">
                  {gettext("Already have an account?")}
                  <.link navigate="/users/log-in" class="underline hover:text-primary-content ml-1">
                    {gettext("Log in")}
                  </.link>
                </p>
              </div>
            <% end %>
          </section>
        </div>
      </div>
    </div>
    """
  end
end
