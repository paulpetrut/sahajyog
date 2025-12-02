defmodule SahajyogWeb.LocaleSwitcher do
  use Phoenix.Component
  import SahajyogWeb.CoreComponents

  attr :current_locale, :string, default: "en"
  attr :class, :string, default: ""
  attr :id, :string, default: "locale-select"

  def locale_switcher(assigns) do
    locales = [
      {"en", "English"},
      {"ro", "Română"},
      {"it", "Italiano"},
      {"de", "Deutsch"},
      {"es", "Español"},
      {"fr", "Français"}
    ]

    assigns = Map.put(assigns, :locales, locales)

    ~H"""
    <div class={["dropdown dropdown-end", @class]}>
      <div
        tabindex="0"
        role="button"
        class="btn btn-ghost btn-sm btn-circle text-base-content/70 hover:text-base-content transition-colors"
        aria-label="Select language"
      >
        <.icon name="hero-globe-alt" class="w-5 h-5" />
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu bg-base-200 rounded-box z-[99999] w-40 p-2 shadow mt-2"
      >
        <%= for {code, name} <- @locales do %>
          <li>
            <button
              type="button"
              phx-hook="LocaleSelector"
              id={"#{@id}-#{code}"}
              data-locale={code}
              class={"flex items-center gap-2 #{if @current_locale == code, do: "active", else: ""}"}
            >
              {name}
              <%= if @current_locale == code do %>
                <.icon name="hero-check" class="w-4 h-4 ml-auto" />
              <% end %>
            </button>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end
