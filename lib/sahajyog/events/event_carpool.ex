defmodule Sahajyog.Events.EventCarpool do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.{Event, EventCarpoolRequest}

  @statuses ~w(open full cancelled)

  schema "event_carpools" do
    field :departure_location, :string
    field :departure_time, :time
    field :available_seats, :integer
    field :contact_phone, :string
    field :notes, :string
    field :status, :string, default: "open"
    field :departure_date, :date
    # "free", "at_destination", "upfront"
    field :payment_method, :string
    field :cost, :decimal

    belongs_to :event, Event
    belongs_to :driver_user, User
    has_many :requests, EventCarpoolRequest, foreign_key: :carpool_id

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(carpool, attrs) do
    carpool
    |> cast(attrs, [
      :departure_location,
      :departure_time,
      :available_seats,
      :contact_phone,
      :notes,
      :status,
      :event_id,
      :driver_user_id,
      :departure_date,
      :payment_method,
      :cost
    ])
    |> validate_required([
      :departure_location,
      :available_seats,
      :event_id,
      :driver_user_id,
      :departure_date,
      :payment_method
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:payment_method, ["free", "at_destination", "upfront"])
    |> validate_number(:available_seats, greater_than: 0)
  end

  @doc """
  Returns the number of accepted passengers for this carpool.
  """
  def accepted_count(%__MODULE__{requests: requests}) when is_list(requests) do
    Enum.count(requests, &(&1.status == "accepted"))
  end

  def accepted_count(_), do: 0

  @doc """
  Returns the remaining seats available.
  """
  def remaining_seats(%__MODULE__{available_seats: seats} = carpool) do
    max(0, seats - accepted_count(carpool))
  end
end
