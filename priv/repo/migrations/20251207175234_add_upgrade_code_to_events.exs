defmodule Sahajyog.Repo.Migrations.AddUpgradeCodeToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :upgrade_code, :string
    end

    create unique_index(:events, [:upgrade_code])
  end
end
