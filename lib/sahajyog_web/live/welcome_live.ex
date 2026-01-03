defmodule SahajyogWeb.WelcomeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Content
  alias Sahajyog.Events
  alias Sahajyog.Topics

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
      <div
        id="welcome-page"
        phx-hook="GSAPScrollReveal"
        class="min-h-screen bg-base-300 text-base-content welcome-page-font"
      >
        <%!-- HERO: Full viewport, minimal, typographic, content-based height --%>
        <section
          id="hero-section"
          phx-hook="GSAPHero"
          class="relative overflow-hidden pt-12 md:pt-20 lg:pt-32 pb-6 md:pb-10 lg:pb-12 flex flex-col justify-center"
        >
          <%!-- Animated gradient orbs --%>
          <div class="hero-orb absolute top-1/4 -left-32 w-96 h-96 bg-primary/10 rounded-full blur-[100px]">
          </div>
          <div
            class="hero-orb absolute bottom-1/4 -right-32 w-80 h-80 bg-secondary/10 rounded-full blur-[100px]"
            style="animation-delay: -3s;"
          >
          </div>

          <div class="relative z-10 w-full max-w-7xl mx-auto px-6 lg:px-8">
            <div>
              <%!-- Eyebrow --%>
              <p class="hero-element text-xs md:text-sm tracking-[0.3em] uppercase text-base-content/40 mb-2 md:mb-6 font-medium">
                {gettext("Free Meditation")}
              </p>

              <%!-- Main headline --%>
              <h1 class="hero-element text-[clamp(2rem,8vw,8rem)] font-bold leading-[0.95] tracking-[-0.03em] mb-3 md:mb-8">
                <span class="block">{gettext("Realize your Self")}</span>
                <span
                  class="block gradient-text"
                  phx-hook="GSAPTextReveal"
                  id="hero-text-title"
                >
                  {gettext("inner silence")}
                </span>
              </h1>

              <%!-- Subhead --%>
              <p class="hero-element text-base md:text-xl lg:text-2xl text-base-content/50 max-w-xl leading-relaxed font-light mb-4 md:mb-12">
                {gettext(
                  "Sahaja Yoga is a unique method of meditation that brings mental, physical and emotional balance."
                )}
              </p>
            </div>
          </div>
        </section>

        <%!-- VIDEO SECTION: Clean, wide --%>
        <section
          :if={@current_video}
          id="video"
          class="pt-6 md:pt-10 lg:pt-12 pb-12 md:pb-20 lg:pb-24 relative"
        >
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="gsap-reveal" data-toggle-actions="play none none reverse">
              <%!-- Video container with ornate golden border --%>
              <div class="ornate-video-border">
                <div
                  id={"welcome-video-container-#{Sahajyog.YouTube.extract_video_id(@current_video.url)}"}
                  phx-hook="LazyYouTube"
                  data-video-id={Sahajyog.YouTube.extract_video_id(@current_video.url)}
                  data-locale={@locale}
                  class="rounded-lg overflow-hidden aspect-video bg-black shadow-inner relative cursor-pointer group"
                >
                  <%!-- Initial placeholder with YouTube thumbnail and play button --%>
                  <div class="absolute inset-0 flex items-center justify-center bg-black">
                    <%!-- YouTube thumbnail (maxresdefault for best quality) --%>
                    <img
                      src={"https://img.youtube.com/vi/#{Sahajyog.YouTube.extract_video_id(@current_video.url)}/maxresdefault.jpg"}
                      alt={@current_video.title}
                      class="absolute inset-0 w-full h-full object-cover"
                      loading="lazy"
                    />
                    <%!-- Dark overlay --%>
                    <div class="absolute inset-0 bg-black/30 group-hover:bg-black/20 transition-colors duration-300">
                    </div>
                    <%!-- YouTube-style play button --%>
                    <div class="relative z-10">
                      <div class="w-20 h-20 bg-red-600 rounded-full flex items-center justify-center group-hover:scale-110 transition-transform duration-300 shadow-2xl">
                        <%!-- Play icon --%>
                        <svg
                          class="w-8 h-8 text-white ml-1"
                          fill="currentColor"
                          viewBox="0 0 20 20"
                        >
                          <path d="M6.3 2.841A1.5 1.5 0 004 4.11V15.89a1.5 1.5 0 002.3 1.269l9.344-5.89a1.5 1.5 0 000-2.538L6.3 2.84z" />
                        </svg>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <%!-- Video info --%>
              <div class="mt-6 md:mt-8 flex flex-col md:flex-row md:items-center md:justify-between gap-3 md:gap-0">
                <div>
                  <p class="text-xs tracking-[0.2em] uppercase text-primary font-semibold mb-1">
                    {gettext("Today's Talk")}
                  </p>
                  <h3 class="text-lg font-medium">{@current_video.title}</h3>
                </div>
                <.link
                  navigate={~p"/talks"}
                  class="text-sm text-base-content/50 hover:text-base-content transition-colors self-start md:self-auto"
                >
                  {gettext("View all")} →
                </.link>
              </div>
            </div>
          </div>
        </section>

        <%!-- PROCESS STRIP: Simple 1-2-3 --%>
        <section class="py-12 md:py-20 border-t border-base-content/5 bg-base-200/30">
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div
              class="text-center mb-10 md:mb-16 gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
              <p class="text-sm tracking-[0.2em] uppercase text-primary font-semibold mb-3">
                {gettext("The Journey")}
              </p>
              <h2 class="text-3xl md:text-4xl font-bold tracking-tight">
                {gettext("How it works")}
              </h2>
            </div>

            <div class="grid md:grid-cols-3 gap-8 relative">
              <%!-- Connecting Line (Desktop) --%>
              <div class="hidden md:block absolute top-8 left-[16%] right-[16%] h-px bg-gradient-to-r from-transparent via-base-content/20 to-transparent z-0">
              </div>
              <%!-- Step 1 --%>
              <.link
                href="#video"
                class="relative z-10 text-center group gsap-reveal block cursor-pointer"
                data-toggle-actions="play none none reverse"
              >
                <div class="w-16 h-16 mx-auto mb-6 rounded-full bg-base-100 border border-base-content/10 flex items-center justify-center shadow-lg shadow-base-200/50 group-hover:scale-110 group-hover:border-primary/30 transition-all duration-300">
                  <span class="text-2xl font-bold text-primary font-serif">1</span>
                </div>
                <h3 class="text-lg font-bold mb-3">{gettext("Learn")}</h3>
                <p class="text-base text-base-content/60 max-w-xs mx-auto leading-relaxed">
                  {gettext("Watch introductory videos to understand the basics.")}
                </p>
              </.link>

              <%!-- Step 2 --%>
              <.link
                navigate={~p"/steps"}
                class="relative z-10 text-center group gsap-reveal block cursor-pointer"
                data-toggle-actions="play none none reverse"
                data-delay="0.2"
              >
                <div class="w-16 h-16 mx-auto mb-6 rounded-full bg-base-100 border border-base-content/10 flex items-center justify-center shadow-lg shadow-base-200/50 group-hover:scale-110 group-hover:border-primary/30">
                  <span class="text-2xl font-bold text-primary font-serif">2</span>
                </div>
                <h3 class="text-lg font-bold mb-3">{gettext("Practice")}</h3>
                <p class="text-base text-base-content/60 max-w-xs mx-auto leading-relaxed">
                  {gettext("Follow guided meditations to experience inner silence.")}
                </p>
              </.link>

              <%!-- Step 3 --%>
              <.link
                navigate={if assigns[:current_scope], do: ~p"/steps", else: ~p"/users/register"}
                class="relative z-10 text-center group gsap-reveal block cursor-pointer"
                data-toggle-actions="play none none reverse"
                data-delay="0.4"
              >
                <div class="w-16 h-16 mx-auto mb-6 rounded-full bg-base-100 border border-base-content/10 flex items-center justify-center shadow-lg shadow-base-200/50 group-hover:scale-110 group-hover:border-primary/30">
                  <span class="text-2xl font-bold text-primary font-serif">3</span>
                </div>
                <h3 class="text-lg font-bold mb-3">
                  {gettext("Experience")}
                  <%= if !assigns[:current_scope] do %>
                    <span class="text-[0.6em] md:text-[0.65em] text-base-content/50 font-normal block">
                      ({gettext("Login Required")})
                    </span>
                  <% end %>
                </h3>
                <p class="text-base text-base-content/60 max-w-xs mx-auto leading-relaxed">
                  {gettext("Feel the peace within and grow through regular practice.")}
                </p>
              </.link>
            </div>

            <div class="mt-12 text-center gsap-reveal" data-toggle-actions="play none none reverse">
              <.link
                navigate={~p"/steps"}
                class="inline-flex items-center gap-2 text-sm font-bold uppercase tracking-widest text-primary hover:text-primary-focus transition-colors"
                id="journey-start-link"
              >
                {gettext("Start your journey")} <.icon name="hero-arrow-right" class="w-4 h-4" />
              </.link>
            </div>
          </div>
        </section>

        <%!-- FEATURES: Horizontal scroll or grid --%>
        <section class="py-12 md:py-24 lg:py-32 border-t border-base-content/5">
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <%!-- Section header --%>
            <div
              class="max-w-2xl mb-6 md:mb-16 lg:mb-20 gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
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

            <%!-- Feature cards - minimal, text-focused --%>
            <div
              id="features-grid"
              phx-hook="GSAPSpotlight"
              class="grid md:grid-cols-3 gap-px bg-base-content/5 rounded-2xl overflow-hidden gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
              <%!-- Card 1 --%>
              <div class="spotlight-card gsap-3d-card bg-base-100 p-6 md:p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                  <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-primary/10 text-primary md:mb-8 shrink-0">
                    <.icon name="hero-sparkles" class="w-5 h-5 md:w-6 md:h-6" />
                  </span>
                  <h3 class="text-lg md:text-xl font-semibold md:mb-3">
                    {gettext("Self Realization")}
                  </h3>
                </div>
                <p class="text-sm md:text-base text-base-content/50 leading-relaxed mb-4 md:mb-6">
                  {gettext("Awaken your inner energy through a simple 10-minute guided experience.")}
                </p>
                <.link
                  navigate={~p"/steps"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-primary hover:gap-3 transition-all"
                >
                  {gettext("Try now")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>

              <%!-- Card 2 --%>
              <div class="gsap-3d-card bg-base-100 p-6 md:p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                  <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-secondary/10 text-secondary md:mb-8 shrink-0">
                    <.icon name="hero-microphone" class="w-5 h-5 md:w-6 md:h-6" />
                  </span>
                  <h3 class="text-lg md:text-xl font-semibold md:mb-3">
                    {gettext("Talks & Lectures")}
                  </h3>
                </div>
                <p class="text-sm md:text-base text-base-content/50 leading-relaxed mb-4 md:mb-6">
                  {gettext("Thousands of hours of wisdom from Shri Mataji Nirmala Devi.")}
                </p>
                <.link
                  navigate={~p"/talks"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-secondary hover:gap-3 transition-all"
                >
                  {gettext("Browse")} <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>

              <%!-- Card 3 --%>
              <div class="gsap-3d-card bg-base-100 p-6 md:p-10 lg:p-12 group hover:bg-base-200/30 transition-colors">
                <div class="flex items-center gap-3 md:block mb-3 md:mb-0">
                  <span class="inline-flex items-center justify-center w-10 h-10 md:w-12 md:h-12 rounded-full bg-accent/10 text-accent md:mb-8 shrink-0">
                    <.icon name="hero-book-open" class="w-5 h-5 md:w-6 md:h-6" />
                  </span>
                  <h3 class="text-lg md:text-xl font-semibold md:mb-3">{gettext("Topics")}</h3>
                </div>
                <p class="text-sm md:text-base text-base-content/50 leading-relaxed mb-4 md:mb-6">
                  {gettext("Explore teachings organized by theme and subject matter.")}
                </p>
                <.link
                  navigate={~p"/topics"}
                  class="inline-flex items-center gap-2 text-sm font-medium text-secondary hover:gap-3 transition-all"
                >
                  {gettext("Explore (Login Required)")}
                  <.icon name="hero-arrow-right" class="w-4 h-4" />
                </.link>
              </div>
            </div>
          </div>
        </section>

        <%!-- TOPICS SECTION --%>
        <section
          :if={@featured_topics != []}
          class="py-12 md:py-24 border-t border-base-content/5 bg-base-200/30"
        >
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div class="mb-12 md:mb-16 gsap-reveal" data-toggle-actions="play none none reverse">
              <p class="text-sm tracking-[0.2em] uppercase text-secondary font-semibold mb-4">
                {gettext("Knowledge")}
              </p>
              <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold tracking-tight leading-[1.1] mb-4">
                {gettext("Featured Topics")}
              </h2>
              <p class="text-lg text-base-content/60">
                {gettext("These topics are generally available to everyone.")}
              </p>
            </div>

            <div
              id="topics-grid"
              phx-hook="GSAPCard3D"
              class="grid md:grid-cols-3 gap-6 gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
              <%= for topic <- @featured_topics do %>
                <.link
                  navigate={~p"/public/topics/#{topic.slug}"}
                  class="gsap-3d-card group relative bg-base-100 rounded-2xl p-6 lg:p-8 hover:bg-base-200/30 transition-all border border-base-content/5 hover:border-base-content/10 hover:-translate-y-1"
                >
                  <div class="min-h-[120px]">
                    <h3 class="text-xl font-bold mb-3 group-hover:text-secondary transition-colors font-serif">
                      {topic.title}
                    </h3>
                    <p class="text-sm text-base-content/60 line-clamp-3">
                      {topic.content |> fast_strip_tags() |> String.slice(0, 150)}...
                    </p>
                  </div>
                  <div class="mt-4 pt-4 border-t border-base-content/5 flex items-center justify-between text-xs text-base-content/40">
                    <span>
                      {Calendar.strftime(topic.published_at || DateTime.utc_now(), "%b %d, %Y")}
                    </span>
                    <span class="flex items-center gap-1 group-hover:text-secondary transition-colors">
                      {gettext("Read")} <.icon name="hero-arrow-right" class="w-3 h-3" />
                    </span>
                  </div>
                </.link>
              <% end %>
            </div>
          </div>
        </section>

        <%!-- EVENTS SECTION --%>
        <section :if={@featured_events != []} class="py-12 md:py-24 border-t border-base-content/5">
          <div class="max-w-7xl mx-auto px-6 lg:px-8">
            <div
              class="mb-12 md:mb-16 flex flex-col md:flex-row md:items-end justify-between gap-6 gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
              <div class="max-w-2xl">
                <p class="text-sm tracking-[0.2em] uppercase text-accent font-semibold mb-4">
                  {gettext("Community")}
                </p>
                <h2 class="text-3xl md:text-4xl lg:text-5xl font-bold tracking-tight leading-[1.1]">
                  {gettext("Upcoming Events")}
                </h2>
              </div>
              <.link
                navigate={~p"/events"}
                class="group inline-flex items-center gap-2 text-sm font-medium hover:text-primary transition-colors"
              >
                {gettext("View all events")}
                <.icon
                  name="hero-arrow-right"
                  class="w-4 h-4 group-hover:translate-x-1 transition-transform"
                />
              </.link>
            </div>

            <div
              id="events-grid"
              phx-hook="GSAPCard3D"
              class="grid md:grid-cols-3 gap-6 gsap-reveal"
              data-toggle-actions="play none none reverse"
            >
              <%= for event <- @featured_events do %>
                <.link
                  navigate={~p"/public/events/#{event.slug}"}
                  class="gsap-3d-card group relative bg-base-100 rounded-2xl p-6 lg:p-8 hover:bg-base-200/30 transition-all border border-base-content/5 hover:border-base-content/10 hover:-translate-y-1"
                >
                  <div class="absolute top-6 right-6 px-3 py-1 rounded-full text-xs font-medium bg-base-content/5 text-base-content/60">
                    <%= if event.event_date do %>
                      {Calendar.strftime(event.event_date, "%b %d")}
                    <% else %>
                      {gettext("TBD")}
                    <% end %>
                  </div>

                  <div class="mb-4">
                    <span class={[
                      "inline-block w-2 h-2 rounded-full mb-1",
                      if(event.status == "public", do: "bg-success", else: "bg-base-content/30")
                    ]}>
                    </span>
                  </div>

                  <h3 class="text-xl font-bold mb-2 line-clamp-2 group-hover:text-primary transition-colors">
                    {event.title}
                  </h3>

                  <div class="flex items-center gap-2 text-sm text-base-content/60 mb-4">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    <span class="truncate">
                      {[event.city, event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                    </span>
                  </div>

                  <div class="mt-auto pt-4 flex items-center text-sm font-medium text-base-content/40 group-hover:text-base-content transition-colors">
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

        <%!-- QUOTE: Full-width, dramatic --%>
        <section class="py-12 md:py-32 lg:py-40 relative animated-gradient noise">
          <div
            class="max-w-5xl mx-auto px-6 lg:px-8 text-center relative z-10 gsap-reveal"
            data-toggle-actions="play none none reverse"
          >
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

        <%!-- CTA: Unlock Your Full Journey --%>
        <section class="py-12 md:py-32 lg:py-40 border-t border-base-content/5">
          <div
            class="max-w-5xl mx-auto px-6 lg:px-8 text-center gsap-reveal"
            data-toggle-actions="play none none reverse"
          >
            <h2 class="text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold tracking-tight mb-4 md:mb-6 text-base-content">
              {gettext("Unlock Your Full Journey")}
            </h2>
            <p class="text-lg md:text-xl lg:text-2xl text-base-content/50 mb-8 md:mb-12 max-w-2xl mx-auto leading-relaxed">
              {gettext(
                "Register for free to access structured learning, resources, and progress tracking"
              )}
            </p>

            <%!-- Minimal benefits list --%>
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

            <%!-- CTA buttons --%>
            <div class="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <.link
                navigate={~p"/users/register"}
                phx-hook="GSAPMagnetic"
                id="cta-register-btn"
                class="magnetic-btn group inline-flex items-center gap-3 bg-base-content text-base-100 px-8 py-4 rounded-full font-medium hover-lift"
              >
                {gettext("Register for Free")}
                <span class="w-8 h-8 rounded-full bg-base-100/20 flex items-center justify-center group-hover:bg-base-100/30 transition-colors">
                  <.icon name="hero-arrow-right" class="w-4 h-4" />
                </span>
              </.link>
              <.link
                navigate={~p"/steps"}
                phx-hook="GSAPMagnetic"
                id="cta-try-btn"
                class="magnetic-btn text-base-content/60 hover:text-base-content transition-colors font-medium px-4 py-2"
              >
                {gettext("Try without account")}
              </.link>
            </div>

            <p class="mt-8 text-sm text-base-content/40">
              {gettext("Sahaja Yoga meditation is always free")}
            </p>
          </div>
        </section>

        <%!-- Spacer for footer --%>
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
