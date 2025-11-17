defmodule Sahajyog.Repo.Migrations.AddStepNumberToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :step_number, :integer
    end

    create index(:videos, [:step_number])
  end
end
