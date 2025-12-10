defmodule SahajyogWeb.PublicEventShowLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    event = Events.get_event_by_slug!(slug)

    if event.status == "public" and event.is_publicly_accessible do
      {:ok,
       socket
       |> assign(:event, event)
       |> assign(:page_title, event.title)}
    else
      {:ok,
       socket
       |> put_flash(:error, "This event is not publicly accessible.")
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

        <div class="bg-base-100 rounded-3xl p-8 lg:p-12 shadow-sm border border-base-content/5">
          <div class="badge badge-primary mb-4">{gettext("Public Event")}</div>
          <h1 class="text-4xl md:text-5xl font-bold mb-6">{@event.title}</h1>

          <div class="flex flex-wrap gap-6 text-sm text-base-content/70 mb-8 border-b border-base-content/10 pb-8">
            <div class="flex items-start gap-3">
              <.icon name="hero-calendar" class="w-5 h-5 text-primary mt-0.5" />
              <div class="flex flex-col">
                <span class="font-medium text-base-content">{gettext("Date")}</span>
                <span>
                  {Calendar.strftime(@event.event_date, "%B %d, %Y")}
                  <%= if @event.end_date && @event.end_date != @event.event_date do %>
                    - {Calendar.strftime(@event.end_date, "%B %d, %Y")}
                  <% end %>
                </span>
              </div>
            </div>

            <%= if @event.event_time do %>
              <div class="flex items-start gap-3">
                <.icon name="hero-clock" class="w-5 h-5 text-primary mt-0.5" />
                <div class="flex flex-col">
                  <span class="font-medium text-base-content">{gettext("Time")}</span>
                  <span>
                    {Calendar.strftime(@event.event_time, "%H:%M")}
                    <%= if @event.end_time do %>
                      - {Calendar.strftime(@event.end_time, "%H:%M")}
                    <% end %>
                    <%= if @event.timezone do %>
                      <span class="text-xs text-base-content/50 ml-1">({@event.timezone})</span>
                    <% end %>
                  </span>
                </div>
              </div>
            <% end %>

            <div class="flex items-start gap-3">
              <.icon name="hero-map-pin" class="w-5 h-5 text-primary mt-0.5" />
              <div class="flex flex-col">
                <span class="font-medium text-base-content">{gettext("Location")}</span>
                <span>
                  {[@event.city, @event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                </span>
              </div>
            </div>

            <div class="flex items-start gap-3">
              <.icon name="hero-currency-dollar" class="w-5 h-5 text-primary mt-0.5" />
              <div class="flex flex-col">
                <span class="font-medium text-base-content">{gettext("Cost")}</span>
                <span class="text-success font-medium">{gettext("Free")}</span>
              </div>
            </div>

            <%= if @event.languages && @event.languages != [] do %>
              <div class="flex items-start gap-3">
                <.icon name="hero-language" class="w-5 h-5 text-primary mt-0.5" />
                <div class="flex flex-col">
                  <span class="font-medium text-base-content">{gettext("Languages")}</span>
                  <span>{@event.languages |> Enum.map(&String.upcase/1) |> Enum.join(", ")}</span>
                </div>
              </div>
            <% end %>
          </div>

          <div class="prose prose-lg max-w-none">
            <%= if @event.description do %>
              {@event.description}
            <% else %>
              <p class="italic text-base-content/60">{gettext("No description provided.")}</p>
            <% end %>
          </div>

          <div class="mt-12 pt-8 border-t border-base-content/10 flex justify-center">
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-lg rounded-full px-8">
              {gettext("Register to Join")}
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
