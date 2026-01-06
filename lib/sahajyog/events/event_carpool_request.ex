defmodule Sahajyog.Events.EventCarpoolRequest do
  @moduledoc """
  Schema for tracking requests to join a carpool.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.EventCarpool

  @statuses ~w(pending accepted rejected)

  schema "event_carpool_requests" do
    field :status, :string, default: "pending"
    field :notes, :string

    belongs_to :carpool, EventCarpool, foreign_key: :carpool_id
    belongs_to :passenger_user, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:status, :notes, :carpool_id, :passenger_user_id])
    |> validate_required([:carpool_id, :passenger_user_id])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:carpool_id, :passenger_user_id])
  end
end
