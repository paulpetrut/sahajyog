defmodule Sahajyog.Content do
  @moduledoc """
  The Content context for managing videos.
  """

  import Ecto.Query, warn: false
  alias Sahajyog.Repo
  alias Sahajyog.Content.Video

  def list_videos do
    Repo.all(from v in Video, order_by: [desc: v.inserted_at])
  end

  def list_videos_ordered do
    Repo.all(from v in Video, order_by: [asc: v.step_number, desc: v.inserted_at])
  end

  def list_videos_by_category(category) do
    Repo.all(from v in Video, where: v.category == ^category, order_by: [desc: v.inserted_at])
  end

  def get_video!(id), do: Repo.get!(Video, id)

  def create_video(attrs \\ %{}) do
    Repo.transaction(fn ->
      changeset = Video.changeset(%Video{}, attrs)

      # Get category from changeset
      category = Ecto.Changeset.get_field(changeset, :category)

      # If step_number is provided, shift existing videos in the same category
      case Ecto.Changeset.fetch_change(changeset, :step_number) do
        {:ok, step_number} when not is_nil(step_number) and not is_nil(category) ->
          shift_videos_up(step_number, category, nil)

        _ ->
          :ok
      end

      case Repo.insert(changeset) do
        {:ok, video} -> video
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def update_video(%Video{} = video, attrs) do
    Repo.transaction(fn ->
      changeset = Video.changeset(video, attrs)

      old_category = video.category
      new_category = Ecto.Changeset.get_field(changeset, :category)
      old_step_number = video.step_number
      new_step_number = Ecto.Changeset.get_field(changeset, :step_number)

      cond do
        # Category changed - handle moving between categories
        old_category != new_category ->
          # Shift down in old category
          if old_step_number do
            shift_videos_down(old_step_number + 1, old_category, video.id)
          end

          # Shift up in new category
          if new_step_number do
            shift_videos_up(new_step_number, new_category, video.id)
          end

        # Same category but step_number changed
        old_step_number != new_step_number and not is_nil(new_step_number) ->
          # Shift down videos in the old range
          if old_step_number do
            shift_videos_down(old_step_number + 1, old_category, video.id)
          end

          # Shift up videos at the new position
          shift_videos_up(new_step_number, new_category, video.id)

        true ->
          :ok
      end

      case Repo.update(changeset) do
        {:ok, video} -> video
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def delete_video(%Video{} = video) do
    Repo.transaction(fn ->
      case Repo.delete(video) do
        {:ok, deleted_video} ->
          # Shift down videos that were after this one in the same category
          if video.step_number && video.category do
            shift_videos_down(video.step_number + 1, video.category, nil)
          end

          deleted_video

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Shift videos up (increment step_number) for videos at or above the given step in the same category
  defp shift_videos_up(from_step, category, exclude_id) do
    query =
      from v in Video,
        where: v.step_number >= ^from_step and v.category == ^category

    query =
      if exclude_id do
        from v in query, where: v.id != ^exclude_id
      else
        query
      end

    Repo.update_all(query, inc: [step_number: 1])
  end

  # Shift videos down (decrement step_number) for videos at or above the given step in the same category
  defp shift_videos_down(from_step, category, exclude_id) do
    query =
      from v in Video,
        where: v.step_number >= ^from_step and v.category == ^category

    query =
      if exclude_id do
        from v in query, where: v.id != ^exclude_id
      else
        query
      end

    Repo.update_all(query, inc: [step_number: -1])
  end

  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  @doc """
  Returns the next available step number for a given category (max + 1, or 1 if no videos exist)
  """
  def next_step_number(category) when is_binary(category) do
    case Repo.one(from v in Video, where: v.category == ^category, select: max(v.step_number)) do
      nil -> 1
      max_step when is_integer(max_step) -> max_step + 1
      _ -> 1
    end
  end

  def next_step_number(_), do: 1
end
