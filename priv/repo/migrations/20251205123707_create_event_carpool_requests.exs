defmodule Sahajyog.Repo.Migrations.CreateEventCarpoolRequests do
  use Ecto.Migration

  def change do
    create table(:event_carpool_requests) do
      add :status, :string, null: false, default: "pending"
      add :notes, :text
      add :carpool_id, references(:event_carpools, on_delete: :delete_all), null: false
      add :passenger_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_carpool_requests, [:carpool_id])
    create index(:event_carpool_requests, [:passenger_user_id])
    create index(:event_carpool_requests, [:status])
    create unique_index(:event_carpool_requests, [:carpool_id, :passenger_user_id])
  end
end
