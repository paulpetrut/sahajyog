defmodule Sahajyog.Repo.Migrations.CreateEventCarpools do
  use Ecto.Migration

  def change do
    create table(:event_carpools) do
      add :departure_location, :string, null: false
      add :departure_time, :time
      add :available_seats, :integer, null: false
      add :contact_phone, :string
      add :notes, :text
      add :status, :string, null: false, default: "open"
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :driver_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_carpools, [:event_id])
    create index(:event_carpools, [:driver_user_id])
    create index(:event_carpools, [:status])
  end
end
