defmodule Sahajyog.Events.EventDonation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event

  @payment_methods ~w(bank_transfer cash other)
  @currencies ~w(EUR USD GBP RON CHF)

  schema "event_donations" do
    field :donor_name, :string
    field :amount, :decimal
    field :currency, :string, default: "EUR"
    field :payment_method, :string, default: "bank_transfer"
    field :payment_date, :date
    field :notes, :string

    belongs_to :event, Event
    belongs_to :donor_user, User
    belongs_to :recorded_by, User

    timestamps(type: :utc_datetime)
  end

  def payment_methods, do: @payment_methods
  def currencies, do: @currencies

  def changeset(donation, attrs) do
    donation
    |> cast(attrs, [
      :donor_name,
      :amount,
      :currency,
      :payment_method,
      :payment_date,
      :notes,
      :event_id,
      :donor_user_id,
      :recorded_by_id
    ])
    |> validate_required([:amount, :event_id, :recorded_by_id])
    |> validate_inclusion(:payment_method, @payment_methods)
    |> validate_inclusion(:currency, @currencies)
    |> validate_number(:amount, greater_than: 0)
  end
end
