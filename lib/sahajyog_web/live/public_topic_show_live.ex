defmodule SahajyogWeb.PublicTopicShowLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Topics

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    # Note: Using get_topic_by_slug! which might raise if not found.
    # In a real app we might handle the error tuple if available.
    topic = Topics.get_topic_by_slug!(slug)

    if topic.status == "published" and topic.is_publicly_accessible do
      {:ok,
       socket
       |> assign(:topic, topic)
       |> assign(:page_title, topic.title)}
    else
      {:ok,
       socket
       |> put_flash(:error, "This topic is not publicly accessible.")
       |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-6 py-12 lg:py-20">
        <.link
          navigate={~p"/"}
          class="inline-flex items-center gap-2 text-sm text-base-content/60 hover:text-primary mb-8 transition-colors"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Home")}
        </.link>

        <article class="bg-base-100 rounded-3xl p-8 lg:p-12 shadow-sm border border-base-content/5">
          <div class="flex items-center gap-3 mb-6">
            <span class="badge badge-secondary">{gettext("Featured Topic")}</span>
            <span class="text-sm text-base-content/60">
              {Calendar.strftime(@topic.published_at || DateTime.utc_now(), "%B %d, %Y")}
            </span>
          </div>

          <h1 class="text-4xl md:text-5xl font-bold mb-8 font-serif">{@topic.title}</h1>

          <div class="prose prose-lg max-w-none prose-headings:font-serif prose-headings:font-bold">
            {raw(@topic.content)}
          </div>

          <%= if @topic.references != [] do %>
            <div class="mt-12 pt-8 border-t border-base-content/10">
              <h3 class="text-xl font-bold mb-4">{gettext("References")}</h3>
              <ul class="space-y-4">
                <%= for ref <- @topic.references do %>
                  <li class="flex items-start gap-3">
                    <div class="mt-1 p-1 bg-base-200 rounded">
                      <.icon name="hero-book-open" class="w-4 h-4 text-secondary" />
                    </div>
                    <div>
                      <div class="font-medium">{ref.title}</div>
                      <%= if ref.url do %>
                        <a href={ref.url} target="_blank" class="text-xs text-primary hover:underline">
                          {ref.url}
                        </a>
                      <% end %>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          <% end %>

          <div class="mt-12 pt-8 border-t border-base-content/10 flex flex-col items-center gap-4">
            <.link
              navigate={~p"/users/register?return_to=#{~p"/topics/#{@topic.slug}"}"}
              class="btn btn-primary btn-lg rounded-full px-8"
            >
              {gettext("Register to Access More")}
            </.link>
            <p class="text-sm text-base-content/60">
              {gettext("Already have an account?")}
              <.link
                navigate={~p"/users/log-in?return_to=#{~p"/topics/#{@topic.slug}"}"}
                class="link link-primary font-semibold"
              >
                {gettext("Log in")}
              </.link>
            </p>
          </div>
        </article>
      </div>
    </Layouts.app>
    """
  end
end
