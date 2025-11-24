defmodule Sahajyog.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content, :text
      add :status, :string, null: false, default: "draft"
      add :language, :string, default: "en"
      add :published_at, :utc_datetime
      add :views_count, :integer, default: 0, null: false
      add :user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:topics, [:slug])
    create index(:topics, [:user_id])
    create index(:topics, [:status])
    create index(:topics, [:published_at])
  end
end
