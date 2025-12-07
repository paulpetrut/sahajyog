defmodule Sahajyog.Repo.Migrations.CreateEventTaskParticipants do
  use Ecto.Migration

  def change do
    create table(:event_task_participants) do
      add :task_id, references(:event_tasks, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      # accepted, pending (if approval needed)
      add :status, :string, default: "accepted"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:event_task_participants, [:task_id, :user_id])
    create index(:event_task_participants, [:user_id])
  end
end
