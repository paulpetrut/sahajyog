defmodule Sahajyog.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "regular", null: false
    end

    create index(:users, [:role])
  end
end
