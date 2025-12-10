defmodule SahajyogWeb.Admin.EventProposalsLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Events
  alias Sahajyog.Events.Event

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Event Proposals")
     |> assign(:filter, "pending")
     |> assign(:proposals, Events.list_proposals(%{status: "pending"}))
     |> assign(:reviewing_proposal, nil)
     |> assign(:review_form, nil)}
  end

  @impl true
  def handle_event("set_filter", %{"filter" => filter}, socket) do
    proposals =
      case filter do
        "pending" -> Events.list_proposals(%{status: "pending"})
        _ -> Events.list_proposals()
      end

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:proposals, proposals)}
  end

  @impl true
  def handle_event("review", %{"id" => id}, socket) do
    proposal = Events.get_proposal!(String.to_integer(id))

    event =
      struct(Event, %{
        title: proposal.title,
        description: proposal.description,
        event_date: proposal.event_date,
        event_time: proposal.start_time,
        is_online: proposal.is_online,
        online_url: proposal.online_url,
        city: proposal.city,
        country: proposal.country,
        budget_type: proposal.budget_type,
        meeting_platform_link: proposal.meeting_platform_link,
        presentation_video_type: proposal.presentation_video_type,
        presentation_video_url: proposal.presentation_video_url
      })

    changeset = Events.change_event(event)

    {:noreply,
     socket
     |> assign(:reviewing_proposal, proposal)
     |> assign(:review_form, to_form(changeset))}
  end

  @impl true
  def handle_event("cancel_review", _, socket) do
    {:noreply,
     socket
     |> assign(:reviewing_proposal, nil)
     |> assign(:review_form, nil)}
  end

  @impl true
  def handle_event("validate_event", params, socket) do
    event_params = params["event"]

    if is_nil(event_params) do
      {:noreply, socket}
    else
      # Check scope
      current_scope = socket.assigns[:current_scope]

      user_id = if current_scope && current_scope.user, do: current_scope.user.id, else: nil

      proposal = socket.assigns.reviewing_proposal

      event =
        struct(Event, %{
          title: proposal.title,
          description: proposal.description,
          event_date: proposal.event_date,
          event_time: proposal.start_time,
          is_online: proposal.is_online,
          online_url: proposal.online_url,
          city: proposal.city,
          country: proposal.country,
          budget_type: proposal.budget_type,
          user_id: user_id,
          meeting_platform_link: proposal.meeting_platform_link,
          presentation_video_type: proposal.presentation_video_type,
          presentation_video_url: proposal.presentation_video_url
        })

      changeset =
        event
        |> Events.change_event(event_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :review_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("approve", %{"event" => event_params}, socket) do
    case socket.assigns.reviewing_proposal do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("No proposal selected for approval."))}

      proposal ->
        case Events.approve_proposal(socket.assigns.current_scope, proposal, event_params) do
          {:ok, {_event, _proposal}} ->
            {:noreply,
             socket
             |> assign(:proposals, Events.list_proposals())
             |> assign(:reviewing_proposal, nil)
             |> assign(:review_form, nil)
             |> put_flash(
               :info,
               gettext(
                 "Proposal approved! Event created as draft for %{email}",
                 email: proposal.proposed_by.email
               )
             )}

          {:error, changeset} ->
            {:noreply, assign(socket, :review_form, to_form(changeset))}
        end
    end
  end

  @impl true
  def handle_event("reject", %{"id" => id, "notes" => notes}, socket) do
    proposal = Events.get_proposal!(String.to_integer(id))

    case Events.reject_proposal(socket.assigns.current_scope, proposal, notes) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> assign(:proposals, Events.list_proposals())
         |> put_flash(:info, gettext("Proposal rejected"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to reject proposal"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    proposal = Events.get_proposal!(String.to_integer(id))
    {:ok, _} = Events.delete_proposal(proposal)

    {:noreply,
     socket
     |> assign(:proposals, Events.list_proposals())
     |> put_flash(:info, gettext("Proposal deleted"))}
  end

  defp proposal_status_class("pending"), do: "bg-warning/10 text-warning border border-warning/20"

  defp proposal_status_class("approved"),
    do: "bg-success/10 text-success border border-success/20"

  defp proposal_status_class("rejected"), do: "bg-error/10 text-error border border-error/20"

  defp proposal_status_class(_),
    do: "bg-base-content/10 text-base-content/60 border border-base-content/20"

  defp proposal_border_class("pending"), do: "border-warning/30"
  defp proposal_border_class("approved"), do: "border-success/30"
  defp proposal_border_class("rejected"), do: "border-error/30"
  defp proposal_border_class(_), do: "border-base-content/20"

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <.admin_nav current_page={:event_proposals} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Event Proposals")} />

        <%!-- Filter Tabs --%>
        <div class="flex gap-2 mb-6 border-b border-base-content/10">
          <button
            phx-click="set_filter"
            phx-value-filter="pending"
            class={[
              "px-4 py-2 text-sm font-medium border-b-2 transition-colors",
              @filter == "pending" && "border-primary text-primary",
              @filter != "pending" &&
                "border-transparent text-base-content/60 hover:text-base-content"
            ]}
          >
            {gettext("Inbox")}
            <span class={[
              "ml-2 px-1.5 py-0.5 rounded-full text-xs",
              @filter == "pending" && "bg-primary/10 text-primary",
              @filter != "pending" && "bg-base-content/10 text-base-content/60"
            ]}>
              {Enum.count(@proposals, &(&1.status == "pending"))}
            </span>
          </button>
          <button
            phx-click="set_filter"
            phx-value-filter="all"
            class={[
              "px-4 py-2 text-sm font-medium border-b-2 transition-colors",
              @filter == "all" && "border-primary text-primary",
              @filter != "all" && "border-transparent text-base-content/60 hover:text-base-content"
            ]}
          >
            {gettext("History")}
          </button>
        </div>

        <%!-- Review Modal --%>
        <.modal
          :if={@reviewing_proposal}
          id="review-modal"
          on_close="cancel_review"
          size="lg"
        >
          <:title>{gettext("Review Event Proposal")}</:title>

          <div class="mb-6 p-4 bg-base-100/50 rounded-lg border border-base-content/10">
            <h3 class="font-semibold text-base-content mb-2">{@reviewing_proposal.title}</h3>
            <p class="text-base-content/60 text-sm mb-3">{@reviewing_proposal.description}</p>
            <div class="flex flex-wrap gap-4 text-xs text-base-content/50">
              <span>{gettext("Proposed by")}: {@reviewing_proposal.proposed_by.email}</span>
              <%= if @reviewing_proposal.event_date do %>
                <span>
                  {gettext("Date")}: {Calendar.strftime(@reviewing_proposal.event_date, "%b %d, %Y")}
                </span>
              <% end %>
              <%= if @reviewing_proposal.city || @reviewing_proposal.country do %>
                <span>
                  {gettext("Location")}: {[@reviewing_proposal.city, @reviewing_proposal.country]
                  |> Enum.reject(&is_nil/1)
                  |> Enum.join(", ")}
                </span>
              <% end %>
            </div>

            <%!-- Meeting Platform Link (for online events) --%>
            <%= if @reviewing_proposal.is_online && @reviewing_proposal.meeting_platform_link do %>
              <div class="mt-3 p-3 bg-info/10 rounded-lg border border-info/20">
                <div class="flex items-center gap-2 text-sm">
                  <.icon name="hero-video-camera" class="w-4 h-4 text-info" />
                  <span class="font-medium text-info">{gettext("Meeting Link")}:</span>
                  <a
                    href={@reviewing_proposal.meeting_platform_link}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-info hover:underline truncate max-w-xs"
                  >
                    {@reviewing_proposal.meeting_platform_link}
                  </a>
                </div>
              </div>
            <% end %>

            <%!-- Presentation Video Information --%>
            <%= if @reviewing_proposal.presentation_video_type do %>
              <div class="mt-3 p-3 bg-primary/10 rounded-lg border border-primary/20">
                <div class="flex items-center gap-2 text-sm">
                  <.icon name="hero-play-circle" class="w-4 h-4 text-primary" />
                  <span class="font-medium text-primary">{gettext("Presentation Video")}:</span>
                  <span class="px-2 py-0.5 bg-primary/20 text-primary rounded text-xs uppercase">
                    {@reviewing_proposal.presentation_video_type}
                  </span>
                </div>
                <%= if @reviewing_proposal.presentation_video_type == "youtube" do %>
                  <a
                    href={@reviewing_proposal.presentation_video_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-primary hover:underline text-sm mt-1 block truncate"
                  >
                    {@reviewing_proposal.presentation_video_url}
                  </a>
                <% else %>
                  <p class="text-sm text-base-content/60 mt-1">
                    {gettext("R2 Storage")}: {@reviewing_proposal.presentation_video_url}
                  </p>
                <% end %>
              </div>
            <% end %>
          </div>

          <.form
            for={@review_form}
            id="review-form"
            phx-change="validate_event"
            phx-submit="approve"
          >
            <div class="space-y-4">
              <div>
                <.input
                  field={@review_form[:title]}
                  type="text"
                  label={gettext("Title")}
                  required
                />
              </div>

              <div>
                <.input
                  field={@review_form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  rows="4"
                />
              </div>

              <div class="flex items-center gap-2 pb-4">
                <.input
                  field={@review_form[:is_online]}
                  type="checkbox"
                  label={gettext("Is Online Event")}
                />
              </div>

              <% is_online = Ecto.Changeset.get_field(@review_form.source, :is_online) || false %>

              <%= if is_online do %>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@review_form[:event_time]}
                      type="time"
                      label={gettext("Start Time")}
                    />
                  </div>
                </div>

                <div class="bg-base-200/50 border border-base-content/10 rounded-lg p-4 mt-4">
                  <p class="text-sm text-base-content/70 mb-3">
                    {gettext("Provide at least one: a YouTube link OR a meeting platform link")}
                  </p>
                  <div class="space-y-4">
                    <div>
                      <.input
                        field={@review_form[:online_url]}
                        type="text"
                        label={gettext("YouTube Link")}
                        placeholder="https://youtube.com/..."
                      />
                    </div>
                    <div>
                      <.input
                        field={@review_form[:meeting_platform_link]}
                        type="text"
                        label={gettext("Meeting Platform Link")}
                        placeholder={
                          gettext("https://teams.microsoft.com/... or https://zoom.us/...")
                        }
                      />
                      <p class="mt-1 text-xs text-base-content/60">
                        {gettext("Teams, Zoom, Google Meet, etc.")}
                      </p>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@review_form[:city]}
                      type="text"
                      label={gettext("City")}
                    />
                  </div>
                  <div>
                    <.input
                      field={@review_form[:country]}
                      type="text"
                      label={gettext("Country")}
                    />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@review_form[:event_date]}
                      type="date"
                      label={gettext("Event Date")}
                    />
                  </div>
                  <div>
                    <.input
                      field={@review_form[:event_time]}
                      type="time"
                      label={gettext("Start Time")}
                    />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@review_form[:budget_type]}
                      type="select"
                      label={gettext("Budget Type")}
                      options={[
                        {gettext("Donations"), "open_for_donations"},
                        {gettext("Fixed Budget"), "fixed_budget"}
                      ]}
                      required
                    />
                  </div>
                  <div>
                    <.input
                      field={@review_form[:status]}
                      type="select"
                      label={gettext("Status")}
                      options={Event.statuses()}
                      required
                    />
                  </div>
                </div>
              <% end %>

              <%!-- Common fields that might be needed or kept outside --%>
              <%= if is_online do %>
                <div class="grid grid-cols-2 gap-4 mt-4">
                  <div>
                    <.input
                      field={@review_form[:event_date]}
                      type="date"
                      label={gettext("Event Date")}
                    />
                  </div>
                  <div>
                    <.input
                      field={@review_form[:status]}
                      type="select"
                      label={gettext("Status")}
                      options={Event.statuses()}
                      required
                    />
                  </div>
                </div>
              <% end %>

              <div class="flex gap-3 pt-4">
                <button
                  type="submit"
                  class="px-6 py-3 bg-success text-success-content rounded-lg hover:bg-success/90 transition-colors font-semibold focus:outline-none focus:ring-2 focus:ring-success focus:ring-offset-2 focus:ring-offset-base-300"
                >
                  {gettext("Approve & Create Event")}
                </button>
                <.secondary_button type="button" phx-click="cancel_review">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.form>
        </.modal>

        <%!-- Proposals List --%>
        <%= if @proposals == [] do %>
          <.card>
            <.empty_state
              icon="hero-calendar"
              title={gettext("No proposals")}
              description={gettext("No event proposals to review")}
            />
          </.card>
        <% else %>
          <div class="space-y-4">
            <.card
              :for={proposal <- @proposals}
              class={["border", proposal_border_class(proposal.status)]}
            >
              <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2 flex-wrap">
                    <h3 class="text-xl font-bold text-base-content">{proposal.title}</h3>
                    <span class={[
                      "px-3 py-1 rounded-full text-xs font-semibold",
                      proposal_status_class(proposal.status)
                    ]}>
                      {proposal.status}
                    </span>
                  </div>

                  <%= if proposal.description do %>
                    <p class="text-base-content/60 mb-3">{proposal.description}</p>
                  <% end %>

                  <div class="flex flex-wrap items-center gap-4 text-sm text-base-content/50">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      {proposal.proposed_by.email}
                    </span>
                    <%= if proposal.event_date do %>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-calendar" class="w-4 h-4" />
                        {Calendar.strftime(proposal.event_date, "%b %d, %Y")}
                      </span>
                    <% end %>
                    <%= if proposal.city || proposal.country do %>
                      <span class="flex items-center gap-1">
                        <.icon name="hero-map-pin" class="w-4 h-4" />
                        {[proposal.city, proposal.country]
                        |> Enum.reject(&is_nil/1)
                        |> Enum.join(", ")}
                      </span>
                    <% end %>
                    <%= if proposal.is_online && proposal.meeting_platform_link do %>
                      <span class="flex items-center gap-1 text-info">
                        <.icon name="hero-video-camera" class="w-4 h-4" />
                        {gettext("Meeting Link")}
                      </span>
                    <% end %>
                    <%= if proposal.presentation_video_type do %>
                      <span class="flex items-center gap-1 text-primary">
                        <.icon name="hero-play-circle" class="w-4 h-4" />
                        {String.upcase(proposal.presentation_video_type)}
                      </span>
                    <% end %>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-clock" class="w-4 h-4" />
                      {Calendar.strftime(proposal.inserted_at, "%b %d, %Y")}
                    </span>
                  </div>

                  <%= if proposal.review_notes do %>
                    <div class="mt-3 p-3 bg-base-100/50 rounded-lg border border-base-content/10">
                      <p class="text-sm text-base-content/60">
                        <span class="font-semibold text-base-content/80">
                          {gettext("Review notes")}:
                        </span>
                        {proposal.review_notes}
                      </p>
                    </div>
                  <% end %>
                </div>

                <div class="flex flex-row sm:flex-col gap-2 w-full sm:w-auto">
                  <%= if proposal.status == "pending" do %>
                    <.primary_button
                      phx-click="review"
                      phx-value-id={proposal.id}
                      class="flex-1 sm:flex-none px-4 py-2 text-sm"
                    >
                      {gettext("Review")}
                    </.primary_button>
                  <% end %>
                  <.danger_button
                    phx-click="delete"
                    phx-value-id={proposal.id}
                    data-confirm={gettext("Are you sure?")}
                    class="flex-1 sm:flex-none px-4 py-2 text-sm"
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
