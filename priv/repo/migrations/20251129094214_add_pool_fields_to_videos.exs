defmodule Sahajyog.Repo.Migrations.AddPoolFieldsToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :pool_position, :integer
      add :in_pool, :boolean, default: false, null: false
    end

    create index(:videos, [:category, :in_pool])
    create index(:videos, [:pool_position], where: "in_pool = true")
  end
end
