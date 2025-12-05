defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  import SahajyogWeb.VideoPlayer

  @impl true
  def mount(_params, _session, socket) do
    current_video = Content.get_daily_video()
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    socket =
      socket
      |> assign(:current_video, current_video)
      |> assign(:locale, locale)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <style>
        /* 2025 Modern Typography & Animations */
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;1,400&display=swap');

        .font-display { font-family: 'Inter', system-ui, sans-serif; }
        .font-serif { font-family: 'Playfair Display', Georgia, serif; }

        /* Scroll-triggered animations (hook adds .revealed class) */
        .apple-reveal {
          opacity: 0;
          transform: translateY(60px);
          transition: opacity 1s cubic-bezier(0.16, 1, 0.3, 1),
                      transform 1s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .apple-reveal.revealed {
          opacity: 1;
          transform: translateY(0);
        }

        .apple-scale {
          opacity: 0;
          transform: scale(0.95);
          transition: opacity 1s cubic-bezier(0.16, 1, 0.3, 1),
                      transform 1s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .apple-scale.revealed {
          opacity: 1;
          transform: scale(1);
        }

        /* Stagger delays for children */
        .apple-reveal:nth-child(2) { transition-delay: 0.1s; }
        .apple-reveal:nth-child(3) { transition-delay: 0.2s; }
        .apple-reveal:nth-child(4) { transition-delay: 0.3s; }

        /* Hero animation - triggers on page load */
        .hero-reveal {
          opacity: 0;
          transform: translateY(30px);
          animation: heroReveal 1s cubic-bezier(0.16, 1, 0.3, 1) 0.2s forwards;
        }
        @keyframes heroReveal {
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        /* Gradient text */
        .gradient-text {
          background: linear-gradient(135deg, oklch(var(--p)) 0%, oklch(var(--s)) 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }

        /* Animated gradient background */
        .animated-gradient {
          background: linear-gradient(-45deg,
            oklch(var(--b2)) 0%,
            oklch(var(--b1)) 25%,
            oklch(var(--b2)) 50%,
            oklch(var(--b1)) 75%,
            oklch(var(--b2)) 100%);
          background-size: 400% 400%;
          animation: gradientShift 15s ease infinite;
        }
        @keyframes gradientShift {
          0% { background-position: 0% 50%; }
          50% { background-position: 100% 50%; }
          100% { background-position: 0% 50%; }
        }

        /* Floating animation */
        .float {
          animation: float 6s ease-in-out infinite;
        }
        @keyframes float {
          0%, 100% { transform: translateY(0px); }
          50% { transform: translateY(-20px); }
        }

        /* Line animation */
        .line-grow {
          width: 0;
          transition: width 1s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .line-grow.visible {
          width: 100%;
        }

        /* Smooth hover */
        .hover-lift {
          transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .hover-lift:hover {
          transform: translateY(-4px);
        }

        /* Noise texture overlay */
        .noise::before {
          content: '';
          position: absolute;
          inset: 0;
          background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
          opacity: 0.03;
          pointer-events: none;
        }

        /* Scroll indicator fade out */
        .scroll-indicator {
          opacity: 1;
          transition: opacity 0.5s cubic-bezier(0.16, 1, 0.3, 1);
          display: none;
        }
        @media (min-width: 1024px) {
          .scroll-indicator {
            display: flex;
          }
        }
        .scroll-indicator.hidden {
          opacity: 0;
          pointer-events: none;
        }
      </style>

      <div
        id="welcome-page"
        phx-hook="AppleAnimations"
        class="min-h-screen bg-base-300 text-base-content font-display"
      >
        
    <!-- HERO: Full viewport, minimal, typographic, content-based height -->
        <section class="relative overflow-hidden pt-12 md:pt-20 lg:pt-32 pb-6 md:pb-10 lg:pb-12 flex flex-col justify-center">
          <!-- Animated gradient orbs -->
          <div class="absolute top-1/4 -left-32 w-96 h-96 bg-primary/10 rounded-full blur-[100px] float">
          </div>
          <div
            class="absolute bottom-1/4 -right-32 w-80 h-80 bg-secondary/10 rounded-full blur-[100px] float"
            style="animation-delay: -3s;"
          >
          </div>

          <div class="relative z-10 w-full max-w-7xl mx-auto px-6 lg:px-8">
            <div class="hero-reveal">
              <!-- Eyebrow -->
              <p class="text-xs md:text-sm tracking-[0.3em] uppercase text-base-content/40 mb-2 md:mb-6 font-medium">
                {gettext("Free Meditation")}
              </p>
              
    <!-- Main headline -->
              <h1 class="text-[clamp(2rem,8vw,8rem)] font-bold leading-[0.95] tracking-[-0.03em] mb-3 md:mb-8">
                <span class="block">{gettext("Realize your Self")}</span>
                <span class="block gradient-text">{gettext("inner silence")}</span>
              </h1>
              
    <!-- Subhead -->
              <p class="text-base md:text-xl lg:text-2xl text-base-content/50 max-w-xl leading-relaxed font-light mb-4 md:mb-12">
                {gettext(
                  "Sahaja Yoga is a unique method of meditation that brings mental, physical and emotional balance."
                )}
              </p>
              
    <!-- How It Works -->
              <div class="grid grid-cols-3 gap-1 md:gap-4 lg:gap-8 mt-6 md:mt-16 lg:mt-20">
                <!-- Step 1 -->
                <.link href="#video" class="step-card group cursor-pointer">
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-base-200/30 transition-colors">
                    <div class="step-circle step-circle-1 w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-lg shadow-primary/30">
                      <span class="text-lg md:text-3xl font-bold text-primary-content">1</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-base-content mb-0.5 md:mb-2">
                      {gettext("Learn")}
                    </h3>
                    <p class="text-xs md:text-sm text-base-content/60 leading-relaxed hidden sm:block">
                      {gettext("Watch introductory videos and understand the basics of meditation")}
                    </p>
                  </div>
                </.link>
                
    <!-- Step 2 -->
                <.link navigate={~p"/steps"} class="step-card group cursor-pointer">
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-base-200/30 transition-colors">
                    <div class="step-circle step-circle-2 w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-lg shadow-primary/30">
                      <span class="text-lg md:text-3xl font-bold text-primary-content">2</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-base-content mb-0.5 md:mb-2">
                      {gettext("Practice")}
                    </h3>
                    <p class="text-xs md:text-sm text-base-content/60 leading-relaxed hidden sm:block">
                      {gettext("Follow guided meditations and experience Self Realization")}
                    </p>
                  </div>
                </.link>
                
    <!-- Step 3 -->
                <.link
                  navigate={if assigns[:current_scope], do: ~p"/steps", else: ~p"/users/register"}
                  class="step-card group cursor-pointer"
                >
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-base-200/30 transition-colors">
                    <div class="step-circle step-circle-3 w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-primary to-primary/70 flex items-center justify-center shadow-lg shadow-primary/30">
                      <span class="text-lg md:text-3xl font-bold text-primary-content">3</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-base-content mb-0.5 md:mb-2">
                      {gettext("Experience")}
                    </h3>
                    <p class="text-xs md:text-sm text-base-content/60 leading-relaxed hidden sm:block">
                      {gettext("Feel the peace within and grow through regular practice")}
                    </p>
                  </div>
                </.link>
              </div>
            </div>
          </div>
        </section>
        
    <!-- VIDEO SECTION: Clean, wide -->
        <section
          :if={@current_video}
          id="video"
          class="pt-6 md:pt-10 lg:pt-12 pb-12 md:pb-20 lg:pb-24 relative"
        >
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="apple-reveal">
              <!-- Video container with subtle border -->
              <div class="relative rounded-2xl lg:rounded-3xl overflow-hidden bg-base-200/50 p-1.5">
                <div class="rounded-xl lg:rounded-2xl overflow-hidden aspect-video bg-black">
                  <.video_player
                    video_id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                    provider={:youtube}
                    locale={@locale}
                  />
                </div>
              </div>
              
    <!-- Video info -->
              <div class="mt-6 md:mt-8 flex flex-col md:flex-row md:items-center md:justify-between gap-3 md:gap-0">
                <div>
                  <p class="text-xs tracking-[0.2em] uppercase text-primary font-semibold mb-1">
                    {gettext("Today's Talk")}
                  </p>
                  <h3 class="text-lg font-medium">{@current_video.title}</h3>
                </div>
                <.link
                  href={~p"/talks"}
                  class="text-sm text-base-content/50 hover:text-base-content transition-colors self-start md:self-auto"
                >
                  {gettext("View all")} →
                </.link>
              </div>
            </div>
          </div>
        </section>
        
    <!-- FEATURES: Horizontal scroll or grid -->
        <section class="py-8 md:py-24 lg:py-32 border-t border-base-content/5">
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <!-- Section header -->
            <div class="max-w-2xl mb-6 md:mb-16 lg:mb-20 apple-reveal">
              <p class="text-sm tracking-[0.2em] uppercase text-primary font-semibold mb-4">
                {gettext("The Practice")}
              </p>
              <h2 class="text-4xl md:text-5xl font-bold tracking-tight leading-[1.1] mb-6">
                {gettext("A meditation that works")}
              </h2>
              <p class="text-xl text-base-content/50 leading-relaxed">
                {gettext("Simple techniques that anyone can practice. No experience needed.")}
              </p>
            </div>
            
    <!-- Feature cards - minimal, text-focused -->
            <div class="grid md:grid-cols-3 gap-px bg-base-content/5 rounded-2xl overflow-hidden apple-reveal">
              <!-- Card 1 -->
              <div class="bg-base-100 p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 text-primary mb-8">
                  <.icon name="hero-sparkles" class="w-6 h-6" />
                </span>
                <h3 class="text-xl font-semibold mb-3">{gettext("Self Realization")}</h3>
                <p class="text-base-content/50 leading-relaxed mb-6">
                  {gettext("Awaken your inner energy through a simple 10-minute guided experience.")}
                </p>
                <.link
                  href={~p"/steps"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-primary hover:gap-3 transition-all"
                >
                  {gettext("Try now")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>
              
    <!-- Card 2 -->
              <div class="bg-base-100 p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-secondary/10 text-secondary mb-8">
                  <.icon name="hero-microphone" class="w-6 h-6" />
                </span>
                <h3 class="text-xl font-semibold mb-3">{gettext("Talks & Lectures")}</h3>
                <p class="text-base-content/50 leading-relaxed mb-6">
                  {gettext("Thousands of hours of wisdom from Shri Mataji Nirmala Devi.")}
                </p>
                <.link
                  href={~p"/talks"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-secondary hover:gap-3 transition-all"
                >
                  {gettext("Browse")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>
              
    <!-- Card 3 -->
              <div class="bg-base-100 p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <span class="inline-flex items-center justify-center w-12 h-12 rounded-full bg-accent/10 text-accent mb-8">
                  <.icon name="hero-book-open" class="w-6 h-6" />
                </span>
                <h3 class="text-xl font-semibold mb-3">{gettext("Topics")}</h3>
                <p class="text-base-content/50 leading-relaxed mb-6">
                  {gettext("Explore teachings organized by theme and subject matter.")}
                </p>
                <.link
                  href={~p"/topics"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-accent hover:gap-3 transition-all"
                >
                  {gettext("Explore")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>
            </div>
          </div>
        </section>
        
    <!-- QUOTE: Full-width, dramatic -->
        <section class="py-12 md:py-32 lg:py-40 relative animated-gradient noise">
          <div class="max-w-5xl mx-auto px-6 lg:px-8 text-center relative z-10 apple-scale">
            <blockquote class="font-serif text-2xl md:text-4xl lg:text-5xl xl:text-6xl italic leading-[1.2] text-base-content/90 mb-6 md:mb-10">
              "{gettext(
                "You cannot know the meaning of your life until you are connected to the power that created you."
              )}"
            </blockquote>
            <cite class="text-base-content/40 text-lg not-italic tracking-wide">
              — Shri Mataji Nirmala Devi
            </cite>
          </div>
        </section>
        
    <!-- CTA: Unlock Your Full Journey -->
        <section class="py-12 md:py-32 lg:py-40 border-t border-base-content/5">
          <div class="max-w-5xl mx-auto px-6 lg:px-8 text-center apple-reveal">
            <h2 class="text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold tracking-tight mb-4 md:mb-6 text-base-content">
              {gettext("Unlock Your Full Journey")}
            </h2>
            <p class="text-lg md:text-xl lg:text-2xl text-base-content/50 mb-8 md:mb-12 max-w-2xl mx-auto leading-relaxed">
              {gettext(
                "Register for free to access structured learning, resources, and progress tracking"
              )}
            </p>
            
    <!-- Minimal benefits list -->
            <div class="flex flex-wrap justify-center gap-4 md:gap-6 lg:gap-8 mb-8 md:mb-12 text-sm md:text-base text-base-content/60">
              <div class="flex items-center gap-2">
                <.icon name="hero-academic-cap" class="w-5 h-5 text-primary" />
                <span>{gettext("Structured Learning")}</span>
              </div>
              <div class="flex items-center gap-2">
                <.icon name="hero-book-open" class="w-5 h-5 text-secondary" />
                <span>{gettext("Resources")}</span>
              </div>
              <div class="flex items-center gap-2">
                <.icon name="hero-chart-bar" class="w-5 h-5 text-accent" />
                <span>{gettext("Track Progress")}</span>
              </div>
            </div>
            
    <!-- CTA buttons -->
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <.link
                href={~p"/users/register"}
                class="group inline-flex items-center gap-3 bg-base-content text-base-100 px-8 py-4 rounded-full font-medium hover-lift"
              >
                {gettext("Register for Free")}
                <span class="w-8 h-8 rounded-full bg-base-100/20 flex items-center justify-center group-hover:bg-base-100/30 transition-colors">
                  <.icon name="hero-arrow-right" class="w-4 h-4" />
                </span>
              </.link>
              <.link
                href={~p"/steps"}
                class="text-base-content/60 hover:text-base-content transition-colors font-medium"
              >
                {gettext("Try without account")}
              </.link>
            </div>

            <p class="mt-8 text-sm text-base-content/40">
              {gettext("Sahaja Yoga meditation is always free")}
            </p>
          </div>
        </section>
        
    <!-- Spacer for footer -->
        <div class="h-20"></div>
      </div>
    </Layouts.app>
    """
  end
end
