defmodule Sahajyog.Events.EventReview do
  @moduledoc """
  Schema for event reviews.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "event_reviews" do
    field :content, :string
    belongs_to :event, Sahajyog.Events.Event
    belongs_to :user, Sahajyog.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(event_review, attrs) do
    event_review
    |> cast(attrs, [:content, :event_id, :user_id])
    |> validate_required([:content, :event_id, :user_id])

    # You might add length validation for content later
  end
end
