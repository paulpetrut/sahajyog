defmodule SahajyogWeb.TopicsLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Topics

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    topics = Topics.list_topics_for_user(user_id)

    {:ok,
     socket
     |> assign(:page_title, "Topics")
     |> assign(:topics, topics)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8 relative">
          <div class="text-center">
            <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-base-content mb-3">
              {gettext("Topics")}
            </h1>
            <p class="text-base sm:text-lg text-base-content/70">
              {gettext("Explore in-depth articles on Sahaja Yoga")}
            </p>
          </div>
          <div class="absolute right-0 top-0 hidden sm:block">
            <.primary_button navigate="/topics/propose" icon="hero-light-bulb">
              {gettext("Propose Topic")}
            </.primary_button>
          </div>
          <div class="mt-4 flex justify-center sm:hidden">
            <.primary_button navigate="/topics/propose" icon="hero-light-bulb">
              {gettext("Propose Topic")}
            </.primary_button>
          </div>
        </div>

        <%!-- Topics Grid --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <.card
            :for={topic <- @topics}
            hover
            class="group overflow-hidden sm:hover:-translate-y-1"
          >
            <.link navigate={~p"/topics/#{topic.slug}"} class="block">
              <div class="p-4 sm:p-6">
                <%!-- Title --%>
                <h3 class="text-lg sm:text-xl font-bold text-base-content mb-3 line-clamp-2 group-hover:text-primary transition-colors">
                  {topic.title}
                </h3>

                <%!-- Content Preview --%>
                <%= if topic.content do %>
                  <p class="text-base-content/60 text-sm mb-4 line-clamp-3">
                    {strip_html_tags(topic.content) |> truncate_text(150)}
                  </p>
                <% end %>

                <%!-- Status Badge --%>
                <%= if topic.status != "published" do %>
                  <div class="mb-3">
                    <.status_badge status={topic.status} />
                  </div>
                <% end %>

                <%!-- Meta Info --%>
                <div class="flex items-center justify-between text-xs text-base-content/50 pt-4 border-t border-base-content/10">
                  <div class="flex items-center gap-2">
                    <.icon name="hero-user" class="w-4 h-4" />
                    <span>{topic.user.email}</span>
                  </div>
                  <div class="flex items-center gap-3">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-eye" class="w-4 h-4" />
                      {topic.views_count}
                    </span>
                    <%= if topic.published_at do %>
                      <span>
                        {Calendar.strftime(topic.published_at, "%b %d, %Y")}
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            </.link>
          </.card>
        </div>

        <%!-- Empty State --%>
        <%= if @topics == [] do %>
          <.empty_state
            icon="hero-document-text"
            title={gettext("No topics yet")}
            description={gettext("Be the first to propose a topic")}
          >
            <:actions>
              <.primary_button navigate="/topics/propose" icon="hero-light-bulb">
                {gettext("Propose Topic")}
              </.primary_button>
            </:actions>
          </.empty_state>
        <% end %>
      </div>
    </.page_container>
    """
  end
end
