defmodule Sahajyog.Events.EventPhoto do
  @moduledoc """
  Schema for event gallery photos.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_photos" do
    field :url, :string
    field :caption, :string
    belongs_to :event, Sahajyog.Events.Event
    belongs_to :user, Sahajyog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(event_photo, attrs) do
    event_photo
    |> cast(attrs, [:url, :caption, :event_id, :user_id])
    |> validate_required([:url, :event_id, :user_id])
  end
end
