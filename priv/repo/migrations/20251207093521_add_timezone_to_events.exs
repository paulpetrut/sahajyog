defmodule Sahajyog.Repo.Migrations.AddTimezoneToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :timezone, :string, default: "Etc/UTC", null: false
    end
  end
end
