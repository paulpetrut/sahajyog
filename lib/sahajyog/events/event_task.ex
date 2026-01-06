defmodule Sahajyog.Events.EventTask do
  @moduledoc """
  Schema for tracking event-related tasks.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @statuses ~w(pending in_progress completed cancelled)

  schema "event_tasks" do
    field :title, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :start_date, :date
    field :due_date, :date
    field :estimated_expense, :decimal
    field :actual_expense, :decimal
    field :expense_notes, :string
    field :expense_receipt_url, :string
    field :position, :integer, default: 0
    field :city, :string
    field :country, :string

    belongs_to :event, Event
    belongs_to :assigned_user, User
    has_many :participants, Sahajyog.Events.EventTaskParticipant, foreign_key: :task_id
    has_many :volunteers, through: [:participants, :user]

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :status,
      :start_date,
      :due_date,
      :estimated_expense,
      :actual_expense,
      :expense_notes,
      :expense_receipt_url,
      :position,
      :event_id,
      :assigned_user_id,
      :city,
      :country
    ])
    |> validate_required([:title, :event_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:estimated_expense, greater_than_or_equal_to: 0)
    |> validate_number(:actual_expense, greater_than_or_equal_to: 0)
  end
end
