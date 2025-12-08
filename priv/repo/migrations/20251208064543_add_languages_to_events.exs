defmodule Sahajyog.Repo.Migrations.AddLanguagesToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :languages, {:array, :string}, default: ["en"]
    end
  end
end
