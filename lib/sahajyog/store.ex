defmodule Sahajyog.Store do
  @moduledoc """
  The Store context for managing SahajStore marketplace items.
  """

  import Ecto.Query
  alias Sahajyog.Repo
  alias Sahajyog.Store.{StoreItem, StoreItemMedia, StoreItemInquiry}
  alias Sahajyog.Resources.R2Storage

  @max_photos 5
  @max_videos 1

  ## Item CRUD Operations

  @doc """
  Creates a new store item for a user.
  The item is created with status "pending" by default.
  """
  def create_item(attrs, user) do
    %StoreItem{}
    |> StoreItem.create_changeset(attrs, user)
    |> Repo.insert()
  end

  @doc """
  Gets a single store item by ID.
  Raises `Ecto.NoResultsError` if the item does not exist.
  """
  def get_item!(id) do
    Repo.get!(StoreItem, id)
  end

  @doc """
  Gets a single store item with preloaded media.
  Raises `Ecto.NoResultsError` if the item does not exist.
  """
  def get_item_with_media!(id) do
    StoreItem
    |> preload([:media, :user])
    |> Repo.get!(id)
  end

  @doc """
  Updates a store item.
  If the item was approved, the status is reset to "pending" for re-review.
  """
  def update_item(%StoreItem{} = item, attrs, _user) do
    item
    |> StoreItem.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a store item and its associated media from R2 storage.
  """
  def delete_item(%StoreItem{} = item) do
    # First, get all media for this item to delete from R2
    media_list = list_media_for_item(item.id)

    # Delete media files from R2 (best effort, don't block on failures)
    Enum.each(media_list, fn media ->
      try do
        R2Storage.delete(media.r2_key)
      rescue
        _ -> :ok
      end
    end)

    # Delete the item (cascades to media records due to on_delete: :delete_all)
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking store item changes.
  """
  def change_item(%StoreItem{} = item, attrs \\ %{}) do
    StoreItem.changeset(item, attrs)
  end

  ## Listing Queries

  @doc """
  Lists all approved store items with optional filters.
  """
  def list_approved_items(opts \\ []) do
    StoreItem
    |> where([i], i.status == "approved")
    |> apply_filters(opts)
    |> order_by([i], desc: i.inserted_at)
    |> preload([:media, :user])
    |> Repo.all()
  end

  @doc """
  Lists all pending store items for admin review.
  """
  def list_pending_items do
    StoreItem
    |> where([i], i.status == "pending")
    |> order_by([i], asc: i.inserted_at)
    |> preload([:media, :user])
    |> Repo.all()
  end

  @doc """
  Lists all store items for a specific user (seller dashboard).
  Returns items in all statuses.
  """
  def list_user_items(user_id) do
    StoreItem
    |> where([i], i.user_id == ^user_id)
    |> order_by([i], desc: i.inserted_at)
    |> preload([:media])
    |> Repo.all()
  end

  ## Admin Approval/Rejection Functions

  @doc """
  Approves a store item, setting status to "approved" and recording the reviewer.
  """
  def approve_item(%StoreItem{} = item, admin, _opts \\ []) do
    item
    |> StoreItem.approve_changeset(admin)
    |> Repo.update()
  end

  @doc """
  Rejects a store item, requiring review notes.
  """
  def reject_item(%StoreItem{} = item, admin, review_notes) do
    item
    |> StoreItem.reject_changeset(admin, review_notes)
    |> Repo.update()
  end

  @doc """
  Marks a store item as sold.
  """
  def mark_item_sold(%StoreItem{} = item) do
    item
    |> StoreItem.sold_changeset()
    |> Repo.update()
  end

  ## Media Management Functions

  @doc """
  Adds media to a store item, enforcing photo/video count limits.
  Returns {:error, :photo_limit_exceeded} or {:error, :video_limit_exceeded} if limits are exceeded.
  """
  def add_media(%StoreItem{} = item, media_attrs) do
    media_type = Map.get(media_attrs, :media_type) || Map.get(media_attrs, "media_type")

    with :ok <- check_media_limit(item.id, media_type) do
      %StoreItemMedia{}
      |> StoreItemMedia.changeset(Map.put(media_attrs, :store_item_id, item.id))
      |> Repo.insert()
    end
  end

  @doc """
  Deletes media from a store item and removes the file from R2 storage.
  """
  def delete_media(%StoreItemMedia{} = media) do
    # Delete from R2 (best effort, don't block on failures)
    try do
      R2Storage.delete(media.r2_key)
    rescue
      _ -> :ok
    end

    # Delete the database record
    Repo.delete(media)
  end

  @doc """
  Counts the number of photos for a store item.
  """
  def count_photos(item_id) do
    StoreItemMedia
    |> where([m], m.store_item_id == ^item_id and m.media_type == "photo")
    |> Repo.aggregate(:count)
  end

  @doc """
  Counts the number of videos for a store item.
  """
  def count_videos(item_id) do
    StoreItemMedia
    |> where([m], m.store_item_id == ^item_id and m.media_type == "video")
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists all media for a store item.
  """
  def list_media_for_item(item_id) do
    StoreItemMedia
    |> where([m], m.store_item_id == ^item_id)
    |> order_by([m], asc: m.position)
    |> Repo.all()
  end

  ## Inquiry Functions

  @doc """
  Creates an inquiry for a store item.
  Validates that requested quantity doesn't exceed available quantity.
  """
  def create_inquiry(%StoreItem{} = item, buyer, attrs) do
    %StoreItemInquiry{}
    |> StoreItemInquiry.create_changeset(attrs, buyer, item)
    |> Repo.insert()
  end

  @doc """
  Lists all inquiries for a specific store item.
  """
  def list_inquiries_for_item(item_id) do
    StoreItemInquiry
    |> where([i], i.store_item_id == ^item_id)
    |> order_by([i], desc: i.inserted_at)
    |> preload([:buyer])
    |> Repo.all()
  end

  @doc """
  Lists all inquiries for items owned by a seller.
  """
  def list_inquiries_for_seller(user_id) do
    StoreItemInquiry
    |> join(:inner, [i], si in StoreItem, on: i.store_item_id == si.id)
    |> where([i, si], si.user_id == ^user_id)
    |> order_by([i], desc: i.inserted_at)
    |> preload([:buyer, :store_item])
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inquiry changes.
  """
  def change_inquiry(%StoreItemInquiry{} = inquiry, attrs \\ %{}) do
    StoreItemInquiry.changeset(inquiry, attrs)
  end

  ## Private Helpers

  defp check_media_limit(item_id, "photo") do
    if count_photos(item_id) >= @max_photos do
      {:error, :photo_limit_exceeded}
    else
      :ok
    end
  end

  defp check_media_limit(item_id, "video") do
    if count_videos(item_id) >= @max_videos do
      {:error, :video_limit_exceeded}
    else
      :ok
    end
  end

  defp check_media_limit(_item_id, _media_type), do: :ok

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:pricing_type, pricing_type}, query when is_binary(pricing_type) ->
        where(query, [i], i.pricing_type == ^pricing_type)

      {:delivery_method, method}, query when is_binary(method) ->
        where(query, [i], ^method in i.delivery_methods)

      {:search, search_term}, query when is_binary(search_term) and search_term != "" ->
        search_pattern = "%#{search_term}%"
        where(query, [i], ilike(i.name, ^search_pattern) or ilike(i.description, ^search_pattern))

      _, query ->
        query
    end)
  end
end
