defmodule Sahajyog.Repo.Migrations.AddProviderToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :provider, :string, default: "youtube"
    end
  end
end
