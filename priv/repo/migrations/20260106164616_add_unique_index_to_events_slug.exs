defmodule Sahajyog.Repo.Migrations.AddUniqueIndexToEventsSlug do
  use Ecto.Migration

  def change do
    create_if_not_exists unique_index(:events, [:slug])
  end
end
