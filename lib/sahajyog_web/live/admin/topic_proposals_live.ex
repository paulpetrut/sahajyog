defmodule SahajyogWeb.Admin.TopicProposalsLive do
  use SahajyogWeb, :live_view

  import SahajyogWeb.AdminNav

  alias Sahajyog.Topics
  alias Sahajyog.Topics.Topic

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Topic Proposals")
     |> assign(:proposals, Topics.list_proposals())
     |> assign(:reviewing_proposal, nil)
     |> assign(:review_form, nil)}
  end

  @impl true
  def handle_event("review", %{"id" => id}, socket) do
    proposal = Topics.get_proposal!(String.to_integer(id))
    topic = %Topic{title: proposal.title, content: proposal.description}
    changeset = Topics.change_topic(topic)

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
  def handle_event("validate_topic", %{"topic" => topic_params}, socket) do
    topic = %Topic{title: socket.assigns.reviewing_proposal.title}

    changeset =
      topic
      |> Topics.change_topic(topic_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :review_form, to_form(changeset))}
  end

  @impl true
  def handle_event("approve", %{"topic" => topic_params}, socket) do
    proposal = socket.assigns.reviewing_proposal

    case Topics.approve_proposal(socket.assigns.current_scope, proposal, topic_params) do
      {:ok, {_topic, _proposal}} ->
        {:noreply,
         socket
         |> assign(:proposals, Topics.list_proposals())
         |> assign(:reviewing_proposal, nil)
         |> assign(:review_form, nil)
         |> put_flash(
           :info,
           gettext(
             "Proposal approved! Topic created as draft for %{email}",
             email: proposal.proposed_by.email
           )
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :review_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("reject", %{"id" => id, "notes" => notes}, socket) do
    proposal = Topics.get_proposal!(String.to_integer(id))

    case Topics.reject_proposal(socket.assigns.current_scope, proposal, notes) do
      {:ok, _proposal} ->
        {:noreply,
         socket
         |> assign(:proposals, Topics.list_proposals())
         |> put_flash(:info, gettext("Proposal rejected"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to reject proposal"))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    proposal = Topics.get_proposal!(String.to_integer(id))
    {:ok, _} = Topics.delete_proposal(proposal)

    {:noreply,
     socket
     |> assign(:proposals, Topics.list_proposals())
     |> put_flash(:info, gettext("Proposal deleted"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900">
      <.admin_nav current_page={:topic_proposals} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <h1 class="text-3xl sm:text-4xl font-bold text-white mb-8">
          {gettext("Topic Proposals")}
        </h1>

        <%!-- Review Modal --%>
        <%= if @reviewing_proposal do %>
          <div class="fixed inset-0 bg-black/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div class="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl max-w-3xl w-full max-h-[90vh] overflow-auto border border-gray-700/50 shadow-2xl">
              <div class="p-6">
                <div class="flex items-center justify-between mb-6">
                  <h2 class="text-2xl font-bold text-white">
                    {gettext("Review Proposal")}
                  </h2>
                  <button
                    phx-click="cancel_review"
                    class="p-2 text-gray-400 hover:text-white hover:bg-gray-700 rounded-lg transition-all"
                  >
                    <.icon name="hero-x-mark" class="w-6 h-6" />
                  </button>
                </div>

                <div class="mb-6 p-4 bg-gray-700/30 rounded-lg border border-gray-700/50">
                  <h3 class="font-semibold text-white mb-2">{@reviewing_proposal.title}</h3>
                  <p class="text-gray-400 text-sm mb-3">{@reviewing_proposal.description}</p>
                  <p class="text-xs text-gray-500">
                    {gettext("Proposed by")}: {@reviewing_proposal.proposed_by.email}
                  </p>
                </div>

                <.form
                  for={@review_form}
                  id="review-form"
                  phx-change="validate_topic"
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
                        field={@review_form[:content]}
                        type="textarea"
                        label={gettext("Initial Content")}
                        rows="8"
                        placeholder={gettext("Add initial content or leave empty...")}
                      />
                    </div>

                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <.input
                          field={@review_form[:status]}
                          type="select"
                          label={gettext("Status")}
                          options={Topic.statuses()}
                          required
                        />
                      </div>
                      <div>
                        <.input
                          field={@review_form[:language]}
                          type="select"
                          label={gettext("Language")}
                          options={Topic.languages()}
                          required
                        />
                      </div>
                    </div>

                    <div class="flex gap-3 pt-4">
                      <button
                        type="submit"
                        class="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-semibold"
                      >
                        {gettext("Approve & Create Topic")}
                      </button>
                      <button
                        type="button"
                        phx-click="cancel_review"
                        class="px-6 py-3 bg-gray-700 text-white rounded-lg hover:bg-gray-600 transition-colors font-semibold"
                      >
                        {gettext("Cancel")}
                      </button>
                    </div>
                  </div>
                </.form>
              </div>
            </div>
          </div>
        <% end %>

        <%!-- Proposals List --%>
        <%= if @proposals == [] do %>
          <div class="text-center py-16 bg-gray-800 rounded-xl border border-gray-700">
            <div class="inline-flex items-center justify-center w-20 h-20 rounded-full bg-gray-700 border border-gray-600 mb-4">
              <.icon name="hero-document-text" class="w-10 h-10 text-gray-500" />
            </div>
            <h3 class="text-xl font-semibold text-gray-300 mb-2">
              {gettext("No proposals")}
            </h3>
            <p class="text-gray-500">{gettext("No topic proposals to review")}</p>
          </div>
        <% else %>
          <div class="space-y-4">
            <div
              :for={proposal <- @proposals}
              class={[
                "bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border transition-all",
                proposal.status == "pending" && "border-yellow-500/30",
                proposal.status == "approved" && "border-green-500/30",
                proposal.status == "rejected" && "border-red-500/30"
              ]}
            >
              <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
                <div class="flex-1">
                  <div class="flex items-center gap-3 mb-2 flex-wrap">
                    <h3 class="text-xl font-bold text-white">{proposal.title}</h3>
                    <span class={[
                      "px-3 py-1 rounded-full text-xs font-semibold",
                      proposal.status == "pending" &&
                        "bg-yellow-500/10 text-yellow-400 border border-yellow-500/20",
                      proposal.status == "approved" &&
                        "bg-green-500/10 text-green-400 border border-green-500/20",
                      proposal.status == "rejected" &&
                        "bg-red-500/10 text-red-400 border border-red-500/20"
                    ]}>
                      {proposal.status}
                    </span>
                  </div>

                  <%= if proposal.description do %>
                    <p class="text-gray-400 mb-3">{proposal.description}</p>
                  <% end %>

                  <div class="flex flex-wrap items-center gap-4 text-sm text-gray-500">
                    <span class="flex items-center gap-1">
                      <.icon name="hero-user" class="w-4 h-4" />
                      {proposal.proposed_by.email}
                    </span>
                    <span class="flex items-center gap-1">
                      <.icon name="hero-calendar" class="w-4 h-4" />
                      {Calendar.strftime(proposal.inserted_at, "%b %d, %Y")}
                    </span>
                  </div>

                  <%= if proposal.review_notes do %>
                    <div class="mt-3 p-3 bg-gray-700/30 rounded-lg border border-gray-700/50">
                      <p class="text-sm text-gray-400">
                        <span class="font-semibold text-gray-300">{gettext("Review notes")}:</span>
                        {proposal.review_notes}
                      </p>
                    </div>
                  <% end %>
                </div>

                <div class="flex flex-row sm:flex-col gap-2 w-full sm:w-auto">
                  <%= if proposal.status == "pending" do %>
                    <button
                      phx-click="review"
                      phx-value-id={proposal.id}
                      class="flex-1 sm:flex-none px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold whitespace-nowrap"
                    >
                      {gettext("Review")}
                    </button>
                  <% end %>
                  <button
                    phx-click="delete"
                    phx-value-id={proposal.id}
                    data-confirm={gettext("Are you sure?")}
                    class="flex-1 sm:flex-none px-4 py-2 bg-gray-700 text-red-400 rounded-lg hover:bg-red-600 hover:text-white transition-colors text-sm font-semibold whitespace-nowrap"
                  >
                    {gettext("Delete")}
                  </button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
