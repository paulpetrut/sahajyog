defmodule Sahajyog.Resources do
  @moduledoc """
  Context for managing downloadable resources stored in Cloudflare R2.
  """

  import Ecto.Query
  alias Sahajyog.Repo
  alias Sahajyog.Resources.Resource

  @doc """
  Lists all resources, optionally filtered by level, type, or language.
  """
  def list_resources(filters \\ %{}) do
    Resource
    |> apply_filters(filters)
    |> order_by([r], desc: r.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists resources accessible to a specific user based on their level.
  """
  def list_resources_for_user(user, filters \\ %{}) do
    filters = Map.put(filters, :level, user.level)
    list_resources(filters)
  end

  @doc """
  Gets a single resource by ID.
  """
  def get_resource!(id), do: Repo.get!(Resource, id)

  @doc """
  Creates a resource record in the database.
  """
  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a resource.
  """
  def update_resource(%Resource{} = resource, attrs) do
    resource
    |> Resource.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a resource.
  """
  def delete_resource(%Resource{} = resource) do
    Repo.delete(resource)
  end

  @doc """
  Increments the download counter for a resource.
  """
  def increment_downloads(%Resource{} = resource) do
    resource
    |> Ecto.Changeset.change(downloads_count: resource.downloads_count + 1)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking resource changes.
  """
  def change_resource(%Resource{} = resource, attrs \\ %{}) do
    Resource.changeset(resource, attrs)
  end

  @doc """
  Generates a thumbnail URL for a resource.
  Returns nil if no thumbnail is set.
  """
  def thumbnail_url(%Resource{thumbnail_r2_key: nil}), do: nil

  def thumbnail_url(%Resource{thumbnail_r2_key: key}) when is_binary(key) do
    Sahajyog.Resources.R2Storage.generate_download_url(key)
  end

  @levels ["Level1", "Level2", "Level3"]

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:level, level}, query when is_binary(level) ->
        # Show resources at or below user's level
        accessible_levels = levels_up_to(level)
        where(query, [r], r.level in ^accessible_levels)

      {:resource_type, resource_type}, query when is_binary(resource_type) ->
        where(query, [r], r.resource_type == ^resource_type)

      {:language, language}, query when is_binary(language) ->
        where(query, [r], r.language == ^language)

      {:user_id, user_id}, query when is_integer(user_id) ->
        where(query, [r], r.user_id == ^user_id)

      _, query ->
        query
    end)
  end

  defp levels_up_to(level) do
    case Enum.find_index(@levels, &(&1 == level)) do
      nil -> @levels
      index -> Enum.take(@levels, index + 1)
    end
  end
end
