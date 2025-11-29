defmodule Sahajyog.Repo.Migrations.CreateWeeklyVideoAssignments do
  use Ecto.Migration

  def change do
    create table(:weekly_video_assignments) do
      add :year, :integer, null: false
      add :week_number, :integer, null: false
      add :video_id, references(:videos, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:weekly_video_assignments, [:video_id, :year, :week_number])
    create index(:weekly_video_assignments, [:year, :week_number])
  end
end
