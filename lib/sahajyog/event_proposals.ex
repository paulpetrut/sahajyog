defmodule Sahajyog.EventProposals do
  @moduledoc """
  Context for managing event proposals.
  """

  import Ecto.Query
  alias Sahajyog.Events.Event
  alias Sahajyog.Events.EventProposal
  alias Sahajyog.Repo

  @doc """
  Lists event proposals with optional filters.
  """
  def list_proposals(filters \\ %{}) do
    EventProposal
    |> apply_proposal_filters(filters)
    |> order_by([p], asc: p.inserted_at)
    |> preload([:proposed_by, :reviewed_by, :event])
    |> Repo.all()
  end

  @doc """
  Lists pending event proposals.
  """
  def list_pending_proposals do
    list_proposals(%{status: "pending"})
  end

  @doc """
  Gets a single proposal by ID.
  """
  def get_proposal!(id) do
    EventProposal
    |> preload([:proposed_by, :reviewed_by, :event])
    |> Repo.get!(id)
  end

  @doc """
  Creates a new event proposal.
  """
  def create_proposal(current_scope, attrs) do
    attrs = Map.put(attrs, "proposed_by_id", current_scope.user.id)

    %EventProposal{}
    |> EventProposal.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Approves a proposal and creates an event from it.
  """
  def approve_proposal(current_scope, %EventProposal{} = proposal, event_attrs) do
    Repo.transaction(fn ->
      # Set the event owner to the user who proposed it
      event_attrs = Map.put(event_attrs, "user_id", proposal.proposed_by_id)

      # Transfer meeting link and video data from proposal to event
      event_attrs =
        event_attrs
        |> maybe_transfer_field(proposal, :meeting_platform_link)
        |> maybe_transfer_field(proposal, :presentation_video_type)
        |> maybe_transfer_field(proposal, :presentation_video_url)

      with {:ok, event} <-
             struct(Event, %{}) |> Event.changeset(event_attrs) |> Repo.insert(),
           {:ok, updated_proposal} <-
             update_proposal(proposal, %{
               status: "approved",
               reviewed_by_id: current_scope.user.id,
               event_id: event.id
             }) do
        {event, updated_proposal}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  # Transfers a field from proposal to event_attrs if not already set in event_attrs
  defp maybe_transfer_field(event_attrs, proposal, field) do
    string_key = Atom.to_string(field)
    proposal_value = Map.get(proposal, field)

    # Only transfer if proposal has a value and event_attrs doesn't already have it
    if proposal_value && !Map.has_key?(event_attrs, string_key) do
      Map.put(event_attrs, string_key, proposal_value)
    else
      event_attrs
    end
  end

  @doc """
  Rejects a proposal with review notes.
  """
  def reject_proposal(current_scope, %EventProposal{} = proposal, review_notes) do
    update_proposal(proposal, %{
      status: "rejected",
      reviewed_by_id: current_scope.user.id,
      review_notes: review_notes
    })
  end

  @doc """
  Updates a proposal.
  """
  def update_proposal(%EventProposal{} = proposal, attrs) do
    proposal
    |> EventProposal.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a proposal.
  """
  def delete_proposal(%EventProposal{} = proposal) do
    Repo.delete(proposal)
  end

  @doc """
  Returns a changeset for tracking proposal changes.
  """
  def change_proposal(%EventProposal{} = proposal, attrs \\ %{}) do
    EventProposal.changeset(proposal, attrs)
  end

  # Private helpers

  defp apply_proposal_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when is_binary(status) ->
        where(query, [p], p.status == ^status)

      {:proposed_by_id, user_id}, query when is_integer(user_id) ->
        where(query, [p], p.proposed_by_id == ^user_id)

      _, query ->
        query
    end)
  end
end
