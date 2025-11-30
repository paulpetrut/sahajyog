defmodule SahajyogWeb.TopicShowLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Topics

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    topic = Topics.get_topic_by_slug!(slug)
    Topics.increment_views(topic)

    can_edit = Topics.can_edit_topic?(socket.assigns.current_scope, topic)

    {:ok,
     socket
     |> assign(:page_title, topic.title)
     |> assign(:topic, topic)
     |> assign(:can_edit, can_edit)
     |> assign(:references, Topics.list_references(topic.id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <.link
          navigate="/topics"
          class="text-info hover:text-info/80 mb-6 inline-flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-info focus:ring-offset-2 focus:ring-offset-base-300 rounded"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Topics")}
        </.link>

        <%!-- Topic Header --%>
        <.card size="lg" class="mb-4 sm:mb-6">
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
            <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-base-content flex-1">
              {@topic.title}
            </h1>
            <%= if @can_edit do %>
              <.primary_button
                navigate={~p"/topics/#{@topic.slug}/edit"}
                icon="hero-pencil-square"
                class="w-full sm:w-auto px-4 py-2 text-sm"
              >
                {gettext("Edit")}
              </.primary_button>
            <% end %>
          </div>

          <%!-- Meta Info --%>
          <div class="flex flex-wrap items-center gap-4 text-sm text-base-content/60">
            <div class="flex items-center gap-2">
              <.icon name="hero-user" class="w-4 h-4" />
              <span>{@topic.user.email}</span>
            </div>
            <%= if @topic.published_at do %>
              <div class="flex items-center gap-2">
                <.icon name="hero-calendar" class="w-4 h-4" />
                <span>{Calendar.strftime(@topic.published_at, "%B %d, %Y")}</span>
              </div>
            <% end %>
            <div class="flex items-center gap-2">
              <.icon name="hero-eye" class="w-4 h-4" />
              <span>{@topic.views_count} {gettext("views")}</span>
            </div>
          </div>

          <%!-- Co-Authors --%>
          <%= if @topic.co_authors != [] do %>
            <div class="mt-4 pt-4 border-t border-base-content/10">
              <p class="text-sm text-base-content/60 mb-2">{gettext("Co-authors")}:</p>
              <div class="flex flex-wrap gap-2">
                <span
                  :for={co_author <- Enum.filter(@topic.co_authors, &(&1.status == "accepted"))}
                  class="px-3 py-1 bg-primary/10 text-primary rounded-full text-xs border border-primary/20"
                >
                  {co_author.user.email}
                </span>
              </div>
            </div>
          <% end %>
        </.card>

        <%!-- Topic Content --%>
        <.card size="lg" class="mb-4 sm:mb-6">
          <div class="prose prose-invert prose-sm sm:prose-base lg:prose-lg max-w-none">
            <%= if @topic.content do %>
              <div class="text-base-content/80 leading-relaxed ql-content">
                {Phoenix.HTML.raw(@topic.content)}
              </div>
            <% else %>
              <p class="text-base-content/50 italic">{gettext("No content yet")}</p>
            <% end %>
          </div>
        </.card>

        <%!-- References --%>
        <%= if @references != [] do %>
          <.card size="lg">
            <h2 class="text-xl sm:text-2xl font-bold text-base-content mb-4 sm:mb-6 flex items-center gap-2">
              <.icon name="hero-book-open" class="w-5 h-5 sm:w-6 sm:h-6" />
              {gettext("References")}
            </h2>

            <div class="space-y-4">
              <div
                :for={ref <- @references}
                class="p-4 bg-base-100/50 rounded-lg border border-base-content/10 hover:border-primary/30 transition-colors"
              >
                <div class="flex items-start gap-3">
                  <div class="p-2 bg-primary/10 rounded-lg border border-primary/20">
                    <.reference_icon type={ref.reference_type} class="w-5 h-5 text-primary" />
                  </div>
                  <div class="flex-1">
                    <div class="flex items-start justify-between gap-2">
                      <h3 class="font-semibold text-base-content">{ref.title}</h3>
                      <span class="px-2 py-1 bg-base-200 text-base-content/70 rounded text-xs">
                        {ref.reference_type}
                      </span>
                    </div>
                    <%= if ref.description do %>
                      <p class="text-sm text-base-content/60 mt-2">{ref.description}</p>
                    <% end %>
                    <%= if ref.url do %>
                      <a
                        href={ref.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-sm text-primary hover:text-primary/80 mt-2 inline-flex items-center gap-1 focus:outline-none focus:ring-2 focus:ring-primary rounded"
                      >
                        {gettext("View")}
                        <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3" />
                      </a>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </.card>
        <% end %>
      </div>
    </.page_container>
    """
  end
end
