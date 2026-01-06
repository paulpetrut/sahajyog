defmodule Sahajyog.Topics.TopicCoAuthor do
  @moduledoc """
  Schema for topic co-authors.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Topics.Topic

  @statuses ~w(pending accepted rejected)

  schema "topic_co_authors" do
    field :status, :string, default: "pending"

    belongs_to :topic, Topic
    belongs_to :user, User
    belongs_to :invited_by, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(co_author, attrs) do
    co_author
    |> cast(attrs, [:status, :topic_id, :user_id, :invited_by_id])
    |> validate_required([:topic_id, :user_id, :invited_by_id])
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:topic_id, :user_id])
  end
end
