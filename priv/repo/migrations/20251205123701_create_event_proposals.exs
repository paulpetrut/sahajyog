defmodule Sahajyog.Repo.Migrations.CreateEventProposals do
  use Ecto.Migration

  def change do
    create table(:event_proposals) do
      add :title, :string, null: false
      add :description, :text
      add :event_date, :date
      add :city, :string
      add :country, :string
      add :status, :string, null: false, default: "pending"
      add :review_notes, :text
      add :proposed_by_id, references(:users, on_delete: :nilify_all), null: false
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)
      add :event_id, references(:events, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_proposals, [:proposed_by_id])
    create index(:event_proposals, [:reviewed_by_id])
    create index(:event_proposals, [:event_id])
    create index(:event_proposals, [:status])
  end
end
