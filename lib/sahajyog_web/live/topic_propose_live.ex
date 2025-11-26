defmodule SahajyogWeb.TopicProposeLive do
  use SahajyogWeb, :live_view

  alias Sahajyog.Topics

  @impl true
  def mount(_params, _session, socket) do
    proposal = %Sahajyog.Topics.TopicProposal{}
    changeset = Topics.change_proposal(proposal)

    {:ok,
     socket
     |> assign(:page_title, "Propose Topic")
     |> assign(:proposal, proposal)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"topic_proposal" => proposal_params}, socket) do
    changeset =
      socket.assigns.proposal
      |> Topics.change_proposal(proposal_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"topic_proposal" => proposal_params}, socket) do
    case Topics.create_proposal(socket.assigns.current_scope, proposal_params) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Topic proposal submitted successfully"))
         |> push_navigate(to: ~p"/topics")}

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
        <.link
          navigate="/topics"
          class="text-info hover:text-info/80 mb-6 inline-flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-info focus:ring-offset-2 focus:ring-offset-base-300 rounded"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Topics")}
        </.link>

        <%!-- Form --%>
        <.card size="lg">
          <div class="mb-4 sm:mb-6">
            <h1 class="text-2xl sm:text-3xl font-bold text-base-content mb-2">
              {gettext("Propose a New Topic")}
            </h1>
            <p class="text-sm sm:text-base text-base-content/60">
              {gettext("Suggest a topic for the community. An admin will review and approve it.")}
            </p>
          </div>

          <.form for={@form} id="proposal-form" phx-change="validate" phx-submit="save">
            <div class="space-y-6">
              <div>
                <.input
                  field={@form[:title]}
                  type="text"
                  label={gettext("Topic Title")}
                  placeholder={gettext("e.g., Understanding the Chakras")}
                  required
                />
              </div>

              <div>
                <.input
                  field={@form[:description]}
                  type="textarea"
                  label={gettext("Description")}
                  placeholder={gettext("Briefly describe what this topic should cover...")}
                  rows="6"
                />
              </div>

              <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-4">
                <.primary_button type="submit" class="w-full sm:w-auto">
                  {gettext("Submit Proposal")}
                </.primary_button>
                <.secondary_button navigate="/topics" class="w-full sm:w-auto">
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
