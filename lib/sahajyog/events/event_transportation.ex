defmodule Sahajyog.Events.EventTransportation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Events.Event

  @transport_types ~w(public bus)

  schema "event_transportation" do
    field :transport_type, :string
    field :title, :string
    field :description, :string
    field :departure_location, :string
    field :departure_time, :time
    field :estimated_cost, :decimal
    field :contact_info, :string
    field :position, :integer, default: 0

    field :capacity, :integer
    field :driver_name, :string
    field :driver_phone, :string
    field :pay_at_destination, :boolean, default: false

    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  def transport_types, do: @transport_types

  def changeset(transportation, attrs) do
    transportation
    |> cast(attrs, [
      :transport_type,
      :title,
      :description,
      :departure_location,
      :departure_time,
      :estimated_cost,
      :contact_info,
      :position,
      :event_id,
      :capacity,
      :driver_name,
      :driver_phone,
      :pay_at_destination
    ])
    |> validate_required([:transport_type, :title, :event_id])
    |> validate_inclusion(:transport_type, @transport_types)
    |> validate_number(:estimated_cost, greater_than_or_equal_to: 0)
    |> validate_number(:capacity, greater_than: 0)
  end
end
