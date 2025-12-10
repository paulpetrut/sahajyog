defmodule Sahajyog.Repo.Migrations.AddOnlineEnhancementsToEventProposals do
  use Ecto.Migration

  def change do
    alter table(:event_proposals) do
      add :meeting_platform_link, :string
      add :presentation_video_type, :string
      add :presentation_video_url, :string
    end
  end
end
