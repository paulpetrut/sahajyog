defmodule Sahajyog.EventTeam do
  @moduledoc """
  Context for managing event team members.
  """

  import Ecto.Query
  alias Sahajyog.Events.EventTeamMember
  alias Sahajyog.Repo

  @doc """
  Lists team members for an event.
  """
  def list_team_members(event_id) do
    EventTeamMember
    |> where([tm], tm.event_id == ^event_id)
    |> preload([:user, :invited_by])
    |> Repo.all()
  end

  @doc """
  Invites a user to join an event team.
  """
  def invite_team_member(current_scope, event_id, user_id, role \\ "co_author") do
    %EventTeamMember{}
    |> EventTeamMember.changeset(%{
      event_id: event_id,
      user_id: user_id,
      invited_by_id: current_scope.user.id,
      role: role,
      status: "pending"
    })
    |> Repo.insert()
    |> broadcast_and_return(event_id)
  end

  @doc """
  Accepts a team invitation.
  """
  def accept_team_invitation(%EventTeamMember{} = member) do
    member
    |> EventTeamMember.changeset(%{status: "accepted"})
    |> Repo.update()
    |> broadcast_and_return(member.event_id)
  end

  @doc """
  Rejects a team invitation.
  """
  def reject_team_invitation(%EventTeamMember{} = member) do
    member
    |> EventTeamMember.changeset(%{status: "rejected"})
    |> Repo.update()
    |> broadcast_and_return(member.event_id)
  end

  @doc """
  Removes a team member from an event.
  """
  def remove_team_member(%EventTeamMember{} = member) do
    Repo.delete(member)
    |> broadcast_and_return(member.event_id)
  end

  @doc """
  Checks if a user is a team member of an event.
  """
  def team_member?(user_id, event_id) do
    EventTeamMember
    |> where(
      [tm],
      tm.user_id == ^user_id and tm.event_id == ^event_id and tm.status == "accepted"
    )
    |> Repo.exists?()
  end

  @doc """
  Returns a changeset for tracking team member changes.
  """
  def change_team_member(%EventTeamMember{} = member, attrs \\ %{}) do
    EventTeamMember.changeset(member, attrs)
  end

  # Private helpers

  defp broadcast_and_return({:ok, result}, event_id) do
    Phoenix.PubSub.broadcast(Sahajyog.PubSub, "event:#{event_id}", {:event_updated, event_id})
    {:ok, result}
  end

  defp broadcast_and_return(error, _event_id), do: error
end
