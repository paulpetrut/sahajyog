defmodule Sahajyog.Repo.Migrations.AddDetailsToEventCarpools do
  use Ecto.Migration

  def change do
    alter table(:event_carpools) do
      add :departure_date, :date
      # "free", "at_destination", "upfront"
      add :payment_method, :string
      add :cost, :decimal
    end
  end
end
