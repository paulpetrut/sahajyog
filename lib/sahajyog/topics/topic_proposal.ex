defmodule Sahajyog.Topics.TopicProposal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Topics.Topic

  @statuses ~w(pending approved rejected)

  schema "topic_proposals" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :review_notes, :string

    belongs_to :proposed_by, User
    belongs_to :reviewed_by, User
    belongs_to :topic, Topic

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :review_notes,
      :proposed_by_id,
      :reviewed_by_id,
      :topic_id
    ])
    |> validate_required([:title, :proposed_by_id])
    |> validate_inclusion(:status, @statuses)
  end
end
