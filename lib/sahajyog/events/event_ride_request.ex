defmodule Sahajyog.Events.EventRideRequest do
  @moduledoc """
  Schema for tracking ride requests for an event.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @statuses ~w(pending accepted fulfilled cancelled)

  schema "event_ride_requests" do
    field :location, :string
    field :contact_info, :string
    field :status, :string, default: "pending"

    belongs_to :event, Event
    belongs_to :passenger_user, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:location, :contact_info, :status, :event_id, :passenger_user_id])
    |> validate_required([:location, :event_id, :passenger_user_id])
    |> validate_inclusion(:status, @statuses)
  end
end
