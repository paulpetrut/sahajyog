defmodule SahajyogWeb.Demo3Live do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  alias Sahajyog.Events
  alias Sahajyog.Topics
  import SahajyogWeb.VideoPlayer

  @impl true
  def mount(_params, _session, socket) do
    current_video = Content.get_daily_video()
    locale = Gettext.get_locale(SahajyogWeb.Gettext)

    socket =
      socket
      |> assign(:current_video, current_video)
      |> assign(
        :featured_events,
        Events.list_publicly_accessible_events() |> Enum.take(3)
      )
      |> assign(
        :featured_topics,
        Topics.list_publicly_accessible_topics() |> Enum.take(3)
      )
      |> assign(:locale, locale)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={assigns[:current_scope]}>
      <style>
        /* Christmas Theme Typography & Animations */
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;1,400&family=Mountains+of+Christmas:wght@400;700&display=swap');

        .font-display { font-family: 'Inter', system-ui, sans-serif; }
        .font-serif { font-family: 'Playfair Display', Georgia, serif; }
        .font-christmas { font-family: 'Mountains of Christmas', cursive; }

        /* Christmas Colors */
        :root {
          --christmas-red: #c41e3a;
          --christmas-green: #165b33;
          --christmas-gold: #f5b041;
          --christmas-snow: #f0f8ff;
          --christmas-pine: #0b3d0b;
        }

        /* Snowfall Animation */
        .snowfall {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          pointer-events: none;
          z-index: 100;
          overflow: hidden;
          animation: fadeOutSnowfall 1s ease-out 30s forwards;
        }

        @keyframes fadeOutSnowfall {
          0% {
            opacity: 1;
            pointer-events: none;
          }
          100% {
            opacity: 0;
            pointer-events: none;
          }
        }

        .snowflake {
          position: absolute;
          top: -10px;
          color: white;
          font-size: 1rem;
          text-shadow: 0 0 5px rgba(255,255,255,0.8);
          animation: fall linear infinite;
          opacity: 0.8;
        }

        @keyframes fall {
          0% {
            transform: translateY(-10px) rotate(0deg);
            opacity: 1;
          }
          100% {
            transform: translateY(100vh) rotate(360deg);
            opacity: 0.3;
          }
        }

        /* Generate snowflakes with different positions and speeds */
        .snowflake:nth-child(1) { left: 5%; animation-duration: 10s; animation-delay: 0s; font-size: 0.8rem; }
        .snowflake:nth-child(2) { left: 10%; animation-duration: 12s; animation-delay: 1s; font-size: 1.2rem; }
        .snowflake:nth-child(3) { left: 15%; animation-duration: 8s; animation-delay: 2s; font-size: 0.6rem; }
        .snowflake:nth-child(4) { left: 20%; animation-duration: 14s; animation-delay: 0.5s; font-size: 1rem; }
        .snowflake:nth-child(5) { left: 25%; animation-duration: 9s; animation-delay: 3s; font-size: 0.9rem; }
        .snowflake:nth-child(6) { left: 30%; animation-duration: 11s; animation-delay: 1.5s; font-size: 1.1rem; }
        .snowflake:nth-child(7) { left: 35%; animation-duration: 13s; animation-delay: 2.5s; font-size: 0.7rem; }
        .snowflake:nth-child(8) { left: 40%; animation-duration: 10s; animation-delay: 4s; font-size: 1.3rem; }
        .snowflake:nth-child(9) { left: 45%; animation-duration: 15s; animation-delay: 0.8s; font-size: 0.8rem; }
        .snowflake:nth-child(10) { left: 50%; animation-duration: 9s; animation-delay: 3.5s; font-size: 1rem; }
        .snowflake:nth-child(11) { left: 55%; animation-duration: 12s; animation-delay: 1.2s; font-size: 1.2rem; }
        .snowflake:nth-child(12) { left: 60%; animation-duration: 8s; animation-delay: 2.8s; font-size: 0.6rem; }
        .snowflake:nth-child(13) { left: 65%; animation-duration: 14s; animation-delay: 4.5s; font-size: 0.9rem; }
        .snowflake:nth-child(14) { left: 70%; animation-duration: 11s; animation-delay: 0.3s; font-size: 1.1rem; }
        .snowflake:nth-child(15) { left: 75%; animation-duration: 10s; animation-delay: 2.2s; font-size: 0.7rem; }
        .snowflake:nth-child(16) { left: 80%; animation-duration: 13s; animation-delay: 3.8s; font-size: 1.4rem; }
        .snowflake:nth-child(17) { left: 85%; animation-duration: 9s; animation-delay: 1.8s; font-size: 0.8rem; }
        .snowflake:nth-child(18) { left: 90%; animation-duration: 12s; animation-delay: 4.2s; font-size: 1rem; }
        .snowflake:nth-child(19) { left: 95%; animation-duration: 11s; animation-delay: 0.6s; font-size: 0.9rem; }
        .snowflake:nth-child(20) { left: 3%; animation-duration: 14s; animation-delay: 2.6s; font-size: 1.2rem; }

        /* Scroll-triggered animations */
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

        /* Hero animation */
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

        /* Christmas gradient text */
        .christmas-gradient-text {
          background: linear-gradient(135deg, var(--christmas-red) 0%, var(--christmas-gold) 50%, var(--christmas-green) 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }

        /* Gold shimmer text */
        .gold-shimmer {
          background: linear-gradient(90deg, var(--christmas-gold), #fff8dc, var(--christmas-gold));
          background-size: 200% auto;
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
          animation: shimmer 3s linear infinite;
        }

        @keyframes shimmer {
          0% { background-position: -200% center; }
          100% { background-position: 200% center; }
        }

        /* Christmas animated gradient background */
        .christmas-gradient {
          background: linear-gradient(-45deg,
            #0a1f0a 0%,
            #1a3a1a 25%,
            #0f2f0f 50%,
            #1a3a1a 75%,
            #0a1f0a 100%);
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

        /* Ornament swing animation */
        .ornament-swing {
          animation: swing 3s ease-in-out infinite;
          transform-origin: top center;
        }
        @keyframes swing {
          0%, 100% { transform: rotate(-3deg); }
          50% { transform: rotate(3deg); }
        }

        /* Twinkling lights */
        .twinkle {
          animation: twinkle 1.5s ease-in-out infinite alternate;
        }
        @keyframes twinkle {
          0% { opacity: 0.4; transform: scale(0.9); }
          100% { opacity: 1; transform: scale(1.1); }
        }

        /* Smooth hover */
        .hover-lift {
          transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }
        .hover-lift:hover {
          transform: translateY(-4px);
        }

        /* Christmas card glow */
        .christmas-card {
          position: relative;
          overflow: hidden;
        }
        .christmas-card::before {
          content: '';
          position: absolute;
          top: -50%;
          left: -50%;
          width: 200%;
          height: 200%;
          background: radial-gradient(circle, rgba(245,176,65,0.1) 0%, transparent 50%);
          animation: rotate 20s linear infinite;
        }
        @keyframes rotate {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }

        /* Candy cane border - 3D Tube Effect */
        .candy-cane-border {
          border: 4px solid #0b3d0b; /* Pine Green rim */
          border-radius: 20px;
          background:
            /* Highlights for 3D tube effect */
            linear-gradient(90deg, rgba(255,255,255,0.6) 0%, rgba(255,255,255,0) 30%, rgba(0,0,0,0.1) 80%, rgba(0,0,0,0.3) 100%) padding-box,
            /* The stripes */
            repeating-linear-gradient(
              45deg,
              var(--christmas-red) 0px,
              var(--christmas-red) 15px,
              #ffffff 15px,
              #ffffff 30px
            ) border-box;
          box-shadow:
            0 10px 20px -5px rgba(0,0,0,0.5), /* Drop shadow */
            inset 0 0 10px rgba(0,0,0,0.5); /* Inner depth */
        }

        /* Realistic Christmas Light Bulbs */
        .light-wire {
          display: flex;
          justify-content: center;
          gap: 40px;
          padding: 10px 0;
          position: fixed;
          top: -10px;
          left: 0;
          right: 0;
          z-index: 50;
          pointer-events: none;
          /* The wire itself */
          border-top: 2px solid #2f4f4f;
          border-radius: 50%;
        }

        .christmas-bulb {
          width: 24px;
          height: 36px;
          border-radius: 50% 50% 40% 40%;
          position: relative;
          z-index: 1;
          margin-top: 5px; /* Hang from wire */
          /* Socket */
          border-top: 6px solid #222;
        }

        /* Bulb Glow Animation */
        @keyframes bulb-glow {
          0%, 100% { opacity: 1; box-shadow: 0 0 15px currentColor; }
          50% { opacity: 0.5; box-shadow: 0 0 5px currentColor; }
        }

        .bulb-red {
          background-color: var(--christmas-red);
          color: var(--christmas-red);
          animation: bulb-glow 2s infinite alternate;
        }
        .bulb-green {
          background-color: var(--christmas-green);
          color: var(--christmas-green);
          background-image: radial-gradient(circle at 30% 30%, #8fbc8f, transparent); /* Shine */
          animation: bulb-glow 2.5s infinite alternate 0.5s;
        }
        .bulb-gold {
          background-color: var(--christmas-gold);
          color: var(--christmas-gold);
          background-image: radial-gradient(circle at 30% 30%, #fffacd, transparent);
          animation: bulb-glow 3s infinite alternate 1s;
        }
        .bulb-blue {
          background-color: #1e90ff;
          color: #1e90ff;
          background-image: radial-gradient(circle at 30% 30%, #e0ffff, transparent);
          animation: bulb-glow 2.2s infinite alternate 0.8s;
        }

        /* Text enhancements */
        .text-glow {
          text-shadow: 0 2px 4px rgba(0,0,0,0.5);
        }

        /* Holly decoration */
        .holly::after {
          content: '🍃';
          position: absolute;
          top: -10px;
          right: -10px;
          font-size: 1.5rem;
        }

        /* Christmas Tree Background */
        .christmas-tree {
          position: absolute;
          bottom: 0;
          right: 5%;
          width: 450px;
          height: 600px;
          opacity: 0.5; /* Increased visibility per expert advice */
          pointer-events: none;
          transition: opacity 0.8s ease-out;
          filter: drop-shadow(0 0 15px rgba(255, 215, 0, 0.4)); /* Golden glow */
          z-index: 0;
        }

        @media (max-width: 768px) {
          .christmas-tree {
            width: 200px;
            height: 300px;
            right: 5%;
          }
        }

        /* Scroll indicator */
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
      
    <!-- Snowfall Effect -->
      <div class="snowfall" id="snowfall-container" phx-hook="SnowfallStop">
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
        <div class="snowflake">❆</div>
        <div class="snowflake">❄</div>
        <div class="snowflake">❅</div>
      </div>

      <div
        id="christmas-demo-page"
        phx-hook="AppleAnimations"
        class="min-h-screen christmas-gradient text-white font-display"
      >
        <!-- Christmas Lights Banner (CSS Implementation) -->
        <div class="light-wire">
          <div class="christmas-bulb bulb-red"></div>
          <div class="christmas-bulb bulb-green"></div>
          <div class="christmas-bulb bulb-gold"></div>
          <div class="christmas-bulb bulb-blue"></div>
          <div class="christmas-bulb bulb-red"></div>
          <div class="christmas-bulb bulb-green"></div>
          <div class="christmas-bulb bulb-gold"></div>
          <div class="christmas-bulb bulb-blue hidden sm:block"></div>
          <div class="christmas-bulb bulb-red hidden sm:block"></div>
          <div class="christmas-bulb bulb-green hidden sm:block"></div>
          <div class="christmas-bulb bulb-gold hidden md:block"></div>
          <div class="christmas-bulb bulb-blue hidden md:block"></div>
          <div class="christmas-bulb bulb-red hidden lg:block"></div>
          <div class="christmas-bulb bulb-green hidden lg:block"></div>
          <div class="christmas-bulb bulb-gold hidden xl:block"></div>
        </div>
        
    <!-- HERO: Christmas themed -->
        <section class="relative overflow-hidden pt-16 md:pt-24 lg:pt-36 pb-6 md:pb-10 lg:pb-12 flex flex-col justify-center">
          <!-- Christmas Tree Background -->
          <svg
            class="christmas-tree"
            viewBox="0 0 200 300"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <!-- Tree trunk -->
            <rect x="85" y="240" width="30" height="60" fill="#4a2511" />
            
    <!-- Unified Tree Silhouette (Single Object) -->
            <path
              d="M100 20
                 L130 80 L115 80
                 L155 140 L135 140
                 L185 240 L15 240
                 L65 140 L45 140
                 L85 80 L70 80
                 Z"
              fill="#165b33"
              stroke="#1a472a"
              stroke-width="2"
              stroke-linejoin="round"
            />
            
    <!-- Star on top -->
            <polygon
              points="100,5 105,18 118,18 108,26 112,39 100,31 88,39 92,26 82,18 95,18"
              fill="#f5b041"
            />
            <!-- Ornaments -->
            <circle cx="70" cy="110" r="4" fill="#c41e3a" class="twinkle" />
            <circle
              cx="130"
              cy="115"
              r="4"
              fill="#f5b041"
              class="twinkle"
              style="animation-delay: 0.5s;"
            />
            <circle
              cx="60"
              cy="160"
              r="4"
              fill="#f5b041"
              class="twinkle"
              style="animation-delay: 1s;"
            />
            <circle
              cx="140"
              cy="165"
              r="4"
              fill="#c41e3a"
              class="twinkle"
              style="animation-delay: 1.5s;"
            />
            <circle
              cx="50"
              cy="210"
              r="4"
              fill="#c41e3a"
              class="twinkle"
              style="animation-delay: 0.8s;"
            />
            <circle
              cx="150"
              cy="215"
              r="4"
              fill="#f5b041"
              class="twinkle"
              style="animation-delay: 1.2s;"
            />
          </svg>
          
    <!-- Animated Christmas orbs -->
          <div class="absolute top-1/4 -left-32 w-96 h-96 bg-red-500/20 rounded-full blur-[100px] float">
          </div>
          <div
            class="absolute bottom-1/4 -right-32 w-80 h-80 bg-green-500/20 rounded-full blur-[100px] float"
            style="animation-delay: -3s;"
          >
          </div>
          <div
            class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-yellow-500/10 rounded-full blur-[80px] float"
            style="animation-delay: -1.5s;"
          >
          </div>

          <div class="relative z-10 w-full max-w-7xl mx-auto px-6 lg:px-8">
            <div class="hero-reveal">
              <!-- Christmas Eyebrow -->
              <p class="text-xs md:text-sm tracking-[0.3em] uppercase text-yellow-400/80 mb-2 md:mb-6 font-medium flex items-center gap-2">
                <span class="ornament-swing inline-block">🎄</span>
                {gettext("Free Meditation")}
                <span class="ornament-swing inline-block" style="animation-delay: -1.5s;">🎄</span>
              </p>
              
    <!-- Main headline with Christmas styling -->
              <h1 class="text-[clamp(2rem,8vw,8rem)] font-bold leading-[0.95] tracking-[-0.03em] mb-3 md:mb-8 font-christmas">
                <span class="block text-white drop-shadow-lg">{gettext("Realize your Self")}</span>
                <span class="block christmas-gradient-text">{gettext("inner silence")}</span>
              </h1>
              
    <!-- Christmas decorations around subhead -->
              <div class="relative">
                <span class="absolute -left-8 top-0 text-3xl ornament-swing hidden md:inline">🎁</span>
                <p class="text-base md:text-xl lg:text-2xl text-white/70 max-w-xl leading-relaxed font-light mb-4 md:mb-12">
                  {gettext(
                    "Sahaja Yoga is a unique method of meditation that brings mental, physical and emotional balance."
                  )}
                </p>
                <span
                  class="absolute -right-8 bottom-0 text-3xl ornament-swing hidden md:inline"
                  style="animation-delay: -1s;"
                >
                  ⭐
                </span>
              </div>
              
    <!-- How It Works - Christmas themed steps -->
              <div class="grid grid-cols-3 gap-1 md:gap-4 lg:gap-8 mt-6 md:mt-16 lg:mt-20">
                <!-- Step 1 -->
                <.link href="#video" class="step-card group cursor-pointer">
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-white/5 transition-colors">
                    <div class="relative w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-red-600 to-red-800 flex items-center justify-center shadow-lg shadow-red-500/30 ornament-swing">
                      <span class="text-lg md:text-3xl font-bold text-white">1</span>
                      <span class="absolute -top-2 left-1/2 -translate-x-1/2 text-xs">🎀</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-white mb-0.5 md:mb-2">
                      {gettext("Learn")}
                    </h3>
                    <p class="text-xs md:text-sm text-white/60 leading-relaxed hidden sm:block">
                      {gettext("Watch introductory videos and understand the basics of meditation")}
                    </p>
                  </div>
                </.link>
                
    <!-- Step 2 -->
                <.link navigate={~p"/steps"} class="step-card group cursor-pointer">
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-white/5 transition-colors">
                    <div
                      class="relative w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-green-600 to-green-800 flex items-center justify-center shadow-lg shadow-green-500/30 ornament-swing"
                      style="animation-delay: -1s;"
                    >
                      <span class="text-lg md:text-3xl font-bold text-white">2</span>
                      <span class="absolute -top-2 left-1/2 -translate-x-1/2 text-xs">🎀</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-white mb-0.5 md:mb-2">
                      {gettext("Practice")}
                    </h3>
                    <p class="text-xs md:text-sm text-white/60 leading-relaxed hidden sm:block">
                      {gettext("Follow guided meditations and experience Self Realization")}
                    </p>
                  </div>
                </.link>
                
    <!-- Step 3 -->
                <.link
                  navigate={if assigns[:current_scope], do: ~p"/steps", else: ~p"/users/register"}
                  class="step-card group cursor-pointer"
                >
                  <div class="text-center p-2 md:p-6 rounded-xl hover:bg-white/5 transition-colors">
                    <div
                      class="relative w-12 h-12 md:w-20 md:h-20 mx-auto mb-2 md:mb-4 rounded-full bg-gradient-to-br from-yellow-500 to-yellow-700 flex items-center justify-center shadow-lg shadow-yellow-500/30 ornament-swing"
                      style="animation-delay: -2s;"
                    >
                      <span class="text-lg md:text-3xl font-bold text-white">3</span>
                      <span class="absolute -top-2 left-1/2 -translate-x-1/2 text-xs">⭐</span>
                    </div>
                    <h3 class="text-xs md:text-lg font-bold text-white mb-0.5 md:mb-2">
                      {gettext("Experience")}
                      <%= if !assigns[:current_scope] do %>
                        <span class="text-[0.6em] md:text-[0.65em] text-white/50 font-normal">
                          ({gettext("Login Required")})
                        </span>
                      <% end %>
                    </h3>
                    <p class="text-xs md:text-sm text-white/60 leading-relaxed hidden sm:block">
                      {gettext("Feel the peace within and grow through regular practice")}
                    </p>
                  </div>
                </.link>
              </div>
            </div>
          </div>
        </section>
        
    <!-- VIDEO SECTION -->
        <section
          :if={@current_video}
          id="video"
          class="pt-6 md:pt-10 lg:pt-12 pb-12 md:pb-20 lg:pb-24 relative"
        >
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="apple-reveal">
              <!-- Video container with Christmas border -->
              <div class="relative rounded-2xl lg:rounded-3xl overflow-hidden candy-cane-border p-4 bg-white/10 backdrop-blur-sm">
                <div class="rounded-xl lg:rounded-2xl overflow-hidden aspect-video bg-black">
                  <.video_player
                    video_id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                    provider={:youtube}
                    locale={@locale}
                  />
                </div>
                <!-- Corner decorations -->
                <span class="absolute -top-3 -left-3 text-3xl ornament-swing">🎄</span>
                <span
                  class="absolute -top-3 -right-3 text-3xl ornament-swing"
                  style="animation-delay: -1s;"
                >
                  🎄
                </span>
              </div>
              
    <!-- Video info -->
              <div class="mt-6 md:mt-8 flex flex-col md:flex-row md:items-center md:justify-between gap-3 md:gap-0">
                <div>
                  <p class="text-xs tracking-[0.2em] uppercase text-yellow-400 font-semibold mb-1 flex items-center gap-2">
                    <span>🎁</span> {gettext("Today's Talk")}
                  </p>
                  <h3 class="text-lg font-medium text-white">{@current_video.title}</h3>
                </div>
                <.link
                  navigate={~p"/talks"}
                  class="text-sm text-white/50 hover:text-white transition-colors self-start md:self-auto"
                >
                  {gettext("View all")} →
                </.link>
              </div>
            </div>
          </div>
        </section>
        
    <!-- FEATURES: Christmas themed cards with Snowdrift Top -->
        <section class="relative py-8 md:py-24 lg:py-32 border-t border-white/10">
          <!-- Snowdrift Divider -->
          <div class="absolute top-0 left-0 w-full overflow-hidden leading-none z-10 -translate-y-[1px]">
            <svg
              data-name="Layer 1"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 1200 120"
              preserveAspectRatio="none"
              class="relative block w-full h-[40px] md:h-[60px] fill-white/10"
            >
              <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z">
              </path>
            </svg>
          </div>

          <div class="max-w-7xl mx-auto px-6 lg:px-8 relative z-20">
            <!-- Section header -->
            <div class="max-w-2xl mb-6 md:mb-16 lg:mb-20 apple-reveal">
              <p class="text-sm tracking-[0.2em] uppercase text-red-400 font-semibold mb-4 flex items-center gap-2">
                <span class="twinkle">
                  <!-- SVG Holly Icon -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-5 h-5 fill-current"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
                  </svg>
                </span>
                {gettext("The Practice")}
                <span class="twinkle" style="animation-delay: 0.5s;">
                  <!-- SVG Holly Icon -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-5 h-5 fill-current"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
                  </svg>
                </span>
              </p>
              <h2 class="text-4xl md:text-5xl font-bold tracking-tight leading-[1.1] mb-6 font-christmas text-white">
                {gettext("A meditation that works")}
              </h2>
              <p class="text-xl text-white/60 leading-relaxed">
                {gettext("Simple techniques that anyone can practice. No experience needed.")}
              </p>
            </div>
            
    <!-- Feature cards -->
            <div class="grid md:grid-cols-3 gap-4 apple-reveal">
              <!-- Card 1 -->
              <div class="christmas-card bg-gradient-to-br from-red-900/50 to-red-950/50 backdrop-blur-sm p-6 md:p-10 lg:p-12 rounded-2xl border border-red-500/20 group hover:border-red-500/40 transition-all hover:-translate-y-1">
                <div class="relative z-10">
                  <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                    <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-red-500/20 text-red-400 md:mb-8 shrink-0">
                      <.icon name="hero-sparkles" class="w-5 h-5 md:w-6 md:h-6" />
                    </span>
                    <h3 class="text-lg md:text-xl font-semibold md:mb-3 text-white">
                      {gettext("Self Realization")}
                    </h3>
                  </div>
                  <p class="text-sm md:text-base text-white/60 leading-relaxed mb-4 md:mb-6">
                    {gettext("Awaken your inner energy through a simple 10-minute guided experience.")}
                  </p>
                  <.link
                    navigate={~p"/steps"}
                    class="inline-flex items-center gap-2 text-sm font-medium text-red-400 hover:gap-3 transition-all"
                  >
                    {gettext("Try now")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                  </.link>
                </div>
              </div>
              
    <!-- Card 2 -->
              <div class="christmas-card bg-gradient-to-br from-green-900/50 to-green-950/50 backdrop-blur-sm p-6 md:p-10 lg:p-12 rounded-2xl border border-green-500/20 group hover:border-green-500/40 transition-all hover:-translate-y-1">
                <div class="relative z-10">
                  <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                    <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-green-500/20 text-green-400 md:mb-8 shrink-0">
                      <.icon name="hero-microphone" class="w-5 h-5 md:w-6 md:h-6" />
                    </span>
                    <h3 class="text-lg md:text-xl font-semibold md:mb-3 text-white">
                      {gettext("Talks & Lectures")}
                    </h3>
                  </div>
                  <p class="text-sm md:text-base text-white/60 leading-relaxed mb-4 md:mb-6">
                    {gettext("Thousands of hours of wisdom from Shri Mataji Nirmala Devi.")}
                  </p>
                  <.link
                    navigate={~p"/talks"}
                    class="inline-flex items-center gap-2 text-sm font-medium text-green-400 hover:gap-3 transition-all"
                  >
                    {gettext("Browse")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                  </.link>
                </div>
              </div>
              
    <!-- Card 3 -->
              <div class="christmas-card bg-gradient-to-br from-yellow-900/50 to-yellow-950/50 backdrop-blur-sm p-6 md:p-10 lg:p-12 rounded-2xl border border-yellow-500/20 group hover:border-yellow-500/40 transition-all hover:-translate-y-1">
                <div class="relative z-10">
                  <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                    <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-yellow-500/20 text-yellow-400 md:mb-8 shrink-0">
                      <.icon name="hero-book-open" class="w-5 h-5 md:w-6 md:h-6" />
                    </span>
                    <h3 class="text-lg md:text-xl font-semibold md:mb-3 text-white">
                      {gettext("Topics")}
                    </h3>
                  </div>
                  <p class="text-sm md:text-base text-white/60 leading-relaxed mb-4 md:mb-6">
                    {gettext("Explore teachings organized by theme and subject matter.")}
                  </p>
                  <.link
                    navigate={~p"/topics"}
                    class="inline-flex items-center gap-2 text-sm font-medium text-yellow-400 hover:gap-3 transition-all"
                  >
                    {gettext("Explore (Login Required)")}
                    <.icon name="hero-arrow-right" class="w-4 h-4" />
                  </.link>
                </div>
              </div>
            </div>
          </div>
        </section>
        
    <!-- TOPICS SECTION with Snowdrift -->
        <section
          :if={@featured_topics != []}
          class="relative py-12 md:py-24 border-t border-white/10 bg-black/20"
        >
          <!-- Snowdrift Divider -->
          <div class="absolute top-0 left-0 w-full overflow-hidden leading-none z-10 -translate-y-[1px]">
            <svg
              data-name="Layer 1"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 1200 120"
              preserveAspectRatio="none"
              class="relative block w-full h-[40px] md:h-[60px] fill-white/10"
            >
              <path
                d="M985.66,92.83C906.67,72,823.78,31,743.84,14.19c-82.26-17.34-168.06-16.33-250.45.39-57.84,11.73-114,31.07-172,41.86A600.21,600.21,0,0,1,0,27.35V120H1200V95.8C1132.19,118.92,1055.71,111.31,985.66,92.83Z"
                class="shape-fill"
              >
              </path>
            </svg>
          </div>

          <div class="max-w-7xl mx-auto px-6 lg:px-8 relative z-20 pt-10">
            <div class="mb-12 md:mb-16 apple-reveal">
              <p class="text-sm tracking-[0.2em] uppercase text-green-400 font-semibold mb-4 flex items-center gap-2">
                <span>
                  <!-- SVG Tree Icon -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-5 h-5 fill-current"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2L2 22h20L12 2zm0 3.5L18.5 19H5.5L12 5.5z" />
                  </svg>
                </span>
                {gettext("Knowledge")}
                <span>
                  <!-- SVG Tree Icon -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="w-5 h-5 fill-current"
                    viewBox="0 0 24 24"
                  >
                    <path d="M12 2L2 22h20L12 2zm0 3.5L18.5 19H5.5L12 5.5z" />
                  </svg>
                </span>
              </p>
              <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold tracking-tight leading-[1.1] mb-4 font-christmas text-white">
                {gettext("Featured Topics")}
              </h2>
              <p class="text-lg text-white/60">
                {gettext("These topics are generally available to everyone.")}
              </p>
            </div>

            <div class="grid md:grid-cols-3 gap-6 apple-reveal">
              <%= for topic <- @featured_topics do %>
                <.link
                  navigate={~p"/public/topics/#{topic.slug}"}
                  class="group relative bg-gradient-to-br from-green-900/30 to-green-950/30 backdrop-blur-sm rounded-2xl p-6 lg:p-8 hover:from-green-900/50 hover:to-green-950/50 transition-all border border-green-500/20 hover:border-green-500/40 hover:-translate-y-1"
                >
                  <div class="min-h-[120px]">
                    <h3 class="text-xl font-bold mb-3 group-hover:text-green-400 transition-colors font-serif text-white">
                      {topic.title}
                    </h3>
                    <p class="text-sm text-white/60 line-clamp-3">
                      {topic.content |> fast_strip_tags() |> String.slice(0, 150)}...
                    </p>
                  </div>
                  <div class="mt-4 pt-4 border-t border-white/10 flex items-center justify-between text-xs text-white/40">
                    <span>
                      {Calendar.strftime(topic.published_at || DateTime.utc_now(), "%b %d, %Y")}
                    </span>
                    <span class="flex items-center gap-1 group-hover:text-green-400 transition-colors">
                      {gettext("Read")} <.icon name="hero-arrow-right" class="w-3 h-3" />
                    </span>
                  </div>
                </.link>
              <% end %>
            </div>
          </div>
        </section>
        
    <!-- EVENTS SECTION with Snowdrift -->
        <section :if={@featured_events != []} class="relative py-12 md:py-24 border-t border-white/10">
          <!-- Snowdrift Divider -->
          <div class="absolute top-0 left-0 w-full overflow-hidden leading-none z-10 -translate-y-[1px]">
            <svg
              data-name="Layer 1"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 1200 120"
              preserveAspectRatio="none"
              class="relative block w-full h-[40px] md:h-[60px] fill-black/20"
            >
              <path d="M321.39,56.44c58-10.79,114.16-30.13,172-41.86,82.39-16.72,168.19-17.73,250.45-.39C823.78,31,906.67,72,985.66,92.83c70.05,18.48,146.53,26.09,214.34,3V0H0V27.35A600.21,600.21,0,0,0,321.39,56.44Z">
              </path>
            </svg>
          </div>

          <div class="max-w-7xl mx-auto px-6 lg:px-8 relative z-20 pt-10">
            <div class="mb-12 md:mb-16 flex flex-col md:flex-row md:items-end justify-between gap-6 apple-reveal">
              <div class="max-w-2xl">
                <p class="text-sm tracking-[0.2em] uppercase text-yellow-400 font-semibold mb-4 flex items-center gap-2">
                  <span>
                    <!-- SVG Bell Icon -->
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="w-5 h-5 fill-current"
                      viewBox="0 0 24 24"
                    >
                      <path d="M11.5 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6.5-6v-5.5c0-3.07-2.13-5.64-5-6.32V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5v.68c-2.87.68-5 3.25-5 6.32V16l-2 2v1h17v-1l-2-2z" />
                    </svg>
                  </span>
                  {gettext("Community")}
                  <span>
                    <!-- SVG Bell Icon -->
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      class="w-5 h-5 fill-current"
                      viewBox="0 0 24 24"
                    >
                      <path d="M11.5 22c1.1 0 2-.9 2-2h-4c0 1.1.9 2 2 2zm6.5-6v-5.5c0-3.07-2.13-5.64-5-6.32V3.5c0-.83-.67-1.5-1.5-1.5S10 2.67 10 3.5v.68c-2.87.68-5 3.25-5 6.32V16l-2 2v1h17v-1l-2-2z" />
                    </svg>
                  </span>
                </p>
                <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold tracking-tight leading-[1.1] font-christmas text-white">
                  {gettext("Upcoming Events")}
                </h2>
              </div>
              <.link
                navigate={~p"/events"}
                class="group inline-flex items-center gap-2 text-sm font-medium hover:text-yellow-400 transition-colors text-white/70"
              >
                {gettext("View all events")}
                <.icon
                  name="hero-arrow-right"
                  class="w-4 h-4 group-hover:translate-x-1 transition-transform"
                />
              </.link>
            </div>

            <div class="grid md:grid-cols-3 gap-6 apple-reveal">
              <%= for event <- @featured_events do %>
                <.link
                  navigate={~p"/public/events/#{event.slug}"}
                  class="group relative bg-gradient-to-br from-yellow-900/30 to-yellow-950/30 backdrop-blur-sm rounded-2xl p-6 lg:p-8 hover:from-yellow-900/50 hover:to-yellow-950/50 transition-all border border-yellow-500/20 hover:border-yellow-500/40 hover:-translate-y-1"
                >
                  <div class="absolute top-6 right-6 px-3 py-1 rounded-full text-xs font-medium bg-yellow-500/20 text-yellow-400">
                    <%= if event.event_date do %>
                      {Calendar.strftime(event.event_date, "%b %d")}
                    <% else %>
                      {gettext("TBD")}
                    <% end %>
                  </div>

                  <div class="mb-4">
                    <span class={[
                      "inline-block w-2 h-2 rounded-full mb-1",
                      if(event.status == "public", do: "bg-green-400", else: "bg-white/30")
                    ]}>
                    </span>
                  </div>

                  <h3 class="text-xl font-bold mb-2 line-clamp-2 group-hover:text-yellow-400 transition-colors text-white">
                    {event.title}
                  </h3>

                  <div class="flex items-center gap-2 text-sm text-white/60 mb-4">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    <span class="truncate">
                      {[event.city, event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                    </span>
                  </div>

                  <div class="mt-auto pt-4 flex items-center text-sm font-medium text-white/40 group-hover:text-white transition-colors">
                    {gettext("Learn more")}
                    <.icon
                      name="hero-arrow-right"
                      class="w-4 h-4 ml-2 opacity-0 group-hover:opacity-100 transition-all transform -translate-x-2 group-hover:translate-x-0"
                    />
                  </div>
                </.link>
              <% end %>
            </div>
          </div>
        </section>
        
    <!-- QUOTE: Christmas themed -->
        <section class="py-12 md:py-32 lg:py-40 relative bg-gradient-to-br from-red-900/30 via-green-900/20 to-yellow-900/30">
          <!-- Decorative elements -->
          <div class="absolute top-10 left-10 text-4xl ornament-swing hidden lg:block">🎄</div>
          <div
            class="absolute top-10 right-10 text-4xl ornament-swing hidden lg:block"
            style="animation-delay: -1s;"
          >
            🎄
          </div>
          <div class="absolute bottom-10 left-20 text-3xl float hidden lg:block">🎁</div>
          <div
            class="absolute bottom-10 right-20 text-3xl float hidden lg:block"
            style="animation-delay: -2s;"
          >
            🎁
          </div>

          <div class="max-w-5xl mx-auto px-6 lg:px-8 text-center relative z-10 apple-scale">
            <div class="mb-6">
              <span class="text-5xl">⭐</span>
            </div>
            <blockquote class="font-serif text-2xl md:text-4xl lg:text-5xl xl:text-6xl italic leading-[1.2] text-white/90 mb-6 md:mb-10">
              "{gettext(
                "You cannot know the meaning of your life until you are connected to the power that created you."
              )}"
            </blockquote>
            <cite class="text-white/50 text-lg not-italic tracking-wide">
              — Shri Mataji Nirmala Devi
            </cite>
          </div>
        </section>
        
    <!-- CTA: Christmas themed -->
        <section class="py-12 md:py-32 lg:py-40 border-t border-white/10">
          <div class="max-w-5xl mx-auto px-6 lg:px-8 text-center apple-reveal">
            <div class="mb-6 flex justify-center gap-4">
              <span class="text-4xl ornament-swing">🎁</span>
              <span class="text-4xl ornament-swing" style="animation-delay: -0.5s;">🎄</span>
              <span class="text-4xl ornament-swing" style="animation-delay: -1s;">⭐</span>
            </div>
            <h2 class="text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold tracking-tight mb-4 md:mb-6 font-christmas gold-shimmer">
              {gettext("Unlock Your Full Journey")}
            </h2>
            <p class="text-lg md:text-xl lg:text-2xl text-white/60 mb-8 md:mb-12 max-w-2xl mx-auto leading-relaxed">
              {gettext(
                "Register for free to access structured learning, resources, and progress tracking"
              )}
            </p>
            
    <!-- Benefits list -->
            <div class="flex flex-wrap justify-center gap-4 md:gap-6 lg:gap-8 mb-8 md:mb-12 text-sm md:text-base text-white/60">
              <div class="flex items-center gap-2">
                <.icon name="hero-academic-cap" class="w-5 h-5 text-red-400" />
                <span>{gettext("Structured Learning")}</span>
              </div>
              <div class="flex items-center gap-2">
                <.icon name="hero-book-open" class="w-5 h-5 text-green-400" />
                <span>{gettext("Resources")}</span>
              </div>
              <div class="flex items-center gap-2">
                <.icon name="hero-chart-bar" class="w-5 h-5 text-yellow-400" />
                <span>{gettext("Track Progress")}</span>
              </div>
            </div>
            
    <!-- CTA buttons -->
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <.link
                navigate={~p"/users/register"}
                class="group inline-flex items-center gap-3 bg-gradient-to-r from-red-600 to-red-700 text-white px-8 py-4 rounded-full font-medium hover-lift shadow-lg shadow-red-500/30"
              >
                🎁 {gettext("Register for Free")}
                <span class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center group-hover:bg-white/30 transition-colors">
                  <.icon name="hero-arrow-right" class="w-4 h-4" />
                </span>
              </.link>
              <.link
                navigate={~p"/steps"}
                class="text-white/60 hover:text-white transition-colors font-medium"
              >
                {gettext("Try without account")}
              </.link>
            </div>

            <p class="mt-8 text-sm text-white/40 flex items-center justify-center gap-2">
              <span>🎄</span>
              {gettext("Sahaja Yoga meditation is always free")}
              <span>🎄</span>
            </p>
          </div>
        </section>
        
    <!-- Spacer for footer -->
        <div class="h-20"></div>
      </div>
    </Layouts.app>
    """
  end

  defp fast_strip_tags(nil), do: ""

  defp fast_strip_tags(html) do
    html
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
