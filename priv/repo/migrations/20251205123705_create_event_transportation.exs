defmodule Sahajyog.Repo.Migrations.CreateEventTransportation do
  use Ecto.Migration

  def change do
    create table(:event_transportation) do
      add :transport_type, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :departure_location, :string
      add :departure_time, :time
      add :estimated_cost, :decimal, precision: 10, scale: 2
      add :contact_info, :string
      add :position, :integer, default: 0
      add :event_id, references(:events, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_transportation, [:event_id])
    create index(:event_transportation, [:transport_type])
  end
end
