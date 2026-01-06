defmodule Sahajyog.Repo.Migrations.AddPerformanceIndexesToEvents do
  use Ecto.Migration

  def change do
    # Events table indexes for filtering and querying
    # Note: [:slug] and [:user_id] indexes already exist from create_events migration
    create_if_not_exists index(:events, [:status, :event_date])
    create_if_not_exists index(:events, [:status, :level, :event_date])
    create_if_not_exists index(:events, [:country, :city])
    create_if_not_exists index(:events, [:is_publicly_accessible, :status, :event_date])

    # Event team members indexes
    create_if_not_exists index(:event_team_members, [:event_id, :user_id, :status])
    create_if_not_exists index(:event_team_members, [:user_id, :status])

    # Event attendances indexes
    create_if_not_exists index(:event_attendances, [:event_id, :user_id, :status])
    create_if_not_exists index(:event_attendances, [:user_id, :status])

    # Event tasks indexes
    create_if_not_exists index(:event_tasks, [:event_id])
    create_if_not_exists index(:event_tasks, [:event_id, :position])

    # Event transportation indexes
    create_if_not_exists index(:event_transportation, [:event_id])
    create_if_not_exists index(:event_transportation, [:event_id, :position])

    # Event carpools indexes
    create_if_not_exists index(:event_carpools, [:event_id])
    create_if_not_exists index(:event_carpools, [:driver_user_id])
    create_if_not_exists index(:event_carpools, [:event_id, :status])

    # Event carpool requests indexes
    create_if_not_exists index(:event_carpool_requests, [:carpool_id])
    create_if_not_exists index(:event_carpool_requests, [:passenger_user_id])

    create_if_not_exists index(:event_carpool_requests, [:carpool_id, :passenger_user_id, :status])

    # Event ride requests indexes
    create_if_not_exists index(:event_ride_requests, [:event_id])
    create_if_not_exists index(:event_ride_requests, [:passenger_user_id])
    create_if_not_exists index(:event_ride_requests, [:event_id, :passenger_user_id, :status])

    # Event donations indexes
    create_if_not_exists index(:event_donations, [:event_id])
    create_if_not_exists index(:event_donations, [:event_id, :payment_date])

    # Event reviews indexes
    create_if_not_exists index(:event_reviews, [:event_id])
    create_if_not_exists index(:event_reviews, [:user_id])
    create_if_not_exists index(:event_reviews, [:event_id, :user_id])

    # Event photos indexes
    create_if_not_exists index(:event_photos, [:event_id])
    create_if_not_exists index(:event_photos, [:user_id])
    create_if_not_exists index(:event_photos, [:event_id, :user_id])

    # Event location photos indexes
    create_if_not_exists index(:event_location_photos, [:event_id])
    create_if_not_exists index(:event_location_photos, [:event_id, :position])

    # Event proposals indexes
    create_if_not_exists index(:event_proposals, [:proposed_by_id])
    create_if_not_exists index(:event_proposals, [:status])
    create_if_not_exists index(:event_proposals, [:reviewed_by_id])

    # Event invitation materials indexes
    create_if_not_exists index(:event_invitation_materials, [:event_id])
  end
end
