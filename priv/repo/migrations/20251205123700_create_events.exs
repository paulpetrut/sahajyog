defmodule Sahajyog.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "draft"
      add :event_date, :date
      add :event_time, :time
      add :end_date, :date
      add :end_time, :time
      add :estimated_participants, :integer
      add :city, :string
      add :country, :string
      add :address, :text
      add :google_maps_link, :string
      add :google_maps_embed_url, :text
      add :venue_name, :string
      add :venue_website, :string
      add :invitation_type, :string, default: "none"
      add :invitation_url, :string
      add :budget_total, :decimal, precision: 12, scale: 2
      add :budget_notes, :text
      add :resources_required, :text
      add :banking_name, :string
      add :banking_iban, :string
      add :banking_swift, :string
      add :banking_notes, :text
      add :published_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:events, [:slug])
    create index(:events, [:user_id])
    create index(:events, [:status])
    create index(:events, [:event_date])
    create index(:events, [:country])
    create index(:events, [:city])
  end
end
