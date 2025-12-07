defmodule Sahajyog.Repo.Migrations.AddBudgetTypeToEventProposals do
  use Ecto.Migration

  def change do
    alter table(:event_proposals) do
      add :budget_type, :string, default: "open_for_donations"
    end
  end
end
