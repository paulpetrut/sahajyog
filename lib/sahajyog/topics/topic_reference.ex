defmodule Sahajyog.Topics.TopicReference do
  @moduledoc """
  Schema for topic references (books, talks, videos, articles, websites).
  References are linked to topics and provide supporting materials.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Topics.Topic

  @reference_types ~w(book talk video article website)

  schema "topic_references" do
    field :reference_type, :string
    field :title, :string
    field :url, :string
    field :description, :string
    field :position, :integer, default: 0

    belongs_to :topic, Topic

    timestamps(type: :utc_datetime)
  end

  def reference_types, do: @reference_types

  def changeset(reference, attrs) do
    reference
    |> cast(attrs, [:reference_type, :title, :url, :description, :position, :topic_id])
    |> validate_required([:reference_type, :title, :topic_id])
    |> validate_inclusion(:reference_type, @reference_types)
  end
end
