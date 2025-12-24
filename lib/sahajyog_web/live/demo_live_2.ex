defmodule SahajyogWeb.DemoLive2 do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  alias Sahajyog.VideoProvider
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

    # Hide "Today's Talk" label after 30 seconds
    if connected?(socket), do: Process.send_after(self(), :hide_todays_talk, 30_000)

    socket =
      socket
      |> assign(:page_title, "Welcome")
      |> assign(:current_video, current_video)
      |> assign(:locale, locale)
      |> assign(:show_schedule_info, false)
      |> assign(:show_todays_talk, true)
      |> assign(:shri_mataji_image, shri_mataji_image)
      |> assign(:testimonials, @testimonials)

    {:ok, socket}
  end

  def handle_info(:clear_schedule_info, socket) do
    {:noreply, assign(socket, :show_schedule_info, false)}
  end

  def handle_info(:hide_todays_talk, socket) do
    {:noreply, assign(socket, :show_todays_talk, false)}
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
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap');
      .font-outfit { font-family: 'Outfit', sans-serif; }
    </style>
    <div id="demo2-page" phx-hook="GSAPScrollReveal" class="overflow-x-hidden font-outfit text-lg">
      <%!-- Scroll Progress Bar --%>
      <div id="scroll-progress" class="scroll-progress" style="width: 0%"></div>

      <%!-- Animated gradient background with mesh and noise --%>
      <div class="min-h-screen bg-gradient-to-br from-base-300 via-base-200 to-base-300 animate-gradient mesh-gradient noise-overlay overflow-x-hidden">
        <%!-- Hidden hooks --%>
        <div
          id="daily-update-hook"
          phx-hook="ScheduleNotification"
          data-key="daily_update_seen_v5"
          class="hidden"
        >
        </div>

        <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 pt-3 sm:pt-4 lg:pt-4 pb-6 sm:pb-8 relative z-10">
          <%!-- Hero Section with entrance animations --%>
          <section
            id="hero-section"
            phx-hook="GSAPHero"
            class="text-center mb-3 sm:mb-4 lg:mb-3 2xl:mb-[3vh]"
          >
            <h1 class="hero-element text-2xl sm:text-3xl lg:text-4xl 2xl:text-[3.5rem] font-bold text-base-content mb-2 sm:mb-2 2xl:mb-4 title-elegant tracking-tight">
              <span class="block" phx-hook="GSAPTextReveal" id="hero-text-title-2" phx-update="ignore">
                {gettext("Welcome to Sahaja Yoga")}
              </span>
            </h1>
            <p class="hero-element text-lg sm:text-xl lg:text-2xl text-base-content/70 mb-3 sm:mb-4 2xl:mb-[3vh]">
              {gettext("Discover inner peace through meditation")}
            </p>

            <%!-- Daily update banner --%>
            <div class={[
              "hero-element flex items-center justify-center px-4 transition-all duration-300",
              if(@show_schedule_info, do: "h-10 mb-1 sm:mb-2 lg:mb-1", else: "h-0 overflow-hidden")
            ]}>
              <div
                class={[
                  "w-fit max-w-full sm:max-w-2xl bg-gradient-to-r from-blue-600 to-blue-500 text-white rounded-full px-4 sm:px-6 py-2 sm:py-2.5 flex items-center gap-2 sm:gap-3 shadow-lg shadow-blue-500/20 transition-all duration-300",
                  if(@show_schedule_info,
                    do: "opacity-100 scale-100",
                    else: "opacity-0 scale-95 pointer-events-none"
                  )
                ]}
                role="alert"
              >
                <.icon name="hero-sparkles" class="w-4 h-4 sm:w-5 sm:h-5 shrink-0" />
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

          <%!-- Video Player with Glassmorphism --%>
          <section :if={@current_video} class="mb-16 md:mb-24 lg:mb-32 xl:mb-40">
            <div class="max-w-3xl lg:max-w-2xl xl:max-w-3xl mx-auto">
              <%!-- Today's Talk Label - subtle, fades after 30s --%>
              <div class={[
                "flex items-center justify-start mb-1.5 sm:mb-2 2xl:mb-3 transition-opacity duration-500",
                if(@show_todays_talk, do: "opacity-100", else: "opacity-0")
              ]}>
                <span class="text-primary/70 text-xs 2xl:text-sm font-medium inline-flex items-center gap-1.5">
                  <.icon name="hero-play-circle" class="w-3.5 h-3.5 2xl:w-4 2xl:h-4" />
                  {gettext("Today's Talk")}
                </span>
              </div>

              <div class="glass-card rounded-2xl 2xl:rounded-3xl overflow-hidden">
                <div class="aspect-video bg-black 2xl:max-h-[48vh]">
                  <.video_player
                    video_id={
                      VideoProvider.extract_video_id(
                        @current_video.url,
                        String.to_atom(@current_video.provider)
                      )
                    }
                    provider={String.to_atom(@current_video.provider)}
                    locale={@locale}
                  />
                </div>
                <div class="p-4 sm:p-5 2xl:p-6">
                  <h2 class="text-lg sm:text-xl 2xl:text-2xl font-bold text-base-content break-words tracking-tight">
                    {@current_video.title}
                  </h2>
                </div>
              </div>
            </div>
          </section>
          <%!-- About Sahaja Yoga Section --%>
          <section class="py-16 sm:py-20 gsap-reveal">
            <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-base-content text-center mb-10 sm:mb-12 tracking-tight">
              {gettext("What is Sahaja Yoga?")}
            </h2>

            <div class="grid md:grid-cols-2 gap-10 lg:gap-16 items-center">
              <div>
                <.card class="p-6 sm:p-8">
                  <p class="text-base-content/90 leading-relaxed mb-5 text-lg sm:text-xl">
                    {gettext(
                      "Sahaja Yoga is a form of yoga initiated by Shri Mataji Nirmala Devi on May 5th, 1970. Through her profound meditation, she made the breakthrough that integrated the spiritual and physical dimensions, making Self Realisation accessible to all mankind."
                    )}
                  </p>
                  <p class="text-base-content/90 leading-relaxed mb-5 text-lg sm:text-xl">
                    {gettext(
                      "In Sanskrit, Sahaja (सहज) means 'born with' and Yoga means union. The name translates to 'the union which one is born with' - the union between your true self and the all-pervading power that permeates all elements of life."
                    )}
                  </p>
                  <p class="text-base-content/90 leading-relaxed text-lg sm:text-xl">
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
                  class="rounded-3xl shadow-2xl max-w-md w-full object-cover animate-float"
                />
              </div>
            </div>
          </section>

          <%!-- Chakra System - Alternating background for visual separation --%>
          <section class="py-16 sm:py-20 gsap-reveal bg-base-200/40 -mx-3 sm:-mx-6 lg:-mx-8 px-3 sm:px-6 lg:px-8">
            <div class="max-w-7xl mx-auto">
              <h3 class="text-xl sm:text-2xl lg:text-3xl font-bold text-base-content text-center mb-10 sm:mb-12 tracking-tight">
                {gettext("The Subtle System")}
              </h3>
              <div class="grid md:grid-cols-2 gap-10 lg:gap-16 items-center">
                <div class="flex justify-center order-2 md:order-1">
                  <img
                    src={~p"/images/chakra_system.jpg"}
                    alt={gettext("Chakra System")}
                    class="rounded-2xl shadow-2xl w-full max-w-md hover:scale-105 transition-transform duration-500"
                  />
                </div>
                <div class="order-1 md:order-2">
                  <.card class="p-6 sm:p-8">
                    <p class="text-base-content/90 leading-relaxed mb-5 text-lg sm:text-xl">
                      {gettext(
                        "Sahaja Yoga meditation works directly on the central nervous system that controls all of our mental, physical and emotional activity. It, therefore, has the potential to dramatically improve our wellbeing by going directly to the source of any problem."
                      )}
                    </p>
                    <p class="text-base-content/90 leading-relaxed mb-5 text-lg sm:text-xl">
                      {gettext(
                        "The immediate effects of raising the Kundalini, and going into thoughtless awareness, can be felt as a gentle release from our mind and a spontaneous state of bliss where one merely witnesses and enjoys the present moment."
                      )}
                    </p>
                    <p class="text-base-content/90 leading-relaxed text-lg sm:text-xl">
                      {gettext(
                        "When the Kundalini rises, she removes the tensions occurring on our central nervous system that cause negative mental, emotional, or physical sensations, and brings our system into balance."
                      )}
                    </p>
                  </.card>
                </div>
              </div>
            </div>
          </section>

          <%!-- Quotes from Shri Mataji - Mobile/Tablet (single quote) --%>
          <section class="py-16 sm:py-20 lg:hidden gsap-reveal">
            <h2 class="text-xl sm:text-2xl font-bold text-base-content text-center mb-8 sm:mb-10 tracking-tight">
              {gettext("Quotes from Shri Mataji")}
            </h2>
            <div class="quote-card relative bg-gradient-to-br from-base-200 to-base-300 rounded-3xl p-8 sm:p-10 text-center max-w-lg mx-auto border border-base-content/5 shadow-xl overflow-hidden">
              <%!-- Decorative quote mark --%>
              <div class="absolute -top-2 left-6 text-8xl text-primary/10 font-display select-none leading-none">
                "
              </div>
              <div class="relative z-10">
                <div class="flex justify-center mb-6">
                  <img
                    src={~p"/images/home_img_Quotes_1.png"}
                    alt={gettext("Shri Mataji")}
                    class="w-24 h-24 rounded-full object-cover border-4 border-primary/30 shadow-xl"
                  />
                </div>

                <blockquote class="text-xl sm:text-2xl text-base-content/90 leading-[1.3] mb-6 italic">
                  "{gettext(
                    "Sahaja Yoga is a very subtle happening within us. It's a very subtle happening. And this subtler happening gives you sensitivity to divine joy."
                  )}"
                </blockquote>
                <cite class="text-xs text-base-content/50 not-italic tracking-wide">
                  — 03 January 1988, Ganapatipule, India
                </cite>
              </div>
            </div>
          </section>

          <%!-- Quotes from Shri Mataji - Desktop Carousel --%>
          <section class="py-16 sm:py-20 hidden lg:block gsap-reveal">
            <h2 class="text-3xl lg:text-4xl font-bold text-base-content text-center mb-12 tracking-tight">
              {gettext("Quotes from Shri Mataji")}
            </h2>

            <div
              id="quotes-carousel"
              phx-hook="QuotesCarousel"
              class="relative max-w-4xl mx-auto"
            >
              <div class="overflow-hidden rounded-3xl">
                <div class="carousel-track flex transition-transform duration-700 ease-in-out">
                  <%!-- Quote 1 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="quote-card relative bg-gradient-to-br from-base-200 to-base-300 rounded-3xl p-10 lg:p-12 text-center border border-base-content/5 shadow-xl overflow-hidden">
                      <%!-- Decorative quote marks --%>
                      <div class="absolute -top-4 left-8 text-9xl text-primary/10 font-display select-none leading-none">
                        "
                      </div>
                      <div class="absolute -bottom-16 right-8 text-9xl text-primary/10 font-display select-none leading-none rotate-180">
                        "
                      </div>
                      <div class="relative z-10">
                        <div class="flex justify-center mb-8">
                          <img
                            src={~p"/images/home_img_Quotes_1.png"}
                            alt={gettext("Shri Mataji")}
                            class="w-36 h-36 rounded-full object-cover border-4 border-primary/30 shadow-2xl"
                          />
                        </div>
                        <blockquote class="text-2xl lg:text-3xl xl:text-4xl text-base-content/90 leading-[1.3] max-w-3xl mx-auto mb-8 italic">
                          "{gettext(
                            "Sahaja Yoga is a very subtle happening within us. It's a very subtle happening. And this subtler happening gives you sensitivity to divine joy."
                          )}"
                        </blockquote>
                        <cite class="text-sm text-base-content/50 not-italic tracking-wide">
                          — 03 January 1988, Ganapatipule, India
                        </cite>
                      </div>
                    </div>
                  </div>

                  <%!-- Quote 2 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="quote-card relative bg-gradient-to-br from-base-200 to-base-300 rounded-3xl p-10 lg:p-12 text-center border border-base-content/5 shadow-xl overflow-hidden">
                      <div class="absolute -top-4 left-8 text-9xl text-primary/10 font-display select-none leading-none">
                        "
                      </div>
                      <div class="absolute -bottom-16 right-8 text-9xl text-primary/10 font-display select-none leading-none rotate-180">
                        "
                      </div>
                      <div class="relative z-10">
                        <div class="flex justify-center mb-8">
                          <img
                            src={~p"/images/home_img_Quotes_2.png"}
                            alt={gettext("Shri Mataji")}
                            class="w-36 h-36 rounded-full object-cover border-4 border-secondary/30 shadow-2xl"
                          />
                        </div>
                        <blockquote class="text-2xl lg:text-3xl xl:text-4xl text-base-content/90 leading-[1.3] max-w-3xl mx-auto mb-8 italic">
                          "{gettext(
                            "What is yoga? In simple words, it is taking your attention to the Spirit. This is yoga. What does the Kundalini do? She raises your attention and takes it to the Spirit."
                          )}"
                        </blockquote>
                        <cite class="text-sm text-base-content/50 not-italic tracking-wide">
                          — 10 November 1980, Caxton Hall, UK
                        </cite>
                      </div>
                    </div>
                  </div>

                  <%!-- Quote 3 --%>
                  <div class="carousel-slide min-w-full flex-shrink-0">
                    <div class="quote-card relative bg-gradient-to-br from-base-200 to-base-300 rounded-3xl p-10 lg:p-12 text-center border border-base-content/5 shadow-xl overflow-hidden">
                      <div class="absolute -top-4 left-8 text-9xl text-primary/10 font-display select-none leading-none">
                        "
                      </div>
                      <div class="absolute -bottom-16 right-8 text-9xl text-primary/10 font-display select-none leading-none rotate-180">
                        "
                      </div>
                      <div class="relative z-10">
                        <div class="flex justify-center mb-8">
                          <img
                            src={~p"/images/home_img_Quotes_3.png"}
                            alt={gettext("Shri Mataji")}
                            class="w-36 h-36 rounded-full object-cover border-4 border-accent/30 shadow-2xl"
                          />
                        </div>
                        <blockquote class="text-2xl lg:text-3xl xl:text-4xl text-base-content/90 leading-[1.3] max-w-3xl mx-auto mb-8 italic">
                          "{gettext(
                            "Meditation is the only way you can grow. Because when you meditate, you are in silence, you are in thoughtless awareness. Then the growth of awareness takes place."
                          )}"
                        </blockquote>
                        <cite class="text-sm text-base-content/50 not-italic tracking-wide">
                          — 27 July 1988, Armonk, New York
                        </cite>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Carousel Indicators --%>
              <div class="flex justify-center gap-3 mt-8">
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

          <%!-- Testimonials Section - Alternating background --%>
          <section class="py-16 sm:py-20 gsap-reveal bg-base-200/40 -mx-3 sm:-mx-6 lg:-mx-8 px-3 sm:px-6 lg:px-8">
            <div class="max-w-7xl mx-auto">
              <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-base-content text-center mb-4 tracking-tight">
                {gettext("What Practitioners Say")}
              </h2>

              <p class="text-base-content/70 text-center mb-12 max-w-2xl mx-auto text-xl">
                {gettext("Join thousands of people who have found peace through Sahaja Yoga")}
              </p>

              <div
                id="testimonials-grid"
                phx-hook="GSAPCard3D"
                class="grid md:grid-cols-3 gap-6 lg:gap-8"
              >
                <%= for {testimonial, idx} <- Enum.with_index(@testimonials) do %>
                  <div class="testimonial-card gsap-3d-card bg-gradient-to-br from-base-100 to-base-200 rounded-2xl p-6 sm:p-8 border border-base-content/5 shadow-lg">
                    <div class="flex items-center gap-4 mb-5">
                      <div class="w-14 h-14 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold text-xl">
                        {testimonial.avatar}
                      </div>
                      <div>
                        <p class="font-semibold text-base-content text-lg">{testimonial.name}</p>
                        <p class="text-sm text-base-content/70">{testimonial.location}</p>
                      </div>
                    </div>
                    <p class="text-base-content/90 font-quote text-base leading-relaxed">
                      "{testimonial.text}"
                    </p>
                  </div>
                <% end %>
              </div>
            </div>
          </section>

          <%!-- Statistics Section with animated counters --%>
          <section id="stats-section" class="py-16 sm:py-20 gsap-reveal">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-8">
              <div class="text-center p-6 sm:p-8 bg-gradient-to-br from-primary/10 to-primary/5 rounded-2xl border border-primary/20">
                <div class="text-4xl md:text-5xl lg:text-6xl font-bold text-primary mb-3">
                  <span
                    data-counter="90"
                    phx-hook="GSAPCounter"
                    id="cnt-countries"
                    phx-update="ignore"
                  >0</span>+
                </div>
                <p class="text-base-content/80 font-medium text-sm sm:text-base">
                  {gettext("Countries")}
                </p>
              </div>
              <div class="text-center p-6 sm:p-8 bg-gradient-to-br from-secondary/10 to-secondary/5 rounded-2xl border border-secondary/20">
                <div class="text-4xl md:text-5xl lg:text-6xl font-bold text-secondary mb-3">
                  <span data-counter="55" phx-hook="GSAPCounter" id="cnt-years" phx-update="ignore">0</span>+
                </div>
                <p class="text-base-content/80 font-medium text-sm sm:text-base">
                  {gettext("Years")}
                </p>
              </div>
              <div class="text-center p-6 sm:p-8 bg-gradient-to-br from-success/10 to-success/5 rounded-2xl border border-success/20">
                <div class="text-4xl md:text-5xl lg:text-6xl font-bold text-success mb-3">
                  100%
                </div>
                <p class="text-base-content/80 font-medium text-sm sm:text-base">
                  {gettext("Free Forever")}
                </p>
              </div>
              <div class="text-center p-6 sm:p-8 bg-gradient-to-br from-info/10 to-info/5 rounded-2xl border border-info/20">
                <div class="text-4xl md:text-5xl lg:text-6xl font-bold text-info mb-3">
                  <span data-counter="1000" phx-hook="GSAPCounter" id="cnt-talks" phx-update="ignore">0</span>+
                </div>
                <p class="text-base-content/80 font-medium text-sm sm:text-base">
                  {gettext("Talks Available")}
                </p>
              </div>
            </div>
          </section>

          <%!-- How It Works Section - Alternating background --%>
          <section
            id="how-it-works"
            class="py-16 sm:py-20 gsap-reveal bg-base-200/40 -mx-3 sm:-mx-6 lg:-mx-8 px-3 sm:px-6 lg:px-8"
          >
            <div class="max-w-7xl mx-auto">
              <h2 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-base-content text-center mb-4 tracking-tight">
                {gettext("How It Works")}
              </h2>
              <p class="text-base-content/70 text-center mb-12 max-w-2xl mx-auto text-xl">
                {gettext("Begin your journey to inner peace in three simple steps")}
              </p>

              <div class="grid md:grid-cols-3 gap-8 lg:gap-12">
                <%!-- Step 1 --%>
                <div class="relative step-card disabled-gsap-3d">
                  <div class="text-center p-6 sm:p-8 rounded-2xl hover:bg-base-100/50 transition-colors">
                    <div class="step-circle step-circle-1 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                      <span class="text-4xl font-bold text-primary-content">1</span>
                    </div>
                    <h3 class="text-xl sm:text-2xl font-bold text-base-content mb-4 tracking-tight">
                      {gettext("Learn")}
                    </h3>
                    <p class="text-base-content/80 text-lg sm:text-xl leading-relaxed">
                      {gettext("Watch introductory videos and understand the basics of meditation")}
                    </p>
                  </div>
                  <%!-- Connector line (hidden on mobile) --%>
                  <div class="hidden md:block absolute top-[4.5rem] left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-primary/50 to-transparent">
                  </div>
                </div>

                <%!-- Step 2 --%>
                <div class="relative step-card">
                  <div class="text-center p-6 sm:p-8 rounded-2xl hover:bg-base-100/50 transition-colors">
                    <div class="step-circle step-circle-2 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                      <span class="text-4xl font-bold text-primary-content">2</span>
                    </div>
                    <h3 class="text-xl sm:text-2xl font-bold text-base-content mb-4 tracking-tight">
                      {gettext("Practice")}
                    </h3>
                    <p class="text-base-content/80 text-lg sm:text-xl leading-relaxed">
                      {gettext("Follow guided meditations and experience Self Realization")}
                    </p>
                  </div>
                  <div class="hidden md:block absolute top-[4.5rem] left-[60%] w-[80%] h-0.5 bg-gradient-to-r from-primary/50 to-transparent">
                  </div>
                </div>

                <%!-- Step 3 --%>
                <div class="step-card">
                  <div class="text-center p-6 sm:p-8 rounded-2xl hover:bg-base-100/50 transition-colors">
                    <div class="step-circle step-circle-3 w-24 h-24 mx-auto mb-6 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-xl shadow-primary/40">
                      <span class="text-4xl font-bold text-primary-content">3</span>
                    </div>
                    <h3 class="text-xl sm:text-2xl font-bold text-base-content mb-4 tracking-tight">
                      {gettext("Experience")}
                    </h3>
                    <p class="text-base-content/80 text-lg sm:text-xl leading-relaxed">
                      {gettext("Feel the peace within and grow through regular practice")}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <%!-- Call to Action --%>
          <section class="py-16 sm:py-20 gsap-reveal">
            <%= if @current_scope do %>
              <%!-- Authenticated user CTA --%>
              <div class="bg-gradient-to-r from-primary to-secondary rounded-2xl p-8 md:p-12 text-center animate-gradient animate-gradient-cta">
                <h3
                  class="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-primary-content mb-4"
                  style="position: relative; z-index: 1;"
                >
                  {gettext("Ready to Begin Your Journey?")}
                </h3>
                <p
                  class="text-base sm:text-lg md:text-xl text-primary-content/80 mb-8 max-w-2xl mx-auto"
                  style="position: relative; z-index: 1;"
                >
                  {gettext("Explore our complete collection of talks and guided meditations")}
                </p>
                <div
                  class="flex flex-col sm:flex-row gap-4 justify-center"
                  style="position: relative; z-index: 1;"
                >
                  <.link
                    navigate="/steps"
                    phx-hook="GSAPMagnetic"
                    id="demo2-start-btn"
                    class="magnetic-btn px-8 py-4 bg-white text-primary rounded-full font-semibold hover:bg-white/90 transition-all duration-300 inline-flex items-center justify-center gap-2 shadow-lg hover:shadow-xl hover:scale-105"
                  >
                    <.icon name="hero-play-circle" class="w-5 h-5" />
                    {gettext("Start Learning")}
                  </.link>
                  <.link
                    navigate="/talks"
                    phx-hook="GSAPMagnetic"
                    id="demo2-browse-btn"
                    class="magnetic-btn px-8 py-4 bg-black/20 text-white rounded-full font-semibold hover:bg-black/30 transition-all duration-300 inline-flex items-center justify-center gap-2 border border-white/30"
                  >
                    <.icon name="hero-magnifying-glass" class="w-5 h-5" />
                    {gettext("Browse All Talks")}
                  </.link>
                  <.link
                    navigate="/topics"
                    phx-hook="GSAPMagnetic"
                    id="demo2-explore-btn"
                    class="magnetic-btn px-8 py-4 bg-secondary/80 text-secondary-content rounded-full font-semibold hover:bg-secondary/70 transition-all duration-300 inline-flex items-center justify-center gap-2"
                  >
                    <.icon name="hero-document-text" class="w-5 h-5" />
                    {gettext("Explore Topics")}
                  </.link>
                </div>
              </div>
            <% else %>
              <%!-- Unauthenticated user CTA - encourage registration --%>
              <div class="bg-gradient-to-r from-primary to-secondary rounded-2xl p-8 md:p-12 text-center animate-gradient animate-gradient-cta">
                <h3
                  class="text-xl sm:text-2xl md:text-3xl lg:text-4xl font-bold text-primary-content mb-4"
                  style="position: relative; z-index: 1;"
                >
                  {gettext("Unlock Your Full Journey")}
                </h3>
                <p
                  class="text-base sm:text-lg md:text-xl text-primary-content/80 mb-6 max-w-2xl mx-auto"
                  style="position: relative; z-index: 1;"
                >
                  {gettext("Register for free to access exclusive benefits")}
                </p>
                <%!-- Benefits list --%>
                <div
                  class="grid sm:grid-cols-3 gap-4 mb-8 max-w-3xl mx-auto text-left"
                  style="position: relative; z-index: 1;"
                >
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
                <div
                  class="flex flex-col sm:flex-row gap-4 justify-center"
                  style="position: relative; z-index: 1;"
                >
                  <.link
                    navigate="/users/register"
                    phx-hook="GSAPMagnetic"
                    id="demo2-register-btn"
                    class="magnetic-btn px-8 py-4 bg-white text-primary rounded-full font-semibold hover:bg-white/90 transition-all duration-300 inline-flex items-center justify-center gap-2 shadow-lg hover:shadow-xl hover:scale-105"
                  >
                    <.icon name="hero-user-plus" class="w-5 h-5" />
                    {gettext("Register for Free")}
                  </.link>
                  <.link
                    navigate="/talks"
                    phx-hook="GSAPMagnetic"
                    id="demo2-browse-anon-btn"
                    class="magnetic-btn px-8 py-4 bg-black/20 text-white rounded-full font-semibold hover:bg-black/30 transition-all duration-300 inline-flex items-center justify-center gap-2 border border-white/30"
                  >
                    <.icon name="hero-magnifying-glass" class="w-5 h-5" />
                    {gettext("Browse Talks")}
                  </.link>
                </div>
                <p
                  class="mt-4 text-sm text-white/90"
                  style="position: relative; z-index: 1;"
                >
                  {gettext("Already have an account?")}
                  <.link
                    navigate="/users/log-in"
                    class="underline hover:text-white font-semibold ml-1"
                  >
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
