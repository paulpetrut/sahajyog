defmodule SahajyogWeb.Admin.EventsLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Events

  @impl true
  def mount(_params, _session, socket) do
    events = Events.list_events()

    {:ok,
     socket
     |> assign(:page_title, "Manage Events")
     |> assign(:events, events)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Events.get_event!(String.to_integer(id))
    {:ok, _} = Events.delete_event(event)

    {:noreply,
     socket
     |> assign(:events, Events.list_events())
     |> put_flash(:info, gettext("Event deleted"))}
  end

  defp status_class("draft"), do: "bg-warning/10 text-warning border border-warning/20"
  defp status_class("public"), do: "bg-success/10 text-success border border-success/20"
  defp status_class("cancelled"), do: "bg-error/10 text-error border border-error/20"

  defp status_class(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:events} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Manage Events")} />

        <%= if @events == [] do %>
          <.card>
            <.empty_state
              icon="hero-calendar"
              title={gettext("No events")}
              description={gettext("No events have been created yet")}
            />
          </.card>
        <% else %>
          <div class="space-y-4">
            <.card
              :for={event <- @events}
              hover
            >
              <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2 flex-wrap">
                    <.link
                      navigate={~p"/events/#{event.slug}"}
                      class="text-xl font-bold text-base-content hover:text-primary"
                    >
                      {event.title}
                    </.link>
                    <span class={[
                      "px-3 py-1 rounded-full text-xs font-semibold",
                      status_class(event.status)
                    ]}>
                      {event.status}
                    </span>
                  </div>

                  <div class="flex flex-wrap items-center gap-4 text-sm text-base-content/50">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      {event.user.email}
                    </span>
                    <%= if event.event_date do %>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-calendar" class="w-4 h-4" />
                        {Calendar.strftime(event.event_date, "%b %d, %Y")}
                      </span>
                    <% end %>
                    <%= if event.city || event.country do %>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-map-pin" class="w-4 h-4" />
                        {[event.city, event.country] |> Enum.reject(&is_nil/1) |> Enum.join(", ")}
                      </span>
                    <% end %>
                    <%= if event.is_online do %>
                      <span class="flex items-center gap-1 text-info">
                        <.icon name="hero-globe-alt" class="w-4 h-4" />
                        {gettext("Online")}
                      </span>
                    <% end %>
                    <%= if event.meeting_platform_link do %>
                      <span class="flex items-center gap-1 text-info">
                        <.icon name="hero-video-camera" class="w-4 h-4" />
                        {gettext("Meeting Link")}
                      </span>
                    <% end %>
                    <%= if event.presentation_video_type do %>
                      <span class="flex items-center gap-1 text-primary">
                        <.icon name="hero-play-circle" class="w-4 h-4" />
                        {String.upcase(event.presentation_video_type)}
                      </span>
                    <% end %>
                  </div>
                </div>

                <div class="flex gap-2">
                  <.link
                    navigate={~p"/events/#{event.slug}/edit"}
                    class="px-4 py-2 bg-primary text-primary-content rounded-lg hover:bg-primary/90 text-sm"
                  >
                    {gettext("Edit")}
                  </.link>
                  <.danger_button
                    phx-click="delete"
                    phx-value-id={event.id}
                    data-confirm={gettext("Are you sure you want to delete this event?")}
                    class="px-4 py-2 text-sm"
                  >
                    {gettext("Delete")}
                  </.danger_button>
                </div>
              </div>
            </.card>
          </div>
        <% end %>
      </div>
    </.page_container>
    """
  end
end
