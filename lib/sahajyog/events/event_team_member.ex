defmodule Sahajyog.Events.EventTeamMember do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @statuses ~w(pending accepted rejected)
  @roles ~w(co_author coordinator volunteer)

  schema "event_team_members" do
    field :role, :string, default: "co_author"
    field :status, :string, default: "pending"

    belongs_to :event, Event
    belongs_to :user, User
    belongs_to :invited_by, User

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def roles, do: @roles

  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:role, :status, :event_id, :user_id, :invited_by_id])
    |> validate_required([:event_id, :user_id, :invited_by_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:role, @roles)
    |> unique_constraint([:event_id, :user_id])
  end
end
