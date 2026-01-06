defmodule Sahajyog.Repo.Migrations.AddMissingUniqueIndexes do
  use Ecto.Migration

  def change do
    # Users table - email must be unique
    create_if_not_exists unique_index(:users, [:email])

    # Topics table - slug must be unique
    create_if_not_exists unique_index(:topics, [:slug])

    # Access codes table - code must be unique
    create_if_not_exists unique_index(:access_codes, [:code])

    # Store item media - r2_key must be unique
    create_if_not_exists unique_index(:store_item_media, [:r2_key])

    # Event invitation materials - r2_key must be unique
    create_if_not_exists unique_index(:event_invitation_materials, [:r2_key])

    # Resources - r2_key must be unique
    create_if_not_exists unique_index(:resources, [:r2_key])

    # Topic co-authors - one user per topic
    create_if_not_exists unique_index(:topic_co_authors, [:topic_id, :user_id])

    # Event team members - one user per event
    create_if_not_exists unique_index(:event_team_members, [:event_id, :user_id])

    # Event attendances - one attendance record per user per event
    create_if_not_exists unique_index(:event_attendances, [:event_id, :user_id])

    # Event carpool requests - one request per passenger per carpool
    create_if_not_exists unique_index(:event_carpool_requests, [:carpool_id, :passenger_user_id])

    # Weekly video assignments - one assignment per video per week
    create_if_not_exists unique_index(:weekly_video_assignments, [:video_id, :year, :week_number])

    # Watched videos - one watch record per user per video
    create_if_not_exists unique_index(:watched_videos, [:user_id, :video_id])

    # Users tokens - unique context and token combination
    create_if_not_exists unique_index(:users_tokens, [:context, :token])
  end
end
