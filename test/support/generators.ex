defmodule Sahajyog.Generators do
  @moduledoc """
  StreamData generators for property-based testing.
  """

  use ExUnitProperties

  alias Sahajyog.Accounts.User
  alias Sahajyog.Content.Video
  alias Sahajyog.Store.StoreItem

  @doc """
  Generates a user with a random level (Level1, Level2, Level3) or nil for unauthenticated.
  """
  def user_or_nil do
    one_of([
      constant(nil),
      user_with_level()
    ])
  end

  @doc """
  Generates a user struct with a random level.
  """
  def user_with_level do
    gen all(level <- member_of(["Level1", "Level2", "Level3"])) do
      %User{
        id: System.unique_integer([:positive]),
        email: "user#{System.unique_integer()}@example.com",
        level: level
      }
    end
  end

  @doc """
  Generates a user level string.
  """
  def user_level do
    member_of(["Level1", "Level2", "Level3"])
  end

  @doc """
  Generates a video category.
  """
  def video_category do
    member_of(["Welcome", "Getting Started", "Advanced Topics", "Excerpts"])
  end

  @doc """
  Generates a video struct with a random category.
  """
  def video do
    gen all(
          category <- video_category(),
          title <- string(:alphanumeric, min_length: 1, max_length: 50)
        ) do
      %Video{
        id: System.unique_integer([:positive]),
        title: title,
        url: "https://youtube.com/watch?v=#{System.unique_integer()}",
        category: category,
        provider: "youtube"
      }
    end
  end

  @doc """
  Generates a list of videos with various categories.
  """
  def video_list do
    list_of(video(), min_length: 0, max_length: 20)
  end

  @doc """
  Generates a pool size between 1 and 31.
  """
  def pool_size do
    integer(1..31)
  end

  @doc """
  Generates a pool size between 1 and a given max.
  """
  def pool_size(max) when max >= 1 do
    integer(1..min(max, 31))
  end

  @doc """
  Generates a valid pool position (1-31).
  """
  def pool_position do
    integer(1..31)
  end

  @doc """
  Generates an event level string (Level1, Level2, Level3, or nil).
  """
  def event_level do
    member_of(["Level1", "Level2", "Level3", nil])
  end

  @doc """
  Generates a non-nil event level string.
  """
  def event_level_non_nil do
    member_of(["Level1", "Level2", "Level3"])
  end

  @doc """
  Generates a resource level string (Level1, Level2, Level3).
  """
  def resource_level do
    member_of(["Level1", "Level2", "Level3"])
  end

  @doc """
  Generates a resource type string.
  """
  def resource_type do
    member_of(["Photos", "Books", "Music"])
  end

  # Store Item Generators

  @doc """
  Generates a valid store item name (1-200 characters).
  """
  def store_item_name do
    string(:alphanumeric, min_length: 1, max_length: 200)
  end

  @doc """
  Generates a store item name that exceeds the max length.
  """
  def store_item_name_too_long do
    string(:alphanumeric, min_length: 201, max_length: 250)
  end

  @doc """
  Generates a valid store item description (0-2000 characters).
  """
  def store_item_description do
    string(:alphanumeric, max_length: 2000)
  end

  @doc """
  Generates a store item description that exceeds the max length.
  """
  def store_item_description_too_long do
    string(:alphanumeric, min_length: 2001, max_length: 2100)
  end

  @doc """
  Generates a positive integer for quantity.
  """
  def store_item_quantity do
    positive_integer()
  end

  @doc """
  Generates a non-positive integer for invalid quantity.
  """
  def store_item_invalid_quantity do
    one_of([constant(0), integer(-100..-1)])
  end

  @doc """
  Generates a non-negative decimal for production cost.
  """
  def store_item_production_cost do
    gen all(value <- float(min: 0.0, max: 10000.0)) do
      Decimal.from_float(value) |> Decimal.round(2)
    end
  end

  @doc """
  Generates a negative decimal for invalid production cost.
  """
  def store_item_invalid_production_cost do
    gen all(value <- float(min: -10000.0, max: -0.01)) do
      Decimal.from_float(value) |> Decimal.round(2)
    end
  end

  @doc """
  Generates a positive decimal for price.
  """
  def store_item_price do
    gen all(value <- float(min: 0.01, max: 10000.0)) do
      Decimal.from_float(value) |> Decimal.round(2)
    end
  end

  @doc """
  Generates a store item pricing type.
  """
  def store_item_pricing_type do
    member_of(StoreItem.pricing_types())
  end

  @doc """
  Generates a store item currency.
  """
  def store_item_currency do
    member_of(StoreItem.currencies())
  end

  @doc """
  Generates a valid delivery method.
  """
  def store_item_delivery_method do
    member_of(StoreItem.delivery_methods())
  end

  @doc """
  Generates a non-empty list of valid delivery methods.
  """
  def store_item_delivery_methods do
    gen all(methods <- list_of(store_item_delivery_method(), min_length: 1, max_length: 4)) do
      Enum.uniq(methods)
    end
  end

  @doc """
  Generates valid store item attributes.
  """
  def store_item_attrs do
    gen all(
          name <- store_item_name(),
          description <- store_item_description(),
          quantity <- store_item_quantity(),
          production_cost <- store_item_production_cost(),
          pricing_type <- store_item_pricing_type(),
          currency <- store_item_currency(),
          delivery_methods <- store_item_delivery_methods(),
          price <- store_item_price()
        ) do
      attrs = %{
        name: name,
        description: description,
        quantity: quantity,
        production_cost: production_cost,
        pricing_type: pricing_type,
        currency: currency,
        delivery_methods: delivery_methods
      }

      # Add price only for fixed_price items
      if pricing_type == "fixed_price" do
        Map.put(attrs, :price, price)
      else
        attrs
      end
    end
  end
end
