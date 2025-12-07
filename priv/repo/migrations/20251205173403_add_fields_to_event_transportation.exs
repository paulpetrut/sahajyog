defmodule Sahajyog.Repo.Migrations.AddFieldsToEventTransportation do
  use Ecto.Migration

  def change do
    alter table(:event_transportation) do
      add :capacity, :integer
      add :driver_name, :string
      add :driver_phone, :string
      add :pay_at_destination, :boolean, default: false, null: false
    end
  end
end
