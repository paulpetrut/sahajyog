defmodule Sahajyog.Store.StoreItemMedia do
  @moduledoc """
  Schema for media files (photos and videos) associated with store items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Store.StoreItem

  @media_types ~w(photo video)
  @photo_content_types ~w(image/jpeg image/png image/webp image/gif)
  @video_content_types ~w(video/mp4 video/webm video/quicktime)
  @max_photo_size 50 * 1024 * 1024
  @max_video_size 500 * 1024 * 1024

  schema "store_item_media" do
    field :file_name, :string
    field :content_type, :string
    field :file_size, :integer
    field :r2_key, :string
    field :media_type, :string
    field :position, :integer, default: 0

    belongs_to :store_item, StoreItem

    timestamps(type: :utc_datetime)
  end

  def media_types, do: @media_types
  def photo_content_types, do: @photo_content_types
  def video_content_types, do: @video_content_types
  def max_photo_size, do: @max_photo_size
  def max_video_size, do: @max_video_size

  @doc """
  Creates a changeset for store item media.
  """
  def changeset(media, attrs) do
    media
    |> cast(attrs, [
      :file_name,
      :content_type,
      :file_size,
      :r2_key,
      :media_type,
      :position,
      :store_item_id
    ])
    |> validate_required([:file_name, :content_type, :file_size, :r2_key, :media_type])
    |> validate_inclusion(:media_type, @media_types)
    |> validate_content_type()
    |> validate_file_size()
    |> unique_constraint(:r2_key)
    |> foreign_key_constraint(:store_item_id)
  end

  defp validate_content_type(changeset) do
    media_type = get_field(changeset, :media_type)
    content_type = get_field(changeset, :content_type)

    cond do
      is_nil(media_type) or is_nil(content_type) ->
        changeset

      media_type == "photo" and content_type not in @photo_content_types ->
        add_error(changeset, :content_type, "must be a valid image type (JPEG, PNG, WebP, GIF)")

      media_type == "video" and content_type not in @video_content_types ->
        add_error(changeset, :content_type, "must be a valid video type (MP4, WebM, MOV)")

      true ->
        changeset
    end
  end

  defp validate_file_size(changeset) do
    media_type = get_field(changeset, :media_type)
    file_size = get_field(changeset, :file_size)

    cond do
      is_nil(media_type) or is_nil(file_size) ->
        changeset

      media_type == "photo" and file_size > @max_photo_size ->
        add_error(changeset, :file_size, "must be less than 50MB for photos")

      media_type == "video" and file_size > @max_video_size ->
        add_error(changeset, :file_size, "must be less than 500MB for videos")

      true ->
        changeset
    end
  end
end
