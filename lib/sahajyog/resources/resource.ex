defmodule Sahajyog.Resources.Resource do
  @moduledoc """
  Schema for community resources like photos, books, and music.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @levels ~w(Level1 Level2 Level3)
  @types ~w(Photos Books Music)
  @max_file_size 500 * 1024 * 1024

  schema "resources" do
    field :title, :string
    field :description, :string
    field :file_name, :string
    field :file_size, :integer
    field :content_type, :string
    field :r2_key, :string
    field :thumbnail_r2_key, :string
    field :level, :string
    field :resource_type, :string
    field :language, :string
    field :downloads_count, :integer, default: 0

    belongs_to :user, Sahajyog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [
      :title,
      :description,
      :file_name,
      :file_size,
      :content_type,
      :r2_key,
      :thumbnail_r2_key,
      :level,
      :resource_type,
      :language,
      :user_id
    ])
    |> validate_required([
      :title,
      :file_name,
      :file_size,
      :content_type,
      :r2_key,
      :level,
      :resource_type
    ])
    |> validate_inclusion(:level, @levels)
    |> validate_inclusion(:resource_type, @types)
    |> validate_number(:file_size, greater_than: 0, less_than: @max_file_size)
    |> unique_constraint(:r2_key)
  end

  def levels, do: @levels
  def types, do: @types
end
