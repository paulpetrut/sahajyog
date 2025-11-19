defmodule Sahajyog.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources) do
      add :title, :string, null: false
      add :description, :text
      add :file_name, :string, null: false
      add :file_size, :bigint, null: false
      add :content_type, :string, null: false
      add :r2_key, :string, null: false
      add :level, :string, null: false
      add :resource_type, :string, null: false
      add :language, :string
      add :downloads_count, :integer, default: 0, null: false
      add :user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:resources, [:user_id])
    create index(:resources, [:level])
    create index(:resources, [:resource_type])
    create index(:resources, [:language])
    create unique_index(:resources, [:r2_key])
  end
end
