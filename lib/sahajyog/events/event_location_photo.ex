defmodule Sahajyog.Events.EventLocationPhoto do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Events.Event

  schema "event_location_photos" do
    field :photo_url, :string
    field :caption, :string
    field :position, :integer, default: 0

    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:photo_url, :caption, :position, :event_id])
    |> validate_required([:photo_url, :event_id])
  end
end
