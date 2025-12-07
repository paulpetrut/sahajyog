defmodule Sahajyog.Repo.Migrations.CreateEventFeatures do
  use Ecto.Migration

  def change do
    create table(:event_attendances) do
      add :status, :string, default: "attending"
      add :notes, :string
      add :event_id, references(:events, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_attendances, [:event_id])
    create index(:event_attendances, [:user_id])
    create unique_index(:event_attendances, [:event_id, :user_id])

    create table(:event_ride_requests) do
      add :location, :string
      add :contact_info, :string
      add :status, :string, default: "pending"
      add :event_id, references(:events, on_delete: :delete_all)
      add :passenger_user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_ride_requests, [:event_id])
    create index(:event_ride_requests, [:passenger_user_id])
  end
end
