defmodule Sahajyog.Events.EventTaskParticipant do
  @moduledoc """
  Schema for tracking participants/volunteers for a specific task.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.EventTask

  schema "event_task_participants" do
    field :status, :string, default: "accepted"

    belongs_to :task, EventTask
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:task_id, :user_id, :status])
    |> validate_required([:task_id, :user_id])
    |> validate_inclusion(:status, ["pending", "accepted", "rejected"])
  end
end
