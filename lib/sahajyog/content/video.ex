defmodule Sahajyog.Content.Video do
  @moduledoc """
  Schema for video content with support for YouTube and Vimeo providers.
  Videos can be organized by category and assigned to weekly schedules.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :title, :string
    field :url, :string
    field :category, :string
    field :description, :string
    field :thumbnail_url, :string
    field :duration, :string
    field :step_number, :integer
    field :provider, :string, default: "youtube"
    field :user_id, :id

    # Pool management fields
    field :pool_position, :integer
    field :in_pool, :boolean, default: false

    has_many :weekly_assignments, Sahajyog.Content.WeeklyVideoAssignment

    timestamps(type: :utc_datetime)
  end

  @categories ["Welcome", "Getting Started", "Advanced Topics", "Excerpts"]

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :title,
      :url,
      :category,
      :description,
      :thumbnail_url,
      :duration,
      :step_number,
      :provider,
      :pool_position,
      :in_pool
    ])
    |> validate_required([:title, :url, :category, :provider])
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:provider, ["youtube", "vimeo"])
    |> validate_pool_position()
  end

  defp validate_pool_position(changeset) do
    case get_field(changeset, :pool_position) do
      nil -> changeset
      pos when pos >= 1 and pos <= 31 -> changeset
      _ -> add_error(changeset, :pool_position, "must be between 1 and 31")
    end
  end

  def categories, do: @categories
end
