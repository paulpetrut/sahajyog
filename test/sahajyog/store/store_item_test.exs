defmodule Sahajyog.Store.StoreItemTest do
  use Sahajyog.DataCase, async: true
  use ExUnitProperties

  alias Sahajyog.Store.StoreItem

  # **Feature: sahaj-store, Property 4: Fixed price requires price field**
  # **Validates: Requirements 1.6, 1.7, 8.5**
  describe "Property 4: Fixed price requires price field" do
    property "fixed_price items require a positive price" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:price, _} = List.keyfind(changeset.errors, :price, 0)
      end
    end

    property "fixed_price items with positive price are valid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0)
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          delivery_methods: [delivery_method],
          price: price
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end

    property "accepts_donation items are valid without price" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "accepts_donation",
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 11: Delivery method requirement**
  # **Validates: Requirements 3.1**
  describe "Property 11: Delivery method requirement" do
    property "changeset is invalid with empty delivery_methods" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0)
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: []
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:delivery_methods, _} = List.keyfind(changeset.errors, :delivery_methods, 0)
      end
    end

    property "changeset is valid with at least one delivery method" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 24: Name validation constraints**
  # **Validates: Requirements 8.1**
  describe "Property 24: Name validation constraints" do
    property "name must be present" do
      check all(
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:name, _} = List.keyfind(changeset.errors, :name, 0)
      end
    end

    property "name exceeding 200 characters is invalid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 201, max_length: 250),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:name, _} = List.keyfind(changeset.errors, :name, 0)
      end
    end

    property "name within 200 characters is valid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 25: Description length constraint**
  # **Validates: Requirements 8.2**
  describe "Property 25: Description length constraint" do
    property "description exceeding 2000 characters is invalid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              description <- StreamData.string(:alphanumeric, min_length: 2001, max_length: 2100),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          description: description,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:description, _} = List.keyfind(changeset.errors, :description, 0)
      end
    end

    property "description within 2000 characters is valid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              description <- StreamData.string(:alphanumeric, max_length: 2000),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          description: description,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 26: Quantity positive integer validation**
  # **Validates: Requirements 8.3**
  describe "Property 26: Quantity positive integer validation" do
    property "quantity must be greater than 0" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <-
                StreamData.one_of([StreamData.constant(0), StreamData.integer(-100..-1)]),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:quantity, _} = List.keyfind(changeset.errors, :quantity, 0)
      end
    end

    property "positive quantity is valid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 27: Production cost non-negative validation**
  # **Validates: Requirements 8.4**
  describe "Property 27: Production cost non-negative validation" do
    property "negative production cost is invalid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              production_cost_float <- StreamData.float(min: -10_000.0, max: -0.01),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        production_cost = Decimal.from_float(production_cost_float) |> Decimal.round(2)
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          production_cost: production_cost,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        refute changeset.valid?
        assert {:production_cost, _} = List.keyfind(changeset.errors, :production_cost, 0)
      end
    end

    property "non-negative production cost is valid" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              production_cost_float <- StreamData.float(min: 0.0, max: 10_000.0),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        production_cost = Decimal.from_float(production_cost_float) |> Decimal.round(2)
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          production_cost: production_cost,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        changeset = StoreItem.changeset(%StoreItem{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end

  # **Feature: sahaj-store, Property 29: Store item JSON round-trip**
  # **Validates: Requirements 8.7**
  describe "Property 29: Store item JSON round-trip" do
    property "serializing to JSON and deserializing back produces equivalent structure" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              description <- StreamData.string(:alphanumeric, max_length: 500),
              quantity <- StreamData.positive_integer(),
              production_cost_float <- StreamData.float(min: 0.0, max: 10_000.0),
              price_float <- StreamData.float(min: 0.01, max: 10_000.0),
              pricing_type <- StreamData.member_of(StoreItem.pricing_types()),
              status <- StreamData.member_of(StoreItem.statuses()),
              delivery_methods <-
                StreamData.list_of(StreamData.member_of(StoreItem.delivery_methods()),
                  min_length: 1,
                  max_length: 4
                ),
              phone_visible <- StreamData.boolean()
            ) do
        production_cost = Decimal.from_float(production_cost_float) |> Decimal.round(2)
        price = Decimal.from_float(price_float) |> Decimal.round(2)
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        original = %StoreItem{
          id: System.unique_integer([:positive]),
          name: name,
          description: description,
          quantity: quantity,
          production_cost: production_cost,
          price: price,
          pricing_type: pricing_type,
          status: status,
          delivery_methods: Enum.uniq(delivery_methods),
          shipping_cost: nil,
          shipping_regions: nil,
          meeting_location: nil,
          phone_visible: phone_visible,
          user_id: System.unique_integer([:positive]),
          inserted_at: now,
          updated_at: now
        }

        # Serialize to JSON and back
        json_string = Jason.encode!(original)
        decoded_map = Jason.decode!(json_string)
        restored = StoreItem.from_json(decoded_map)

        # Verify all public fields are preserved
        assert restored.id == original.id
        assert restored.name == original.name
        assert restored.description == original.description
        assert restored.quantity == original.quantity
        assert Decimal.equal?(restored.production_cost, original.production_cost)
        assert Decimal.equal?(restored.price, original.price)
        assert restored.pricing_type == original.pricing_type
        assert restored.status == original.status
        assert restored.delivery_methods == original.delivery_methods
        assert restored.shipping_cost == original.shipping_cost
        assert restored.shipping_regions == original.shipping_regions
        assert restored.meeting_location == original.meeting_location
        assert restored.phone_visible == original.phone_visible
        assert restored.user_id == original.user_id
        assert DateTime.compare(restored.inserted_at, original.inserted_at) == :eq
        assert DateTime.compare(restored.updated_at, original.updated_at) == :eq
      end
    end

    property "JSON round-trip preserves optional decimal fields when present" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              shipping_cost_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods())
            ) do
        shipping_cost = Decimal.from_float(shipping_cost_float) |> Decimal.round(2)
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        original = %StoreItem{
          id: System.unique_integer([:positive]),
          name: name,
          description: nil,
          quantity: quantity,
          production_cost: nil,
          price: nil,
          pricing_type: "accepts_donation",
          status: "pending",
          delivery_methods: [delivery_method],
          shipping_cost: shipping_cost,
          shipping_regions: "US, Canada",
          meeting_location: "Downtown",
          phone_visible: true,
          user_id: System.unique_integer([:positive]),
          inserted_at: now,
          updated_at: now
        }

        json_string = Jason.encode!(original)
        decoded_map = Jason.decode!(json_string)
        restored = StoreItem.from_json(decoded_map)

        assert Decimal.equal?(restored.shipping_cost, original.shipping_cost)
        assert restored.shipping_regions == original.shipping_regions
        assert restored.meeting_location == original.meeting_location
      end
    end
  end
end
