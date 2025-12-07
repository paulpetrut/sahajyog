defmodule Sahajyog.Events.EventProposal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @statuses ~w(pending approved rejected)
  @budget_types ~w(open_for_donations fixed_budget)

  schema "event_proposals" do
    field :title, :string
    field :description, :string
    field :event_date, :date
    field :start_time, :time
    field :online_url, :string
    field :is_online, :boolean, default: false
    field :city, :string
    field :country, :string
    field :budget_type, :string, default: "open_for_donations"
    field :status, :string, default: "pending"
    field :review_notes, :string

    belongs_to :proposed_by, User
    belongs_to :reviewed_by, User
    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def budget_types, do: @budget_types

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :title,
      :description,
      :event_date,
      :start_time,
      :online_url,
      :is_online,
      :city,
      :country,
      :budget_type,
      :status,
      :review_notes,
      :proposed_by_id,
      :reviewed_by_id,
      :event_id
    ])
    |> validate_required([:title, :event_date, :proposed_by_id])
    |> validate_online_fields()
    |> validate_in_person_fields()
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:budget_type, @budget_types)
  end

  defp validate_online_fields(changeset) do
    if get_field(changeset, :is_online) do
      changeset
      |> validate_required([:online_url, :start_time])
    else
      changeset
    end
  end

  defp validate_in_person_fields(changeset) do
    if !get_field(changeset, :is_online) do
      changeset
      |> validate_required([:city, :country, :budget_type])
    else
      changeset
    end
  end
end
