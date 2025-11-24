defmodule SahajyogWeb.AdminNav do
  use SahajyogWeb, :html

  attr :current_page, :atom, default: nil

  def admin_nav(assigns) do
    ~H"""
    <div class="bg-gray-800/50 border-b border-gray-700 mb-8">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <nav class="flex gap-1 overflow-x-auto">
          <.link
            navigate={~p"/admin/videos"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2",
              if(@current_page == :videos,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-video-camera" class="w-4 h-4 inline mr-1" />
            {gettext("Videos")}
          </.link>

          <.link
            navigate={~p"/admin/resources"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2",
              if(@current_page == :resources,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-folder" class="w-4 h-4 inline mr-1" />
            {gettext("Resources")}
          </.link>

          <.link
            navigate={~p"/admin/topics"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2",
              if(@current_page == :topics,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-document-text" class="w-4 h-4 inline mr-1" />
            {gettext("Topics")}
          </.link>

          <.link
            navigate={~p"/admin/topic-proposals"}
            class={[
              "px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors border-b-2",
              if(@current_page == :topic_proposals,
                do: "text-orange-400 border-orange-400",
                else: "text-gray-400 hover:text-white border-transparent"
              )
            ]}
          >
            <.icon name="hero-light-bulb" class="w-4 h-4 inline mr-1" />
            {gettext("Proposals")}
          </.link>
        </nav>
      </div>
    </div>
    """
  end
end
