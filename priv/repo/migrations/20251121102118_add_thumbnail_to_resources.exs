defmodule Sahajyog.Repo.Migrations.AddThumbnailToResources do
  use Ecto.Migration

  def change do
    alter table(:resources) do
      add :thumbnail_r2_key, :string
    end
  end
end
