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
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  @doc """
  Renders the site footer with navigation links and contact information.
  """
  attr :current_scope, :map, default: nil

  def footer(assigns) do
    ~H"""
    <footer class="w-full bg-base-200/50 border-t border-base-content/10 mt-auto">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-12">
          <%!-- Left: Branding --%>
          <div>
            <h3 class="text-2xl font-bold text-base-content mb-3">SahajYog</h3>
            <p class="text-base-content/60 text-sm leading-relaxed">
              {gettext(
                "Discover inner peace through Sahaja Yoga meditation. Explore teachings, talks, and resources for your spiritual journey."
              )}
            </p>
          </div>

          <%!-- Center: Quick Links --%>
          <div>
            <h4 class="text-sm font-semibold text-base-content uppercase tracking-wider mb-4">
              {gettext("Explore")}
            </h4>
            <nav class="flex flex-col gap-2">
              <.link
                href={~p"/"}
                data-footer-path="/"
                class="footer-nav-link text-base-content/60 hover:text-primary transition-colors text-sm"
              >
                {gettext("Home")}
              </.link>
              <.link
                href={~p"/steps"}
                data-footer-path="/steps"
                class="footer-nav-link text-base-content/60 hover:text-primary transition-colors text-sm"
              >
                {gettext("Steps")}
              </.link>
              <.link
                href={~p"/talks"}
                data-footer-path="/talks"
                class="footer-nav-link text-base-content/60 hover:text-primary transition-colors text-sm"
              >
                {gettext("Talks")}
              </.link>
              <.link
                :if={@current_scope}
                href={~p"/resources"}
                data-footer-path="/resources"
                class="footer-nav-link text-base-content/60 hover:text-primary transition-colors text-sm"
              >
                {gettext("Resources")}
              </.link>
              <.link
                :if={@current_scope}
                href={~p"/topics"}
                data-footer-path="/topics"
                class="footer-nav-link text-base-content/60 hover:text-primary transition-colors text-sm"
              >
                {gettext("Topics")}
              </.link>
            </nav>
          </div>

          <%!-- Right: Contact --%>
          <div class="text-center md:text-left">
            <h4 class="text-sm font-semibold text-base-content uppercase tracking-wider mb-4">
              {gettext("Get in Touch")}
            </h4>
            <p class="text-base-content/60 text-sm mb-4">
              {gettext("Have questions? We'd love to hear from you.")}
            </p>
            <.link
              href={~p"/contact"}
              class="inline-flex items-center gap-2 px-5 py-2.5 bg-primary text-primary-content hover:bg-primary/90 rounded-lg transition-all duration-200 text-sm font-medium"
            >
              <.icon name="hero-envelope" class="w-4 h-4" />
              {gettext("Contact Us")}
            </.link>
          </div>
        </div>

        <%!-- Bottom Bar --%>
        <div class="border-t border-base-content/10 mt-10 pt-6 flex flex-col sm:flex-row justify-between items-center gap-4">
          <p class="text-base-content/50 text-sm">
            © {DateTime.utc_now().year} SahajYog. {gettext("All rights reserved.")}
          </p>
          <p class="text-base-content/40 text-xs">
            {gettext("Sahaja Yoga is always free")}
          </p>
        </div>
      </div>
    </footer>
    """
  end
end
