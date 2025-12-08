defmodule Sahajyog.Repo.Migrations.CreateEventReviewsAndPhotos do
  use Ecto.Migration

  def change do
    create table(:event_reviews) do
      add :content, :text
      add :event_id, references(:events, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:event_reviews, [:event_id])
    create index(:event_reviews, [:user_id])
    create index(:event_reviews, [:event_id, :user_id])

    create table(:event_photos) do
      add :url, :string
      add :caption, :text
      add :event_id, references(:events, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:event_photos, [:event_id])
    create index(:event_photos, [:user_id])
  end
end
