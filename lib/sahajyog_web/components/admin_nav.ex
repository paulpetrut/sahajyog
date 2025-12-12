defmodule SahajyogWeb.AdminNav do
  use SahajyogWeb, :html

  attr :current_page, :atom, default: nil

  def admin_nav(assigns) do
    assigns = assign(assigns, :active_group, get_active_group(assigns.current_page))

    ~H"""
    <div class="bg-gray-800/50 border-b border-gray-700 mb-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <nav class="flex gap-1 flex-wrap md:flex-nowrap w-full">
          <%!-- Resources (standalone) --%>
          <.link
            navigate={~p"/admin/resources"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2 shrink-0 flex items-center gap-1.5",
              if(@current_page == :resources,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-folder" class="w-4 h-4" />
            {gettext("Resources")}
          </.link>

          <%!-- Videos Dropdown --%>
          <.nav_dropdown
            label={gettext("Videos")}
            icon="hero-video-camera"
            active={@active_group == :videos}
            id="videos-dropdown"
          >
            <.dropdown_link
              navigate={~p"/admin/videos"}
              label={gettext("All Videos")}
              active={@current_page == :videos}
            />
            <.dropdown_link
              navigate={~p"/admin/weekly-schedule"}
              label={gettext("Weekly Schedule")}
              active={@current_page == :weekly_schedule}
            />
          </.nav_dropdown>

          <%!-- Topics Dropdown --%>
          <.nav_dropdown
            label={gettext("Topics")}
            icon="hero-document-text"
            active={@active_group == :topics}
            id="topics-dropdown"
          >
            <.dropdown_link
              navigate={~p"/admin/topics"}
              label={gettext("All Topics")}
              active={@current_page == :topics}
            />
            <.dropdown_link
              navigate={~p"/admin/topic-proposals"}
              label={gettext("Proposals")}
              active={@current_page == :topic_proposals}
            />
          </.nav_dropdown>

          <%!-- Events Dropdown --%>
          <.nav_dropdown
            label={gettext("Events")}
            icon="hero-calendar"
            active={@active_group == :events}
            id="events-dropdown"
          >
            <.dropdown_link
              navigate={~p"/admin/events"}
              label={gettext("All Events")}
              active={@current_page == :events}
            />
            <.dropdown_link
              navigate={~p"/admin/event-proposals"}
              label={gettext("Proposals")}
              active={@current_page == :event_proposals}
            />
          </.nav_dropdown>

          <%!-- Store Items (standalone) --%>
          <.link
            navigate={~p"/admin/store-items"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2 shrink-0 flex items-center gap-1.5",
              if(@current_page == :store_items,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-shopping-bag" class="w-4 h-4" />
            {gettext("Store Items")}
          </.link>

          <%!-- Access Codes (standalone) --%>
          <.link
            navigate={~p"/admin/access-codes"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2 shrink-0 flex items-center gap-1.5",
              if(@current_page == :access_codes,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-key" class="w-4 h-4" />
            {gettext("Access Codes")}
          </.link>
        </nav>
      </div>
    </div>
    """
  end

  defp get_active_group(current_page) do
    case current_page do
      page when page in [:videos, :weekly_schedule] -> :videos
      :resources -> :resources
      page when page in [:topics, :topic_proposals] -> :topics
      page when page in [:events, :event_proposals] -> :events
      :store_items -> :store_items
      :access_codes -> :access_codes
      _ -> nil
    end
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :id, :string, required: true
  slot :inner_block, required: true

  defp nav_dropdown(assigns) do
    ~H"""
    <div class="relative group shrink-0">
      <button
        type="button"
        class={[
          "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2 flex items-center gap-1.5",
          if(@active,
            do: "text-orange-400 border-orange-400",
            else: "text-gray-400 hover:text-white border-transparent"
          )
        ]}
      >
        <.icon name={@icon} class="w-4 h-4" />
        {@label}
        <.icon name="hero-chevron-down" class="w-3 h-3 transition-transform group-hover:rotate-180" />
      </button>
      <div class="absolute left-0 top-full mt-0 w-44 bg-gray-800 border border-gray-700 rounded-lg shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-150 z-50">
        <div class="py-1">
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  attr :navigate, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp dropdown_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "block px-4 py-2 text-sm transition-colors",
        if(@active,
          do: "text-orange-400 bg-gray-700/50",
          else: "text-gray-300 hover:text-white hover:bg-gray-700/50"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end
end
