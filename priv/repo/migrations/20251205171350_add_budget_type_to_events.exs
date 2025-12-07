defmodule Sahajyog.Repo.Migrations.AddBudgetTypeToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :budget_type, :string, default: "open_for_donations"
    end
  end
end
