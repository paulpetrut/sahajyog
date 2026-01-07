defmodule SahajyogWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SahajyogWeb, :html

  import SahajyogWeb.LocaleSwitcher
  import SahajyogWeb.MobileMenu

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <main>
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the secondary navigation for events.
  """
  attr :current_page, :atom, required: true

  def events_nav(assigns) do
    ~H"""
    <nav class="flex justify-center mb-8 sm:mb-12">
      <div class="bg-gradient-to-br from-base-200/80 to-base-300/80 backdrop-blur-sm rounded-xl p-1.5 border border-base-content/10 shadow-xl flex flex-wrap justify-center gap-1.5 w-full sm:w-max mx-auto px-1.5">
        <.link
          navigate={~p"/events"}
          class={[
            "px-4 py-2.5 rounded-lg transition-all duration-200 font-bold text-sm sm:text-base flex items-center justify-center gap-2 flex-grow sm:flex-grow-0 sm:flex-none min-w-[120px] sm:min-w-0 md:min-w-[140px]",
            if(@current_page == :list,
              do: "bg-primary text-primary-content shadow-lg shadow-primary/20",
              else: "text-base-content/60 hover:bg-base-100/50 hover:text-base-content"
            )
          ]}
        >
          <.icon name="hero-calendar" class="w-4 h-4 sm:w-5 sm:h-5" />
          <span>{gettext("All Events")}</span>
        </.link>

        <.link
          navigate={~p"/events?filter=my_events"}
          class={[
            "px-4 py-2.5 rounded-lg transition-all duration-200 font-bold text-sm sm:text-base flex items-center justify-center gap-2 flex-grow sm:flex-grow-0 sm:flex-none min-w-[120px] sm:min-w-0 md:min-w-[140px]",
            if(@current_page == :my_events,
              do: "bg-primary text-primary-content shadow-lg shadow-primary/20",
              else: "text-base-content/60 hover:bg-base-100/50 hover:text-base-content"
            )
          ]}
        >
          <.icon name="hero-user-group" class="w-4 h-4 sm:w-5 sm:h-5" />
          <span>{gettext("My Events")}</span>
        </.link>

        <.link
          navigate={~p"/events?filter=past"}
          class={[
            "px-4 py-2.5 rounded-lg transition-all duration-200 font-bold text-sm sm:text-base flex items-center justify-center gap-2 flex-grow sm:flex-grow-0 sm:flex-none min-w-[120px] sm:min-w-0 md:min-w-[140px]",
            if(@current_page == :past,
              do: "bg-primary text-primary-content shadow-lg shadow-primary/20",
              else: "text-base-content/60 hover:bg-base-100/50 hover:text-base-content"
            )
          ]}
        >
          <.icon name="hero-clock" class="w-4 h-4 sm:w-5 sm:h-5" />
          <span>{gettext("Past Events")}</span>
        </.link>
      </div>
    </nav>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders the site footer with navigation links and contact information.
  """
  attr :current_scope, :map, default: nil

  def footer(assigns) do
    ~H"""
    <footer class="w-full bg-base-300 border-t border-base-content/10 mt-auto overflow-hidden">
      <div class="max-w-7xl mx-auto px-3 sm:px-6 lg:px-8 py-8 sm:py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12">
          <%!-- Left: Branding --%>
          <div class="text-center md:text-left">
            <h3 class="text-2xl font-bold text-base-content mb-3">SahajYog</h3>
            <p class="text-base-content/60 text-sm leading-relaxed">
              {gettext(
                "Discover inner peace through Sahaja Yoga meditation. Explore teachings, talks, and resources for your spiritual journey."
              )}
            </p>
          </div>

          <%!-- Center: Quick Links --%>
          <div class="text-center md:text-left md:pl-20">
            <h4 class="text-sm font-semibold text-base-content uppercase tracking-wider mb-4">
              {gettext("Explore")}
            </h4>
            <nav class="flex flex-col gap-3 items-center md:items-start">
              <.link
                navigate={~p"/"}
                data-footer-path="/"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Home")}
              </.link>
              <.link
                :if={@current_scope}
                navigate={~p"/steps"}
                data-footer-path="/steps"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Steps")}
              </.link>
              <.link
                navigate={~p"/talks"}
                data-footer-path="/talks"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Talks")}
              </.link>
              <.link
                :if={@current_scope}
                navigate={~p"/resources"}
                data-footer-path="/resources"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Resources")}
              </.link>
              <.link
                :if={@current_scope}
                navigate={~p"/topics"}
                data-footer-path="/topics"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Topics")}
              </.link>

              <.link
                :if={@current_scope}
                navigate={~p"/store"}
                data-footer-path="/store"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Store")}
              </.link>
              <.link
                :if={
                  @current_scope && Sahajyog.Accounts.User.eligible_for_upgrade?(@current_scope.user)
                }
                navigate={~p"/level-upgrade"}
                data-footer-path="/level-upgrade"
                class="footer-nav-link text-base-content/70 hover:text-primary transition-colors text-sm"
              >
                {gettext("Upgrade Access")}
              </.link>
            </nav>
          </div>

          <%!-- Right: Contact --%>
          <div class="text-center md:text-left">
            <h4 class="text-sm font-semibold text-base-content uppercase tracking-wider mb-4">
              {gettext("Get in Touch")}
            </h4>
            <p class="text-base-content/70 text-sm mb-4">
              {gettext("Have questions? We'd love to hear from you.")}
            </p>
            <.link
              navigate={~p"/contact"}
              class="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-primary-content hover:bg-primary/90 rounded-lg transition-all duration-200 text-sm font-medium"
            >
              <.icon name="hero-envelope" class="w-4 h-4" />
              {gettext("Contact Us")}
            </.link>
          </div>
        </div>

        <%!-- Bottom Bar --%>
        <div class="border-t border-base-content/10 mt-10 pt-6">
          <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
            <p class="text-base-content/70 text-sm">
              © {DateTime.utc_now().year} SahajYog. {gettext("All rights reserved.")}
            </p>
            <div class="flex items-center gap-4">
              <p class="text-base-content/60 text-xs">
                {gettext("Sahaja Yoga is always free")}
              </p>
              <button
                onclick="window.scrollTo({top: 0, behavior: 'smooth'})"
                class="p-2 bg-base-200 hover:bg-primary hover:text-primary-content rounded-full transition-all duration-200 group"
                aria-label={gettext("Back to top")}
                title={gettext("Back to top")}
              >
                <.icon name="hero-arrow-up" class="w-4 h-4 group-hover:animate-bounce" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </footer>
    """
  end
end
