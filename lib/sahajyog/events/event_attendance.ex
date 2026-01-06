defmodule Sahajyog.Events.EventAttendance do
  @moduledoc """
  Schema for tracking event attendance.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @statuses ~w(attending maybe not_attending)

  schema "event_attendances" do
    field :status, :string, default: "attending"
    field :notes, :string

    belongs_to :event, Event
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(attendance, attrs) do
    attendance
    |> cast(attrs, [:status, :notes, :event_id, :user_id])
    |> validate_required([:event_id, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:event_id, :user_id])
  end
end
