defmodule SahajyogWeb.DemoLive do
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
      <div id="demo-page-container" class="min-h-screen bg-base-100" phx-hook="GSAPScrollReveal">
        <style>
           /* 2025 Modern Typography & Animations */
          @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;1,400&display=swap');

          .font-display { font-family: 'Inter', system-ui, sans-serif; }
          .font-serif { font-family: 'Playfair Display', Georgia, serif; }

          /* Smooth hover */
          .hover-lift {
            transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1);
          }
          .hover-lift:hover {
            transform: translateY(-4px);
          }

          /* Hover lift effect for cards */
          .card-hover {
            transition: transform 0.4s cubic-bezier(0.5, 0, 0, 1),
                        box-shadow 0.4s cubic-bezier(0.5, 0, 0, 1);
          }
          .card-hover:hover {
            transform: translateY(-12px);
            box-shadow: 0 30px 60px rgba(0, 0, 0, 0.12);
          }
        </style>

        <%!-- Hero Section - Full Viewport with Video (subtract navbar) --%>
        <section
          id="demo-hero"
          phx-hook="GSAPHero"
          class="flex flex-col px-4 md:px-8 lg:px-16 pt-2 pb-4 h-[calc(100vh-80px)]"
        >
          <%!-- Title and Subtitle --%>
          <div class="text-center mb-4 md:mb-6 shrink-0">
            <h1 class="hero-element text-2xl md:text-4xl lg:text-5xl font-semibold text-base-content tracking-tight mb-2">
              <span class="block" phx-hook="GSAPTextReveal" id="hero-text-title" phx-update="ignore">
                {gettext("Sahaja Yoga")}
              </span>
            </h1>
            <p class="hero-element text-base md:text-lg text-base-content/70 max-w-2xl mx-auto">
              {gettext("Discover the peace within. Free meditation for everyone.")}
            </p>
          </div>

          <%!-- Video Player - Main Focus (fills available space) --%>
          <div
            :if={@current_video}
            class="hero-element flex-1 min-h-0 flex flex-col max-w-6xl mx-auto w-full"
          >
            <div class="bg-base-200 rounded-2xl md:rounded-3xl overflow-hidden shadow-2xl flex-1 flex flex-col">
              <div class="flex-1 bg-black">
                <.video_player
                  video_id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                  provider={:youtube}
                  locale={@locale}
                />
              </div>
              <div class="p-3 md:p-4 text-center shrink-0">
                <h2 class="text-base md:text-lg font-semibold text-base-content">
                  {@current_video.title}
                </h2>
              </div>
            </div>
          </div>

          <%!-- Scroll Indicator - Bottom of viewport --%>
          <div
            id="scroll-indicator"
            class="hero-element hidden sm:flex flex-col items-center mt-4 shrink-0 transition-opacity duration-500"
          >
            <p class="text-base-content/50 text-sm mb-2">{gettext("Scroll to explore")}</p>
            <.icon name="hero-chevron-double-down" class="w-6 h-6 text-base-content/40" />
          </div>
        </section>

        <%!-- Featured Card - Full Width Gradient (like iPad Air) --%>
        <%!-- Featured Card - Full Width Gradient (like iPad Air) --%>
        <section class="mx-4 md:mx-8 lg:mx-16 mb-8 gsap-reveal">
          <div
            id="feat-card-1"
            phx-hook="GSAPCard3D"
            class="gsap-3d-card bg-gradient-to-b from-violet-100 to-violet-50 dark:from-violet-950/50 dark:to-violet-900/30 rounded-3xl p-12 md:p-20 text-center card-hover"
          >
            <p class="text-sm font-medium text-primary mb-4 tracking-wide uppercase">
              {gettext("The Meditation")}
            </p>
            <h2 class="text-3xl md:text-5xl lg:text-6xl font-semibold text-base-content mb-4">
              {gettext("Self-Realization")}
            </h2>
            <p class="text-lg md:text-xl text-base-content/70 mb-8 max-w-xl mx-auto">
              {gettext("Awaken your inner energy. Experience thoughtless awareness.")}
            </p>
            <div>
              <.link
                navigate={~p"/steps"}
                phx-hook="GSAPMagnetic"
                id="demo-exp-btn"
                class="magnetic-btn hover-lift px-6 py-2.5 bg-primary text-primary-content rounded-full text-sm font-medium inline-block"
              >
                {gettext("Experience Now")}
              </.link>
            </div>
          </div>
        </section>

        <%!-- Two Column Cards (like AirPods + Watch) --%>
        <%!-- Two Column Cards (like AirPods + Watch) --%>
        <section class="mx-4 md:mx-8 lg:mx-16 mb-8 grid md:grid-cols-2 gap-6">
          <%!-- Talks Card --%>
          <div class="gsap-reveal">
            <div
              id="talks-card"
              phx-hook="GSAPCard3D"
              class="gsap-3d-card bg-gradient-to-b from-sky-100 to-sky-50 dark:from-sky-950/50 dark:to-sky-900/30 rounded-3xl p-10 md:p-14 text-center card-hover"
            >
              <div>
                <p class="text-sm font-medium text-sky-600 dark:text-sky-400 mb-2 tracking-wide">
                  {gettext("Wisdom")}
                </p>
                <h3 class="text-2xl md:text-3xl font-semibold text-base-content mb-3">
                  {gettext("Talks & Lectures")}
                </h3>
                <p class="text-base-content/70 mb-6 max-w-sm mx-auto">
                  {gettext("Timeless teachings from Shri Mataji Nirmala Devi.")}
                </p>
                <div>
                  <.link
                    navigate={~p"/talks"}
                    phx-hook="GSAPMagnetic"
                    id="demo-talks-btn"
                    class="magnetic-btn hover-lift inline-block px-5 py-2 bg-sky-600 text-white rounded-full text-sm font-medium"
                  >
                    {gettext("Browse Talks")}
                  </.link>
                </div>
                <%!-- Decorative element --%>
                <div class="mt-10 text-6xl opacity-20">🎙️</div>
              </div>
            </div>
          </div>

          <%!-- Topics Card --%>
          <div class="gsap-reveal">
            <div
              id="topics-card"
              phx-hook="GSAPCard3D"
              class="gsap-3d-card bg-gradient-to-b from-amber-100 to-amber-50 dark:from-amber-950/50 dark:to-amber-900/30 rounded-3xl p-10 md:p-14 text-center card-hover"
            >
              <div>
                <p class="text-sm font-medium text-amber-600 dark:text-amber-400 mb-2 tracking-wide">
                  {gettext("Knowledge")}
                </p>
                <h3 class="text-2xl md:text-3xl font-semibold text-base-content mb-3">
                  {gettext("Topics & Themes")}
                </h3>
                <p class="text-base-content/70 mb-6 max-w-sm mx-auto">
                  {gettext("Explore teachings organized by subject.")}
                </p>
                <div>
                  <.link
                    navigate={~p"/topics"}
                    phx-hook="GSAPMagnetic"
                    id="demo-topics-btn"
                    class="magnetic-btn hover-lift inline-block px-5 py-2 bg-amber-600 text-white rounded-full text-sm font-medium"
                  >
                    {gettext("Explore Topics")}
                  </.link>
                </div>
                <%!-- Decorative element --%>
                <div class="mt-10 text-6xl opacity-20">📚</div>
              </div>
            </div>
          </div>
        </section>

        <%!-- Quote Section - Full Width --%>
        <%!-- Quote Section - Full Width --%>
        <section class="mx-4 md:mx-8 lg:mx-16 mb-8 gsap-reveal">
          <div class="bg-gradient-to-br from-base-200 to-base-300 rounded-3xl p-10 md:p-16 text-center">
            <blockquote class="text-xl md:text-2xl lg:text-3xl text-base-content italic leading-relaxed max-w-4xl mx-auto mb-8">
              "{gettext(
                "You cannot know the meaning of your life until you are connected to the power that created you."
              )}"
            </blockquote>
            <p class="text-base-content/60 font-medium">
              — Shri Mataji Nirmala Devi
            </p>
          </div>
        </section>

        <%!-- Steps Card - Full Width --%>
        <%!-- Steps Card - Full Width --%>
        <section class="mx-4 md:mx-8 lg:mx-16 mb-8 gsap-reveal">
          <div
            id="steps-card"
            phx-hook="GSAPCard3D"
            class="gsap-3d-card bg-gradient-to-b from-emerald-100 to-emerald-50 dark:from-emerald-950/50 dark:to-emerald-900/30 rounded-3xl p-12 md:p-20 text-center card-hover"
          >
            <p class="text-sm font-medium text-emerald-600 dark:text-emerald-400 mb-4 tracking-wide uppercase">
              {gettext("Your Journey")}
            </p>
            <h2 class="text-3xl md:text-5xl font-semibold text-base-content mb-4">
              {gettext("7 Steps to Meditation")}
            </h2>
            <p class="text-lg md:text-xl text-base-content/70 mb-8 max-w-xl mx-auto">
              {gettext("A guided path to inner peace and self-discovery.")}
            </p>
            <div>
              <.link
                navigate={~p"/steps"}
                phx-hook="GSAPMagnetic"
                id="demo-steps-btn"
                class="magnetic-btn hover-lift inline-block px-6 py-2.5 bg-emerald-600 text-white rounded-full text-sm font-medium"
              >
                {gettext("Begin Your Journey")}
              </.link>
            </div>
          </div>
        </section>

        <%!-- CTA Section --%>
        <section class="py-20 md:py-32 text-center px-4 gsap-reveal">
          <div>
            <h2 class="text-3xl md:text-5xl font-semibold text-base-content mb-6">
              {gettext("Start Your Journey Today")}
            </h2>
            <p class="text-lg md:text-xl text-base-content/70 mb-10 max-w-xl mx-auto">
              {gettext("Sahaja Yoga is always free. Join millions who have found inner peace.")}
            </p>
            <div>
              <.link
                navigate={~p"/users/register"}
                phx-hook="GSAPMagnetic"
                id="demo-cta-btn"
                class="magnetic-btn hover-lift inline-block px-10 py-4 bg-primary text-primary-content rounded-full text-lg font-medium shadow-lg"
              >
                {gettext("Get Started — It's Free")}
              </.link>
            </div>
          </div>
        </section>

        <%!-- Footer spacer --%>
        <div class="h-20"></div>
      </div>
    </Layouts.app>
    """
  end
end
