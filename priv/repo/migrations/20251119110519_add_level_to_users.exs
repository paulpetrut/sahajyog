defmodule Sahajyog.Repo.Migrations.AddLevelToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :level, :string, default: "Level1", null: false
    end

    create index(:users, [:level])
  end
end
