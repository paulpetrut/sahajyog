defmodule Sahajyog.Store.StoreItemInquiry do
  @moduledoc """
  Schema for buyer inquiries about store items.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Store.StoreItem

  schema "store_item_inquiries" do
    field :message, :string
    field :requested_quantity, :integer

    belongs_to :store_item, StoreItem
    belongs_to :buyer, User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a store item inquiry.
  """
  def changeset(inquiry, attrs) do
    inquiry
    |> cast(attrs, [:message, :requested_quantity, :store_item_id, :buyer_id])
    |> validate_required([:message, :requested_quantity])
    |> validate_number(:requested_quantity, greater_than: 0)
    |> validate_length(:message, min: 1, max: 2000)
    |> foreign_key_constraint(:store_item_id)
    |> foreign_key_constraint(:buyer_id)
  end

  @doc """
  Creates a changeset for creating a new inquiry with buyer and item associations.
  """
  def create_changeset(inquiry, attrs, buyer, store_item) do
    inquiry
    |> changeset(attrs)
    |> put_change(:buyer_id, buyer.id)
    |> put_change(:store_item_id, store_item.id)
    |> validate_quantity_available(store_item)
  end

  defp validate_quantity_available(changeset, store_item) do
    requested_quantity = get_field(changeset, :requested_quantity)

    if requested_quantity && requested_quantity > store_item.quantity do
      add_error(
        changeset,
        :requested_quantity,
        "cannot exceed available quantity (#{store_item.quantity})"
      )
    else
      changeset
    end
  end
end
