defmodule SahajyogWeb.MobileMenu do
  use SahajyogWeb, :html
  import SahajyogWeb.LocaleSwitcher

  attr :current_scope, :map, default: nil
  attr :locale, :string, default: "en"

  def mobile_menu(assigns) do
    ~H"""
    <%!-- Mobile Menu Overlay --%>
    <div
      id="mobile-menu-overlay"
      class="fixed inset-0 z-40 hidden md:hidden backdrop-blur-sm bg-black/25"
    >
    </div>
    <%!-- Mobile Menu Sidebar --%>
    <div
      id="mobile-menu"
      class="fixed top-0 right-0 h-full w-64 bg-base-200 shadow-xl z-50 transform translate-x-full transition-transform duration-300 ease-in-out md:hidden"
    >
      <div class="flex flex-col h-full">
        <%!-- Menu Items --%>
        <nav class="flex-1 px-4 pt-20 pb-2 overflow-y-auto">
          <ul class="menu menu-vertical w-full gap-2">
            <%= if @current_scope do %>
              <%!-- User Info Section --%>
              <li class="border-b border-base-content/20 mb-2 pb-2">
                <div class="flex items-center gap-3 py-3 px-0 pointer-events-none">
                  <div class="flex items-center justify-center w-10 h-10 rounded-full bg-base-300 text-base-content font-semibold">
                    {String.upcase(String.first(@current_scope.user.email))}
                  </div>
                  <div class="flex-1 min-w-0 text-left">
                    <p class="text-sm font-semibold text-base-content truncate">
                      {@current_scope.user.email}
                    </p>
                  </div>
                </div>
              </li>
              <%!-- Main Menu Items --%>
              <li>
                <.link href={~p"/steps"}>{gettext("Steps")}</.link>
              </li>
              <li>
                <.link href={~p"/talks"}>{gettext("Talks")}</.link>
              </li>
              <li>
                <.link href={~p"/topics"}>{gettext("Topics")}</.link>
              </li>
              <li>
                <.link href={~p"/resources"}>{gettext("Resources")}</.link>
              </li>
              <%= if Sahajyog.Accounts.User.can_access_events?(@current_scope.user) do %>
                <li>
                  <.link href={~p"/events"}>{gettext("Events")}</.link>
                </li>
              <% end %>
              <%= if Sahajyog.Accounts.User.admin?(@current_scope.user) do %>
                <li>
                  <.link href={~p"/admin/videos"}>{gettext("Admin")}</.link>
                </li>
              <% end %>
              <li class="mt-2">
                <.link href={~p"/users/settings"}>
                  <.icon name="hero-cog-6-tooth" class="w-5 h-5" />
                  {gettext("Account settings")}
                </.link>
              </li>
              <li class="border-t border-base-content/20 mt-2 pt-2">
                <.link href={~p"/users/log-out"} method="delete">
                  <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5" />
                  {gettext("Sign out")}
                </.link>
              </li>
              <li class="border-t border-base-content/20 mt-4 pt-2">
                <div class="flex items-center justify-between py-2 px-3">
                  <span class="text-sm font-medium text-base-content/70">{gettext("Language")}</span>
                  <.locale_switcher id="locale-select-mobile" current_locale={@locale} />
                </div>
              </li>
              <li class="mt-2">
                <div class="flex items-center justify-between py-2 px-3">
                  <span class="text-sm font-medium text-base-content/70">{gettext("Theme")}</span>
                  <.theme_toggle />
                </div>
              </li>
            <% else %>
              <%!-- Public links for non-logged-in users --%>
              <li>
                <.link href={~p"/talks"}>{gettext("Talks")}</.link>
              </li>
              <li class="border-t border-base-content/20 mt-4 pt-2">
                <div class="flex items-center justify-between py-2 px-3">
                  <span class="text-sm font-medium text-base-content/70">{gettext("Language")}</span>
                  <.locale_switcher id="locale-select-mobile-public" current_locale={@locale} />
                </div>
              </li>
              <li class="mt-2">
                <div class="flex items-center justify-between py-2 px-3">
                  <span class="text-sm font-medium text-base-content/70">{gettext("Theme")}</span>
                  <.theme_toggle />
                </div>
              </li>
              <li class="border-t border-base-content/20 mt-4 pt-2">
                <.link href={~p"/users/register"} class="btn btn-primary btn-sm w-full font-medium">
                  {gettext("Register")}
                </.link>
              </li>
              <li class="mt-2">
                <.link href={~p"/users/log-in"} class="text-center">{gettext("Log in")}</.link>
              </li>
            <% end %>
          </ul>
        </nav>
      </div>
    </div>
    """
  end
end
