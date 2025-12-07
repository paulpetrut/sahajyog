defmodule Sahajyog.Repo.Migrations.CreateEventTeamMembers do
  use Ecto.Migration

  def change do
    create table(:event_team_members) do
      add :role, :string, null: false, default: "co_author"
      add :status, :string, null: false, default: "pending"
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :invited_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_team_members, [:event_id])
    create index(:event_team_members, [:user_id])
    create index(:event_team_members, [:invited_by_id])
    create unique_index(:event_team_members, [:event_id, :user_id])
  end
end
