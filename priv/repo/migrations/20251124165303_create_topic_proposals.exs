defmodule Sahajyog.Repo.Migrations.CreateTopicProposals do
  use Ecto.Migration

  def change do
    create table(:topic_proposals) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :proposed_by_id, references(:users, on_delete: :delete_all), null: false
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)
      add :topic_id, references(:topics, on_delete: :nilify_all)
      add :review_notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:topic_proposals, [:proposed_by_id])
    create index(:topic_proposals, [:reviewed_by_id])
    create index(:topic_proposals, [:topic_id])
    create index(:topic_proposals, [:status])
  end
end
