defmodule SahajyogWeb.MobileMenu do
  @moduledoc """
  Component for rendering the mobile navigation menu drawer.
  Displays navigation links, user info, locale switcher, and theme toggle.
  """
  use SahajyogWeb, :html
  import SahajyogWeb.LocaleSwitcher

  attr :current_scope, :map, default: nil
  attr :locale, :string, default: "en"

  def mobile_menu(assigns) do
    ~H"""
    <div class="relative h-full w-80 bg-base-200 flex flex-col">
      <%!-- Header Section --%>
      <div class="flex items-center justify-between p-4 border-b border-base-content/10">
        <span class="text-sm font-bold uppercase tracking-[0.2em] text-base-content/50">
          {gettext("Menu")}
        </span>
        <label
          for="mobile-drawer"
          class="btn btn-ghost btn-circle"
          aria-label="Close menu"
        >
          <.icon name="hero-x-mark" class="w-6 h-6 text-base-content" />
        </label>
      </div>

      <div class="flex-1 overflow-y-auto">
        <%= if @current_scope do %>
          <%!-- User Info Section --%>
          <div class="border-b border-base-content/20 mb-4 pb-4 px-4">
            <div class="flex items-center gap-3 py-3">
              <div class="flex items-center justify-center w-12 h-12 rounded-full bg-base-300 text-base-content font-semibold text-lg">
                {String.upcase(String.first(@current_scope.user.email))}
              </div>
              <div class="flex-1 min-w-0 text-left">
                <p class="text-base font-semibold text-base-content truncate">
                  {@current_scope.user.email}
                </p>
              </div>
            </div>
          </div>

          <ul class="menu p-4 w-full text-base-content gap-1">
            <%!-- Main Menu Items --%>
            <li>
              <.link navigate={~p"/talks"} class="py-3 text-lg min-h-[48px] flex items-center">
                {gettext("Talks")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/steps"} class="py-3 text-lg min-h-[48px] flex items-center">
                {gettext("Steps")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/topics"} class="py-3 text-lg min-h-[48px] flex items-center">
                {gettext("Topics")}
              </.link>
            </li>
            <li>
              <.link navigate={~p"/resources"} class="py-3 text-lg min-h-[48px] flex items-center">
                {gettext("Resources")}
              </.link>
            </li>
            <%= if Sahajyog.Accounts.User.can_access_events?(@current_scope.user) do %>
              <li>
                <.link navigate={~p"/events"} class="py-3 text-lg min-h-[48px] flex items-center">
                  {gettext("Events")}
                </.link>
              </li>
            <% end %>
            <li>
              <.link navigate={~p"/store"} class="py-3 text-lg min-h-[48px] flex items-center">
                {gettext("Store")}
              </.link>
            </li>
            <%= if Sahajyog.Accounts.User.admin?(@current_scope.user) do %>
              <li>
                <.link
                  navigate={~p"/admin/videos"}
                  class="py-3 text-lg min-h-[48px] flex items-center"
                >
                  {gettext("Admin")}
                </.link>
              </li>
            <% end %>
            <li class="border-t border-base-content/20 mt-2 pt-2">
              <.link
                navigate={~p"/users/settings"}
                class="py-3 text-lg min-h-[48px] flex items-center"
              >
                <.icon name="hero-cog-6-tooth" class="w-6 h-6" />
                {gettext("Account settings")}
              </.link>
            </li>
            <li>
              <.link
                href={~p"/users/log-out"}
                method="delete"
                class="py-3 text-lg min-h-[48px] flex items-center"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="w-6 h-6" />
                {gettext("Sign out")}
              </.link>
            </li>
            <li class="border-t border-base-content/20 mt-4 pt-4">
              <div class="flex items-center justify-between py-3 px-3 text-base-content/70 min-h-[48px]">
                <span class="text-base font-medium">{gettext("Language")}</span>
                <.locale_switcher id="locale-select-mobile" current_locale={@locale} />
              </div>
            </li>
            <li class="mt-2 text-base-content/70">
              <div class="flex items-center justify-between py-3 px-3 min-h-[48px]">
                <span class="text-base font-medium">{gettext("Theme")}</span>
                <.theme_toggle />
              </div>
            </li>
          </ul>
        <% else %>
          <ul class="menu p-4 w-full text-base-content gap-1">
            <%!-- Public links for non-logged-in users --%>
            <li>
              <.link
                navigate={~p"/talks"}
                class="py-3 text-lg font-medium min-h-[48px] flex items-center"
              >
                {gettext("Talks")}
              </.link>
            </li>
            <li class="border-t border-base-content/20 mt-4 pt-4 text-base-content/70">
              <div class="flex items-center justify-between py-3 px-3 min-h-[48px]">
                <span class="text-base font-medium">{gettext("Language")}</span>
                <.locale_switcher id="locale-select-mobile-public" current_locale={@locale} />
              </div>
            </li>
            <li class="mt-2 text-base-content/70">
              <div class="flex items-center justify-between py-3 px-3 min-h-[48px]">
                <span class="text-base font-medium">{gettext("Theme")}</span>
                <.theme_toggle />
              </div>
            </li>
          </ul>

          <div class="mt-auto p-4 pb-6">
            <div class="flex flex-col gap-3">
              <.link
                navigate={~p"/users/register"}
                class="btn btn-primary btn-lg w-full font-bold shadow-lg"
              >
                {gettext("Register")}
              </.link>
              <.link
                navigate={~p"/users/log-in"}
                class="btn btn-outline btn-lg w-full font-medium"
              >
                {gettext("Log in")}
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
