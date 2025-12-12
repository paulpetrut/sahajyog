defmodule Sahajyog.Repo.Migrations.CreateStoreTables do
  use Ecto.Migration

  def change do
    create table(:store_items) do
      add :name, :string, null: false
      add :description, :text
      add :quantity, :integer, null: false, default: 1
      add :production_cost, :decimal, precision: 10, scale: 2
      add :price, :decimal, precision: 10, scale: 2
      add :pricing_type, :string, null: false, default: "fixed_price"
      add :status, :string, null: false, default: "pending"
      add :review_notes, :text
      add :delivery_methods, {:array, :string}, default: []
      add :shipping_cost, :decimal, precision: 10, scale: 2
      add :shipping_regions, :string
      add :meeting_location, :string
      add :phone_visible, :boolean, default: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :reviewed_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:store_items, [:user_id])
    create index(:store_items, [:status])

    create table(:store_item_media) do
      add :file_name, :string, null: false
      add :content_type, :string, null: false
      add :file_size, :integer, null: false
      add :r2_key, :string, null: false
      add :media_type, :string, null: false
      add :position, :integer, default: 0
      add :store_item_id, references(:store_items, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:store_item_media, [:r2_key])
    create index(:store_item_media, [:store_item_id])

    create table(:store_item_inquiries) do
      add :message, :text, null: false
      add :requested_quantity, :integer, null: false, default: 1
      add :store_item_id, references(:store_items, on_delete: :delete_all), null: false
      add :buyer_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:store_item_inquiries, [:store_item_id])
    create index(:store_item_inquiries, [:buyer_id])
  end
end
