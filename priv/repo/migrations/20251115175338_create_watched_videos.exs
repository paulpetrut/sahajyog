defmodule Sahajyog.Repo.Migrations.CreateWatchedVideos do
  use Ecto.Migration

  def change do
    create table(:watched_videos) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :video_id, :integer, null: false
      add :watched_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:watched_videos, [:user_id])
    create unique_index(:watched_videos, [:user_id, :video_id])
  end
end
