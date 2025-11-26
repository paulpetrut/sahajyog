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
      <.admin_nav current_page={:topic_proposals} />

      <div class="max-w-7xl mx-auto px-4 py-8">
        <.page_header title={gettext("Topic Proposals")} />

        <%!-- Review Modal --%>
        <.modal
          :if={@reviewing_proposal}
          id="review-modal"
          on_close="cancel_review"
          size="lg"
        >
          <:title>{gettext("Review Proposal")}</:title>

          <div class="mb-6 p-4 bg-base-100/50 rounded-lg border border-base-content/10">
            <h3 class="font-semibold text-base-content mb-2">{@reviewing_proposal.title}</h3>
            <p class="text-base-content/60 text-sm mb-3">{@reviewing_proposal.description}</p>
            <p class="text-xs text-base-content/50">
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
                  class="px-6 py-3 bg-success text-success-content rounded-lg hover:bg-success/90 transition-colors font-semibold focus:outline-none focus:ring-2 focus:ring-success focus:ring-offset-2 focus:ring-offset-base-300"
                >
                  {gettext("Approve & Create Topic")}
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
              icon="hero-document-text"
              title={gettext("No proposals")}
              description={gettext("No topic proposals to review")}
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
                    <span class="flex items-center gap-1">
                      <.icon name="hero-calendar" class="w-4 h-4" />
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
