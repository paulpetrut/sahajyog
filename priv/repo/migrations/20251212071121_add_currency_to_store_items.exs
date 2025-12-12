defmodule Sahajyog.Repo.Migrations.AddCurrencyToStoreItems do
  use Ecto.Migration

  def change do
    alter table(:store_items) do
      add :currency, :string, default: "EUR", null: false
    end
  end
end
