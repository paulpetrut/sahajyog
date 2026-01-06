defmodule Sahajyog.Topics.Topic do
  @moduledoc """
  Schema for topics in the knowledge base.
  Topics can be authored by users and have co-authors and references.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Topics.{TopicCoAuthor, TopicReference}

  @statuses ~w(draft published archived)
  @languages ~w(en es fr de it ro)

  schema "topics" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :status, :string, default: "draft"
    field :language, :string, default: "en"
    field :published_at, :utc_datetime
    field :views_count, :integer, default: 0
    field :is_publicly_accessible, :boolean, default: false

    belongs_to :user, User
    has_many :co_authors, TopicCoAuthor
    has_many :references, TopicReference

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def languages, do: @languages

  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [
      :title,
      :slug,
      :content,
      :status,
      :language,
      :published_at,
      :user_id,
      :is_publicly_accessible
    ])
    |> validate_required([:title, :user_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:language, @languages)
    |> generate_slug()
    |> unique_constraint(:slug)
    |> maybe_set_published_at()
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^\w\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end

  defp maybe_set_published_at(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    cond do
      status == "published" && is_nil(published_at) ->
        put_change(changeset, :published_at, DateTime.utc_now(:second))

      status != "published" && !is_nil(published_at) ->
        put_change(changeset, :published_at, nil)

      true ->
        changeset
    end
  end
end
