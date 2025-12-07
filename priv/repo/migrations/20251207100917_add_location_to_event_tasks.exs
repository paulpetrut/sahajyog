defmodule Sahajyog.Repo.Migrations.AddLocationToEventTasks do
  use Ecto.Migration

  def change do
    alter table(:event_tasks) do
      add :city, :string
      add :country, :string
    end
  end
end
