defmodule Sahajyog.Repo.Migrations.CreateTopicReferences do
  use Ecto.Migration

  def change do
    create table(:topic_references) do
      add :topic_id, references(:topics, on_delete: :delete_all), null: false
      add :reference_type, :string, null: false
      add :title, :string, null: false
      add :url, :string
      add :description, :text
      add :position, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:topic_references, [:topic_id])
    create index(:topic_references, [:reference_type])
  end
end
