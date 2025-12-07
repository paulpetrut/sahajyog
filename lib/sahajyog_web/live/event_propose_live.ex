defmodule SahajyogWeb.EventProposeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Events

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    if !Sahajyog.Accounts.User.profile_complete?(user) do
      encoded_return = URI.encode_www_form(~p"/events/propose")

      {:ok,
       socket
       |> put_flash(
         :error,
         gettext(
           "Please complete your profile (First Name, Last Name, Phone Number) before proposing an event."
         )
       )
       |> push_navigate(to: ~p"/users/settings?return_to=#{encoded_return}")}
    else
      proposal = %Sahajyog.Events.EventProposal{}
      changeset = Events.change_proposal(proposal)

      {:ok,
       socket
       |> assign(:page_title, "Propose Event")
       |> assign(:proposal, proposal)
       |> assign(:form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate", %{"event_proposal" => proposal_params}, socket) do
    changeset =
      socket.assigns.proposal
      |> Events.change_proposal(proposal_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"event_proposal" => proposal_params}, socket) do
    case Events.create_proposal(socket.assigns.current_scope, proposal_params) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Event proposal submitted successfully! An admin will review it shortly.")
         )
         |> push_navigate(to: ~p"/events")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_container>
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <Layouts.events_nav current_page={:propose} />

        <%!-- Form --%>
        <.card size="lg">
          <div class="mb-4 sm:mb-6">
            <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
              {gettext("Propose a New Event")}
            </h1>
            <p class="text-sm sm:text-base text-base-content/60">
              {gettext("Suggest an event for the community. An admin will review and approve it.")}
            </p>
          </div>

          <.form for={@form} id="proposal-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input
                  field={@form[:title]}
                  type="text"
                  label={gettext("Event Title")}
                  placeholder={gettext("e.g., Summer Meditation Retreat 2024")}
                  required
                />
              </div>

              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  placeholder={
                    gettext("Describe the event, its purpose, and what participants can expect...")
                  }
                  rows="6"
                />
              </div>

              <% is_online = Ecto.Changeset.get_field(@form.source, :is_online) || false %>

              <div class="flex items-center gap-2 pb-2">
                <.input
                  field={@form[:is_online]}
                  type="checkbox"
                  label={gettext("This is an Online Event")}
                />
              </div>

              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <.input
                    field={@form[:event_date]}
                    type="date"
                    label={gettext("Event Date")}
                    required
                  />
                </div>
                <div>
                  <.input
                    field={@form[:start_time]}
                    type="time"
                    label={gettext("Start Time")}
                    required
                  />
                </div>
              </div>

              <%= if is_online do %>
                <div>
                  <.input
                    field={@form[:online_url]}
                    type="text"
                    label={gettext("Online Link (YouTube)")}
                    placeholder="https://youtube.com/..."
                    required
                  />
                </div>
              <% else %>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:budget_type]}
                      type="select"
                      label={gettext("Budget Type")}
                      options={[
                        {gettext("Donations"), "open_for_donations"},
                        {gettext("Fixed Budget"), "fixed_budget"}
                      ]}
                      required
                    />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <.input
                      field={@form[:city]}
                      type="text"
                      label={gettext("City")}
                      placeholder={gettext("e.g., Rome")}
                      required
                    />
                  </div>
                  <div>
                    <.input
                      field={@form[:country]}
                      type="text"
                      label={gettext("Country")}
                      placeholder={gettext("e.g., Italy")}
                      required
                    />
                  </div>
                </div>
              <% end %>

              <div class="bg-info/10 border border-info/20 rounded-lg p-4">
                <div class="flex items-start gap-3">
                  <.icon name="hero-information-circle" class="w-5 h-5 text-info mt-0.5" />
                  <div class="text-sm text-base-content/70">
                    <p class="font-medium text-base-content mb-1">{gettext("What happens next?")}</p>
                    <ul class="list-disc list-inside space-y-1">
                      <li>{gettext("Your proposal will be reviewed by an admin")}</li>
                      <li>{gettext("If approved, you'll be able to add full event details")}</li>
                      <li>{gettext("You can manage team members, transportation, and more")}</li>
                    </ul>
                  </div>
                </div>
              </div>

              <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-4">
                <.primary_button type="submit" class="w-full sm:w-auto">
                  {gettext("Submit Proposal")}
                </.primary_button>
                <.secondary_button navigate="/events" class="w-full sm:w-auto">
                  {gettext("Cancel")}
                </.secondary_button>
              </div>
            </div>
          </.form>
        </.card>
      </div>
    </.page_container>
    """
  end
end
