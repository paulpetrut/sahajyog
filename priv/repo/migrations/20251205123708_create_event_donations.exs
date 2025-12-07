defmodule Sahajyog.Repo.Migrations.CreateEventDonations do
  use Ecto.Migration

  def change do
    create table(:event_donations) do
      add :donor_name, :string
      add :amount, :decimal, precision: 10, scale: 2, null: false
      add :currency, :string, null: false, default: "EUR"
      add :payment_method, :string, null: false, default: "bank_transfer"
      add :payment_date, :date
      add :notes, :text
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :donor_user_id, references(:users, on_delete: :nilify_all)
      add :recorded_by_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_donations, [:event_id])
    create index(:event_donations, [:donor_user_id])
    create index(:event_donations, [:recorded_by_id])
    create index(:event_donations, [:payment_date])
  end
end
