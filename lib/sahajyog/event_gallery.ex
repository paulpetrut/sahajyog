defmodule Sahajyog.EventGallery do
  @moduledoc """
  Context for managing event photos and location photos.
  """

  import Ecto.Query
  alias Sahajyog.Events.{EventLocationPhoto, EventPhoto}
  alias Sahajyog.Repo
  alias Sahajyog.Resources.R2Storage

  ## Event Photos

  @doc """
  Lists photos for an event.
  """
  def list_event_photos(event_id) do
    EventPhoto
    |> where([p], p.event_id == ^event_id)
    |> order_by([p], desc: p.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Counts photos uploaded by a user for an event.
  """
  def count_user_event_photos(event_id, user_id) do
    EventPhoto
    |> where([p], p.event_id == ^event_id and p.user_id == ^user_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Creates an event photo.
  """
  def create_event_photo(attrs) do
    case %EventPhoto{}
         |> EventPhoto.changeset(attrs)
         |> Repo.insert() do
      {:ok, photo} ->
        photo = Repo.preload(photo, :user)
        broadcast(photo.event_id, {:photo_created, photo})
        {:ok, photo}

      error ->
        error
    end
  end

  @doc """
  Deletes an event photo and its R2 file.
  """
  def delete_event_photo(%EventPhoto{} = photo) do
    # Delete from R2 storage first (if it's an R2 key, not a legacy URL)
    if photo.url && !String.starts_with?(photo.url, "http") do
      key = String.trim_leading(photo.url, "/")
      R2Storage.delete(key)
    end

    case Repo.delete(photo) do
      {:ok, _} ->
        broadcast(photo.event_id, {:photo_deleted, photo.id})
        {:ok, photo}

      error ->
        error
    end
  end

  @doc """
  Gets a photo by ID.
  """
  def get_event_photo!(id), do: Repo.get!(EventPhoto, id)

  ## Location Photos

  @doc """
  Lists location photos for an event.
  """
  def list_location_photos(event_id) do
    EventLocationPhoto
    |> where([p], p.event_id == ^event_id)
    |> order_by([p], asc: p.position)
    |> Repo.all()
  end

  @doc """
  Creates a location photo.
  """
  def create_location_photo(attrs) do
    %EventLocationPhoto{}
    |> EventLocationPhoto.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a location photo.
  """
  def delete_location_photo(%EventLocationPhoto{} = photo) do
    Repo.delete(photo)
  end

  # Private helpers

  defp broadcast(event_id, message) do
    Phoenix.PubSub.broadcast(Sahajyog.PubSub, "event:#{event_id}", message)
  end
end
