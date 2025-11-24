defmodule Sahajyog.Repo.Migrations.CreateTopicCoAuthors do
  use Ecto.Migration

  def change do
    create table(:topic_co_authors) do
      add :topic_id, references(:topics, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"
      add :invited_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:topic_co_authors, [:topic_id, :user_id])
    create index(:topic_co_authors, [:user_id])
    create index(:topic_co_authors, [:status])
  end
end
