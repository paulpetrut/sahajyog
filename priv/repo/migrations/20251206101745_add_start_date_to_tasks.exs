defmodule Sahajyog.Repo.Migrations.AddStartDateToTasks do
  use Ecto.Migration

  def change do
    alter table(:event_tasks) do
      add :start_date, :date
    end
  end
end
