defmodule Sahajyog.Admin.AccessCode do
  @moduledoc """
  Schema for access codes used to grant special permissions or event access.
  Codes can have usage limits and are tracked for audit purposes.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "access_codes" do
    field :code, :string
    field :usage_count, :integer, default: 0
    field :max_uses, :integer

    belongs_to :event, Sahajyog.Events.Event
    belongs_to :created_by, Sahajyog.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(access_code, attrs) do
    access_code
    |> cast(attrs, [:code, :max_uses, :event_id, :created_by_id])
    |> validate_required([:code, :created_by_id])
    |> validate_number(:max_uses, greater_than: 0)
    |> unique_constraint(:code)
  end
end
