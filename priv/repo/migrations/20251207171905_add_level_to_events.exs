defmodule Sahajyog.Repo.Migrations.AddLevelToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :level, :string, default: "Level1"
    end
  end
end
