defmodule Sahajyog.Progress do
  @moduledoc """
  The Progress context for tracking user video watching progress.
  """

  import Ecto.Query, warn: false
  alias Sahajyog.Repo
  alias Sahajyog.Progress.WatchedVideo

  @doc """
  Returns the list of watched video IDs for a user.
  """
  def list_watched_video_ids(user_id) do
    WatchedVideo
    |> where([w], w.user_id == ^user_id)
    |> select([w], w.video_id)
    |> Repo.all()
  end

  @doc """
  Marks a video as watched for a user.
  """
  def mark_video_watched(user_id, video_id) do
    %WatchedVideo{}
    |> WatchedVideo.changeset(%{
      user_id: user_id,
      video_id: video_id,
      watched_at: DateTime.utc_now()
    })
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc """
  Resets all watched videos for a user.
  """
  def reset_progress(user_id) do
    WatchedVideo
    |> where([w], w.user_id == ^user_id)
    |> Repo.delete_all()
  end

  @doc """
  Checks if a video is watched by a user.
  """
  def video_watched?(user_id, video_id) do
    WatchedVideo
    |> where([w], w.user_id == ^user_id and w.video_id == ^video_id)
    |> Repo.exists?()
  end
end
