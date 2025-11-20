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
    <div class={["relative w-full", @class]}>
      <select
        id={@id}
        name="locale"
        phx-hook="LocaleSelector"
        class="appearance-none w-full bg-gray-800 text-white border border-gray-700 rounded-lg px-4 py-2.5 pr-10 hover:bg-gray-700 transition-colors cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
      >
        <%= for {code, name} <- @locales do %>
          <option value={code} selected={@current_locale == code}>
            {name}
          </option>
        <% end %>
      </select>
      <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3 text-gray-400">
        <.icon name="hero-chevron-down" class="w-4 h-4" />
      </div>
    </div>
    """
  end
end
