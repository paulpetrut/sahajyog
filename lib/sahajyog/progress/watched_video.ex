defmodule Sahajyog.Progress.WatchedVideo do
  @moduledoc """
  Schema for tracking videos watched by users.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "watched_videos" do
    field :video_id, :integer
    field :watched_at, :utc_datetime
    belongs_to :user, Sahajyog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(watched_video, attrs) do
    watched_video
    |> cast(attrs, [:user_id, :video_id, :watched_at])
    |> validate_required([:user_id, :video_id, :watched_at])
    |> unique_constraint([:user_id, :video_id])
  end
end
