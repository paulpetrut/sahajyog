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
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Header --%>
        <div class="mb-6 sm:mb-8">
          <div class="flex flex-col gap-4">
            <div class="text-center sm:text-left">
              <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-white mb-2">
                {gettext("Topics")}
              </h1>
              <p class="text-base sm:text-lg text-gray-300">
                {gettext("Explore in-depth articles on Sahaja Yoga")}
              </p>
            </div>
            <.link
              navigate="/topics/propose"
              class="w-full sm:w-auto sm:self-start px-6 sm:px-8 py-3 bg-purple-700 text-white rounded-lg hover:bg-purple-800 transition-colors font-semibold inline-flex items-center justify-center gap-2"
            >
              <span>{gettext("Propose Topic")}</span>
              <.icon name="hero-light-bulb" class="w-5 h-5" />
            </.link>
          </div>
        </div>

        <%!-- Topics Grid --%>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 sm:gap-6">
          <div
            :for={topic <- @topics}
            class="group bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl overflow-hidden border border-gray-700/50 hover:border-blue-500/50 transition-all duration-300 hover:shadow-2xl hover:shadow-blue-500/10 sm:hover:-translate-y-1"
          >
            <.link navigate={~p"/topics/#{topic.slug}"} class="block">
              <div class="p-4 sm:p-6">
                <%!-- Title --%>
                <h3 class="text-lg sm:text-xl font-bold text-white mb-3 line-clamp-2 group-hover:text-blue-400 transition-colors">
                  {topic.title}
                </h3>

                <%!-- Content Preview --%>
                <%= if topic.content do %>
                  <p class="text-gray-400 text-sm mb-4 line-clamp-3">
                    {String.slice(topic.content, 0, 150)}...
                  </p>
                <% end %>

                <%!-- Status Badge --%>
                <%= if topic.status != "published" do %>
                  <div class="mb-3">
                    <span class={[
                      "px-3 py-1 rounded-full text-xs font-semibold inline-flex items-center gap-1",
                      topic.status == "draft" &&
                        "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20",
                      topic.status == "archived" &&
                        "bg-gray-500/10 text-gray-400 border border-gray-500/20"
                    ]}>
                      <.icon name="hero-pencil" class="w-3 h-3" />
                      {String.capitalize(topic.status)}
                    </span>
                  </div>
                <% end %>

                <%!-- Meta Info --%>
                <div class="flex items-center justify-between text-xs text-gray-500 pt-4 border-t border-gray-700/50">
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
          </div>
        </div>

        <%!-- Empty State --%>
        <%= if @topics == [] do %>
          <div class="text-center py-16">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gray-800 border border-gray-700 mb-4">
              <.icon name="hero-document-text" class="w-10 h-10 text-gray-600" />
            </div>
            <h3 class="text-xl font-semibold text-gray-300 mb-2">
              {gettext("No topics yet")}
            </h3>
            <p class="text-gray-500">
              {gettext("Be the first to propose a topic")}
            </p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
