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
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <.link
          navigate="/topics"
          class="text-blue-400 hover:text-blue-300 mb-6 inline-flex items-center gap-2"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Topics")}
        </.link>

        <%!-- Topic Header --%>
        <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50 mb-4 sm:mb-6">
          <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
            <h1 class="text-2xl sm:text-3xl lg:text-4xl font-bold text-white flex-1">
              {@topic.title}
            </h1>
            <%= if @can_edit do %>
              <.link
                navigate={~p"/topics/#{@topic.slug}/edit"}
                class="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold text-center"
              >
                {gettext("Edit")}
              </.link>
            <% end %>
          </div>

          <%!-- Meta Info --%>
          <div class="flex flex-wrap items-center gap-4 text-sm text-gray-400">
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
            <div class="mt-4 pt-4 border-t border-gray-700/50">
              <p class="text-sm text-gray-400 mb-2">{gettext("Co-authors")}:</p>
              <div class="flex flex-wrap gap-2">
                <span
                  :for={co_author <- Enum.filter(@topic.co_authors, &(&1.status == "accepted"))}
                  class="px-3 py-1 bg-blue-500/10 text-blue-400 rounded-full text-xs border border-blue-500/20"
                >
                  {co_author.user.email}
                </span>
              </div>
            </div>
          <% end %>
        </div>

        <%!-- Topic Content --%>
        <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50 mb-4 sm:mb-6">
          <div class="prose prose-invert prose-sm sm:prose-base lg:prose-lg max-w-none">
            <%= if @topic.content do %>
              <div class="text-gray-300 leading-relaxed ql-editor">
                {Phoenix.HTML.raw(@topic.content)}
              </div>
            <% else %>
              <p class="text-gray-500 italic">{gettext("No content yet")}</p>
            <% end %>
          </div>
        </div>

        <%!-- References --%>
        <%= if @references != [] do %>
          <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50">
            <h2 class="text-xl sm:text-2xl font-bold text-white mb-4 sm:mb-6 flex items-center gap-2">
              <.icon name="hero-book-open" class="w-5 h-5 sm:w-6 sm:h-6" />
              {gettext("References")}
            </h2>

            <div class="space-y-4">
              <div
                :for={ref <- @references}
                class="p-4 bg-gray-700/30 rounded-lg border border-gray-700/50 hover:border-blue-500/30 transition-colors"
              >
                <div class="flex items-start gap-3">
                  <div class="p-2 bg-blue-500/10 rounded-lg border border-blue-500/20">
                    <.icon name={reference_icon(ref.reference_type)} class="w-5 h-5 text-blue-400" />
                  </div>
                  <div class="flex-1">
                    <div class="flex items-start justify-between gap-2">
                      <h3 class="font-semibold text-white">{ref.title}</h3>
                      <span class="px-2 py-1 bg-gray-700 text-gray-300 rounded text-xs">
                        {ref.reference_type}
                      </span>
                    </div>
                    <%= if ref.description do %>
                      <p class="text-sm text-gray-400 mt-2">{ref.description}</p>
                    <% end %>
                    <%= if ref.url do %>
                      <a
                        href={ref.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-sm text-blue-400 hover:text-blue-300 mt-2 inline-flex items-center gap-1"
                      >
                        {gettext("View")}
                        <.icon name="hero-arrow-top-right-on-square" class="w-3 h-3" />
                      </a>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp reference_icon("book"), do: "hero-book-open"
  defp reference_icon("talk"), do: "hero-microphone"
  defp reference_icon("video"), do: "hero-video-camera"
  defp reference_icon("article"), do: "hero-document-text"
  defp reference_icon("website"), do: "hero-globe-alt"
  defp reference_icon(_), do: "hero-link"
end
