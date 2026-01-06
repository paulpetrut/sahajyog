defmodule Sahajyog.Store.StoreItem do
  @moduledoc """
  Schema for store items in the SahajStore marketplace.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Store.{StoreItemInquiry, StoreItemMedia}

  @statuses ~w(pending approved rejected sold)
  @pricing_types ~w(fixed_price accepts_donation)
  @delivery_methods ~w(express_delivery in_person local_pickup shipping)
  @currencies ~w(USD EUR GBP INR RON JPY CNY AUD CAD CHF)

  @max_name_length 200
  @max_description_length 2000

  @derive {Jason.Encoder,
           only: [
             :id,
             :name,
             :description,
             :quantity,
             :production_cost,
             :price,
             :pricing_type,
             :currency,
             :status,
             :delivery_methods,
             :shipping_cost,
             :shipping_regions,
             :meeting_location,
             :phone_visible,
             :user_id,
             :inserted_at,
             :updated_at
           ]}

  schema "store_items" do
    field :name, :string
    field :description, :string
    field :quantity, :integer
    field :production_cost, :decimal
    field :price, :decimal
    field :pricing_type, :string, default: "fixed_price"
    field :currency, :string, default: "EUR"
    field :status, :string, default: "pending"
    field :review_notes, :string

    # Delivery options
    field :delivery_methods, {:array, :string}, default: []
    field :shipping_cost, :decimal
    field :shipping_regions, :string
    field :meeting_location, :string

    # Seller visibility preferences
    field :phone_visible, :boolean, default: false

    belongs_to :user, User
    belongs_to :reviewed_by, User

    has_many :media, StoreItemMedia
    has_many :inquiries, StoreItemInquiry

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def pricing_types, do: @pricing_types
  def delivery_methods, do: @delivery_methods
  def currencies, do: @currencies
  def max_name_length, do: @max_name_length
  def max_description_length, do: @max_description_length

  @doc """
  Returns the currency symbol for a given currency code.
  """
  def currency_symbol("USD"), do: "$"
  def currency_symbol("EUR"), do: "€"
  def currency_symbol("GBP"), do: "£"
  def currency_symbol("INR"), do: "₹"
  def currency_symbol("RON"), do: "lei"
  def currency_symbol("JPY"), do: "¥"
  def currency_symbol("CNY"), do: "¥"
  def currency_symbol("AUD"), do: "A$"
  def currency_symbol("CAD"), do: "C$"
  def currency_symbol("CHF"), do: "CHF"
  def currency_symbol(_), do: ""

  @doc """
  Converts a JSON-decoded map back to a StoreItem struct.
  Used for round-trip JSON serialization testing.
  """
  def from_json(map) when is_map(map) do
    %__MODULE__{
      id: map["id"],
      name: map["name"],
      description: map["description"],
      quantity: map["quantity"],
      production_cost: parse_decimal(map["production_cost"]),
      price: parse_decimal(map["price"]),
      pricing_type: map["pricing_type"],
      currency: map["currency"],
      status: map["status"],
      delivery_methods: map["delivery_methods"],
      shipping_cost: parse_decimal(map["shipping_cost"]),
      shipping_regions: map["shipping_regions"],
      meeting_location: map["meeting_location"],
      phone_visible: map["phone_visible"],
      user_id: map["user_id"],
      inserted_at: parse_datetime(map["inserted_at"]),
      updated_at: parse_datetime(map["updated_at"])
    }
  end

  defp parse_decimal(nil), do: nil
  defp parse_decimal(value) when is_binary(value), do: Decimal.new(value)
  defp parse_decimal(value) when is_number(value), do: Decimal.from_float(value / 1)

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      _ -> nil
    end
  end

  @doc """
  Creates a changeset for a store item.
  """
  def changeset(store_item, attrs) do
    store_item
    |> cast(attrs, [
      :name,
      :description,
      :quantity,
      :production_cost,
      :price,
      :pricing_type,
      :currency,
      :status,
      :review_notes,
      :delivery_methods,
      :shipping_cost,
      :shipping_regions,
      :meeting_location,
      :phone_visible,
      :user_id,
      :reviewed_by_id
    ])
    |> validate_required([:name, :quantity, :pricing_type, :currency, :delivery_methods])
    |> validate_length(:name, max: @max_name_length)
    |> validate_length(:description, max: @max_description_length)
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:production_cost, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:pricing_type, @pricing_types)
    |> validate_inclusion(:currency, @currencies)
    |> validate_delivery_methods()
    |> validate_price_for_fixed_pricing()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:reviewed_by_id)
  end

  @doc """
  Creates a changeset for creating a new store item.
  Ensures status defaults to pending and user_id is set.
  """
  def create_changeset(store_item, attrs, user) do
    store_item
    |> changeset(attrs)
    |> put_change(:user_id, user.id)
    |> put_change(:status, "pending")
  end

  @doc """
  Creates a changeset for updating a store item.
  Resets status to pending if the item was approved.
  """
  def update_changeset(store_item, attrs) do
    changeset = changeset(store_item, attrs)

    if store_item.status == "approved" do
      put_change(changeset, :status, "pending")
    else
      changeset
    end
  end

  @doc """
  Creates a changeset for admin approval.
  """
  def approve_changeset(store_item, admin) do
    store_item
    |> change()
    |> put_change(:status, "approved")
    |> put_change(:reviewed_by_id, admin.id)
  end

  @doc """
  Creates a changeset for admin rejection.
  """
  def reject_changeset(store_item, admin, review_notes) do
    store_item
    |> change()
    |> put_change(:status, "rejected")
    |> put_change(:reviewed_by_id, admin.id)
    |> put_change(:review_notes, review_notes)
    |> validate_required([:review_notes])
  end

  @doc """
  Creates a changeset for marking an item as sold.
  """
  def sold_changeset(store_item) do
    store_item
    |> change()
    |> put_change(:status, "sold")
  end

  # Private validation functions

  defp validate_delivery_methods(changeset) do
    delivery_methods = get_field(changeset, :delivery_methods)

    cond do
      is_nil(delivery_methods) or delivery_methods == [] ->
        add_error(changeset, :delivery_methods, "must have at least one delivery method")

      not Enum.all?(delivery_methods, &(&1 in @delivery_methods)) ->
        add_error(changeset, :delivery_methods, "contains invalid delivery method")

      true ->
        changeset
    end
  end

  defp validate_price_for_fixed_pricing(changeset) do
    pricing_type = get_field(changeset, :pricing_type)
    price = get_field(changeset, :price)

    if pricing_type == "fixed_price" and (is_nil(price) or Decimal.compare(price, 0) != :gt) do
      add_error(changeset, :price, "is required and must be positive for fixed price items")
    else
      changeset
    end
  end
end
