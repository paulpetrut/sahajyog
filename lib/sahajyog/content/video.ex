defmodule Sahajyog.Content.Video do
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
    field :user_id, :id

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
      :step_number
    ])
    |> validate_required([:title, :url, :category])
    |> validate_inclusion(:category, @categories)
  end

  def categories, do: @categories
end
