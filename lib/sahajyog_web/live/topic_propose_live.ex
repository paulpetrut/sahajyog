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
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <%!-- Back Button --%>
        <.link
          navigate="/topics"
          class="text-blue-400 hover:text-blue-300 mb-6 inline-flex items-center gap-2"
        >
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          {gettext("Back to Topics")}
        </.link>

        <%!-- Form --%>
        <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-4 sm:p-6 lg:p-8 border border-gray-700/50">
          <div class="mb-4 sm:mb-6">
            <h1 class="text-2xl sm:text-3xl font-bold text-white mb-2">
              {gettext("Propose a New Topic")}
            </h1>
            <p class="text-sm sm:text-base text-gray-400">
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
                <button
                  type="submit"
                  class="w-full sm:w-auto px-6 py-3 bg-purple-700 text-white rounded-lg hover:bg-purple-800 transition-colors font-semibold"
                >
                  {gettext("Submit Proposal")}
                </button>
                <.link
                  navigate="/topics"
                  class="w-full sm:w-auto px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold text-center"
                >
                  {gettext("Cancel")}
                </.link>
              </div>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
