defmodule Sahajyog.Repo.Migrations.CreateEventLocationPhotos do
  use Ecto.Migration

  def change do
    create table(:event_location_photos) do
      add :photo_url, :string, null: false
      add :caption, :string
      add :position, :integer, default: 0
      add :event_id, references(:events, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:event_location_photos, [:event_id])
    create index(:event_location_photos, [:position])
  end
end
