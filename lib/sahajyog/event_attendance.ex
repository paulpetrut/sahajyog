defmodule Sahajyog.EventAttendance do
  @moduledoc """
  Context for managing event attendance.
  """

  import Ecto.Query
  alias Sahajyog.Events.EventAttendance
  alias Sahajyog.Repo

  @doc """
  Gets attendance record for a user and event.
  """
  def get_attendance(event_id, user_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Subscribes a user to an event.
  """
  def subscribe_to_event(user_id, event_id, notes \\ nil) do
    case get_attendance(event_id, user_id) do
      nil ->
        %EventAttendance{}
        |> EventAttendance.changeset(%{
          user_id: user_id,
          event_id: event_id,
          status: "attending",
          notes: notes
        })
        |> Repo.insert()

      attendance ->
        attendance
        |> EventAttendance.changeset(%{status: "attending", notes: notes})
        |> Repo.update()
    end
  end

  @doc """
  Unsubscribes a user from an event.
  """
  def unsubscribe_from_event(user_id, event_id) do
    case get_attendance(event_id, user_id) do
      nil ->
        {:ok, nil}

      attendance ->
        attendance
        |> EventAttendance.changeset(%{status: "not_attending"})
        |> Repo.update()
    end
  end

  @doc """
  Lists attendees for an event.
  """
  def list_attendees(event_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.status == "attending")
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Counts attendees for an event.
  """
  def count_attendees(event_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.status == "attending")
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns a changeset for tracking attendance changes.
  """
  def change_attendance(%EventAttendance{} = attendance, attrs \\ %{}) do
    EventAttendance.changeset(attendance, attrs)
  end
end
