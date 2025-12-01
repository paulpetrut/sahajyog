defmodule Sahajyog.Repo.Migrations.AddCityCountryToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :city, :string
      add :country, :string
    end
  end
end
