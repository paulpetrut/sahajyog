defmodule Sahajyog.Repo.Migrations.AddIsPubliclyAccessibleToEventsAndTopics do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :is_publicly_accessible, :boolean, default: false, null: false
    end

    alter table(:topics) do
      add :is_publicly_accessible, :boolean, default: false, null: false
    end
  end
end
