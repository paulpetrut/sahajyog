defmodule Sahajyog.StoreTest do
  use Sahajyog.DataCase, async: true
  use ExUnitProperties

  alias Sahajyog.Store
  alias Sahajyog.Store.{StoreItem, StoreItemMedia}
  alias Sahajyog.AccountsFixtures

  defp create_user do
    AccountsFixtures.user_fixture()
  end

  # **Feature: sahaj-store, Property 1: Item creation preserves all required fields**
  # **Validates: Requirements 1.1, 1.5**
  describe "Property 1: Item creation preserves all required fields" do
    property "creating an item preserves all provided field values" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              description <- StreamData.string(:alphanumeric, max_length: 500),
              quantity <- StreamData.positive_integer(),
              production_cost_float <- StreamData.float(min: 0.0, max: 1000.0),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        production_cost = Decimal.from_float(production_cost_float) |> Decimal.round(2)
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          description: description,
          quantity: quantity,
          production_cost: production_cost,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        assert item.name == name
        assert item.description == description || (description == "" && item.description == nil)
        assert item.quantity == quantity
        assert Decimal.equal?(item.production_cost, production_cost)
        assert Decimal.equal?(item.price, price)
        assert item.pricing_type == "fixed_price"
        assert delivery_method in item.delivery_methods
        assert item.inserted_at != nil
      end
    end
  end

  # **Feature: sahaj-store, Property 2: Item-user association integrity**
  # **Validates: Requirements 1.2**
  describe "Property 2: Item-user association integrity" do
    property "created item is associated with the creating user" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        assert item.user_id == user.id

        item_with_user = Store.get_item_with_media!(item.id)
        assert item_with_user.user.id == user.id
      end
    end
  end

  # **Feature: sahaj-store, Property 13: New items default to pending status**
  # **Validates: Requirements 4.1**
  describe "Property 13: New items default to pending status" do
    property "newly created items always have pending status" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)
        assert item.status == "pending"
      end
    end

    property "status cannot be overridden during creation" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              attempted_status <- StreamData.member_of(["approved", "rejected", "sold"]),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method],
          status: attempted_status
        }

        {:ok, item} = Store.create_item(attrs, user)
        assert item.status == "pending"
      end
    end
  end

  # **Feature: sahaj-store, Property 21: Edit resets approved status to pending**
  # **Validates: Requirements 6.2**
  describe "Property 21: Edit resets approved status to pending" do
    property "updating an approved item resets status to pending" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              new_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        admin = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)
        assert item.status == "pending"

        {:ok, approved_item} = Store.approve_item(item, admin)
        assert approved_item.status == "approved"

        {:ok, updated_item} = Store.update_item(approved_item, %{name: new_name}, user)
        assert updated_item.status == "pending"
      end
    end

    property "updating a pending item keeps status as pending" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              new_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)
        assert item.status == "pending"

        {:ok, updated_item} = Store.update_item(item, %{name: new_name}, user)
        assert updated_item.status == "pending"
      end
    end
  end

  # **Feature: sahaj-store, Property 23: Item deletion cascades to media**
  # **Validates: Requirements 6.4**
  describe "Property 23: Item deletion cascades to media" do
    property "deleting an item removes all associated media records" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              photo_count <- StreamData.integer(1..5),
              max_runs: 50
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        media_ids =
          for i <- 1..photo_count do
            media_attrs = %{
              file_name: "photo_#{i}.jpg",
              content_type: "image/jpeg",
              file_size: 1024,
              r2_key:
                "sahajaonline/sahajstore/#{item.id}/photo/#{Ecto.UUID.generate()}-photo_#{i}.jpg",
              media_type: "photo"
            }

            {:ok, media} = Store.add_media(item, media_attrs)
            media.id
          end

        assert length(media_ids) == photo_count

        {:ok, _deleted_item} = Store.delete_item(item)

        for media_id <- media_ids do
          assert Repo.get(StoreItemMedia, media_id) == nil
        end
      end
    end
  end

  # **Feature: sahaj-store, Property 14: Pending items query accuracy**
  # **Validates: Requirements 4.2**
  describe "Property 14: Pending items query accuracy" do
    property "list_pending_items returns exactly items with pending status" do
      check all(
              item_count <- StreamData.integer(1..5),
              max_runs: 50
            ) do
        user = create_user()
        admin = create_user()

        items =
          for i <- 1..item_count do
            attrs = %{
              name: "Item #{i}",
              quantity: 1,
              pricing_type: "fixed_price",
              price: Decimal.new("10.00"),
              delivery_methods: ["local_pickup"]
            }

            {:ok, item} = Store.create_item(attrs, user)
            item
          end

        approved_items =
          items
          |> Enum.take_random(div(item_count, 2))
          |> Enum.map(fn item ->
            {:ok, approved} = Store.approve_item(item, admin)
            approved
          end)

        approved_ids = Enum.map(approved_items, & &1.id)

        pending_items = Store.list_pending_items()

        for item <- pending_items do
          assert item.status == "pending"
        end

        pending_ids = Enum.map(pending_items, & &1.id)

        for approved_id <- approved_ids do
          refute approved_id in pending_ids
        end
      end
    end
  end

  # **Feature: sahaj-store, Property 17: Public listing shows only approved items**
  # **Validates: Requirements 4.6, 5.1**
  describe "Property 17: Public listing shows only approved items" do
    property "list_approved_items returns only items with approved status" do
      check all(
              item_count <- StreamData.integer(1..5),
              max_runs: 50
            ) do
        user = create_user()
        admin = create_user()

        items =
          for i <- 1..item_count do
            attrs = %{
              name: "Item #{i}",
              quantity: 1,
              pricing_type: "fixed_price",
              price: Decimal.new("10.00"),
              delivery_methods: ["local_pickup"]
            }

            {:ok, item} = Store.create_item(attrs, user)
            item
          end

        approved_items =
          items
          |> Enum.take_random(max(1, div(item_count, 2)))
          |> Enum.map(fn item ->
            {:ok, approved} = Store.approve_item(item, admin)
            approved
          end)

        approved_ids = MapSet.new(Enum.map(approved_items, & &1.id))

        public_items = Store.list_approved_items()

        for item <- public_items do
          assert item.status == "approved"
        end

        public_ids = MapSet.new(Enum.map(public_items, & &1.id))

        for approved_id <- approved_ids do
          assert approved_id in public_ids
        end
      end
    end
  end

  # **Feature: sahaj-store, Property 20: User items query returns all statuses**
  # **Validates: Requirements 6.1**
  describe "Property 20: User items query returns all statuses" do
    property "list_user_items returns all items for a user regardless of status" do
      check all(
              item_count <- StreamData.integer(1..5),
              max_runs: 50
            ) do
        user = create_user()
        admin = create_user()

        items =
          for i <- 1..item_count do
            attrs = %{
              name: "Item #{i}",
              quantity: 1,
              pricing_type: "fixed_price",
              price: Decimal.new("10.00"),
              delivery_methods: ["local_pickup"]
            }

            {:ok, item} = Store.create_item(attrs, user)
            item
          end

        item_ids = MapSet.new(Enum.map(items, & &1.id))

        items
        |> Enum.take_random(max(1, div(item_count, 2)))
        |> Enum.each(fn item ->
          Store.approve_item(item, admin)
        end)

        if item_count > 2 do
          item_to_sell = Enum.at(items, 0)
          {:ok, _} = Store.approve_item(item_to_sell, admin)
          Store.mark_item_sold(Repo.get!(StoreItem, item_to_sell.id))
        end

        user_items = Store.list_user_items(user.id)
        user_item_ids = MapSet.new(Enum.map(user_items, & &1.id))

        assert MapSet.equal?(item_ids, user_item_ids)
      end
    end
  end

  # **Feature: sahaj-store, Property 15: Approval state transition**
  # **Validates: Requirements 4.3**
  describe "Property 15: Approval state transition" do
    property "approving an item sets status to approved and records reviewer" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        admin = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)
        assert item.status == "pending"

        {:ok, approved_item} = Store.approve_item(item, admin)

        assert approved_item.status == "approved"
        assert approved_item.reviewed_by_id == admin.id
      end
    end
  end

  # **Feature: sahaj-store, Property 16: Rejection requires review notes**
  # **Validates: Requirements 4.4**
  describe "Property 16: Rejection requires review notes" do
    property "rejecting an item without review notes fails" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        admin = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        {:error, changeset} = Store.reject_item(item, admin, nil)
        assert {:review_notes, _} = List.keyfind(changeset.errors, :review_notes, 0)

        {:error, changeset} = Store.reject_item(item, admin, "")
        assert {:review_notes, _} = List.keyfind(changeset.errors, :review_notes, 0)
      end
    end

    property "rejecting an item with review notes succeeds" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              review_notes <- StreamData.string(:alphanumeric, min_length: 1, max_length: 500),
              max_runs: 100
            ) do
        user = create_user()
        admin = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        {:ok, rejected_item} = Store.reject_item(item, admin, review_notes)

        assert rejected_item.status == "rejected"
        assert rejected_item.reviewed_by_id == admin.id
        assert rejected_item.review_notes == review_notes
      end
    end
  end

  # **Feature: sahaj-store, Property 22: Mark sold state transition**
  # **Validates: Requirements 6.3**
  describe "Property 22: Mark sold state transition" do
    property "marking an item as sold sets status to sold" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        {:ok, sold_item} = Store.mark_item_sold(item)

        assert sold_item.status == "sold"
      end
    end
  end

  # **Feature: sahaj-store, Property 5: Photo count limit enforcement**
  # **Validates: Requirements 2.1, 2.3**
  describe "Property 5: Photo count limit enforcement" do
    property "adding photos succeeds when under limit and fails when at limit" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 50
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        # Add 5 photos (should all succeed)
        for i <- 1..5 do
          media_attrs = %{
            file_name: "photo_#{i}.jpg",
            content_type: "image/jpeg",
            file_size: 1024,
            r2_key:
              "sahajaonline/sahajstore/#{item.id}/photo/#{Ecto.UUID.generate()}-photo_#{i}.jpg",
            media_type: "photo"
          }

          {:ok, _media} = Store.add_media(item, media_attrs)
        end

        assert Store.count_photos(item.id) == 5

        # 6th photo should fail
        media_attrs = %{
          file_name: "photo_6.jpg",
          content_type: "image/jpeg",
          file_size: 1024,
          r2_key: "sahajaonline/sahajstore/#{item.id}/photo/#{Ecto.UUID.generate()}-photo_6.jpg",
          media_type: "photo"
        }

        assert {:error, :photo_limit_exceeded} = Store.add_media(item, media_attrs)
        assert Store.count_photos(item.id) == 5
      end
    end
  end

  # **Feature: sahaj-store, Property 6: Video count limit enforcement**
  # **Validates: Requirements 2.2, 2.4**
  describe "Property 6: Video count limit enforcement" do
    property "adding video succeeds when none exists and fails when one exists" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 50
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        # First video should succeed
        media_attrs = %{
          file_name: "video_1.mp4",
          content_type: "video/mp4",
          file_size: 10240,
          r2_key: "sahajaonline/sahajstore/#{item.id}/video/#{Ecto.UUID.generate()}-video_1.mp4",
          media_type: "video"
        }

        {:ok, _media} = Store.add_media(item, media_attrs)
        assert Store.count_videos(item.id) == 1

        # Second video should fail
        media_attrs2 = %{
          file_name: "video_2.mp4",
          content_type: "video/mp4",
          file_size: 10240,
          r2_key: "sahajaonline/sahajstore/#{item.id}/video/#{Ecto.UUID.generate()}-video_2.mp4",
          media_type: "video"
        }

        assert {:error, :video_limit_exceeded} = Store.add_media(item, media_attrs2)
        assert Store.count_videos(item.id) == 1
      end
    end
  end

  # **Feature: sahaj-store, Property 8: Media metadata completeness**
  # **Validates: Requirements 2.6**
  describe "Property 8: Media metadata completeness" do
    property "uploaded media has all required metadata fields" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 50),
              file_size <- StreamData.positive_integer(),
              max_runs: 50
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        r2_key =
          "sahajaonline/sahajstore/#{item.id}/photo/#{Ecto.UUID.generate()}-#{file_name}.jpg"

        media_attrs = %{
          file_name: "#{file_name}.jpg",
          content_type: "image/jpeg",
          file_size: file_size,
          r2_key: r2_key,
          media_type: "photo"
        }

        {:ok, media} = Store.add_media(item, media_attrs)

        assert media.file_name != nil
        assert media.content_type != nil
        assert media.r2_key != nil
        assert media.media_type != nil
        assert media.file_size != nil
      end
    end
  end

  # **Feature: sahaj-store, Property 18: Inquiry quantity validation**
  # **Validates: Requirements 5.6, 5.7**
  describe "Property 18: Inquiry quantity validation" do
    property "inquiry quantity must be positive and not exceed available quantity" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              item_quantity <- StreamData.integer(1..100),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 50
            ) do
        user = create_user()
        buyer = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: item_quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        # Valid quantity should succeed
        valid_quantity = max(1, div(item_quantity, 2))
        inquiry_attrs = %{message: "I'm interested", requested_quantity: valid_quantity}
        {:ok, inquiry} = Store.create_inquiry(item, buyer, inquiry_attrs)
        assert inquiry.requested_quantity == valid_quantity

        # Quantity exceeding available should fail
        invalid_quantity = item_quantity + 1
        inquiry_attrs2 = %{message: "I want more", requested_quantity: invalid_quantity}
        {:error, changeset} = Store.create_inquiry(item, buyer, inquiry_attrs2)
        assert {:requested_quantity, _} = List.keyfind(changeset.errors, :requested_quantity, 0)

        # Zero or negative quantity should fail
        inquiry_attrs3 = %{message: "Zero items", requested_quantity: 0}
        {:error, changeset} = Store.create_inquiry(item, buyer, inquiry_attrs3)
        assert {:requested_quantity, _} = List.keyfind(changeset.errors, :requested_quantity, 0)
      end
    end
  end

  # **Feature: sahaj-store, Property 19: Inquiry record completeness**
  # **Validates: Requirements 5.8**
  describe "Property 19: Inquiry record completeness" do
    property "submitted inquiry has all required fields" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              item_quantity <- StreamData.integer(1..100),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              message <- StreamData.string(:alphanumeric, min_length: 1, max_length: 500),
              max_runs: 50
            ) do
        user = create_user()
        buyer = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: item_quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)

        requested_quantity = max(1, div(item_quantity, 2))
        inquiry_attrs = %{message: message, requested_quantity: requested_quantity}
        {:ok, inquiry} = Store.create_inquiry(item, buyer, inquiry_attrs)

        assert inquiry.buyer_id == buyer.id
        assert inquiry.store_item_id == item.id
        assert inquiry.requested_quantity == requested_quantity
        assert inquiry.message == message
        assert inquiry.inserted_at != nil
      end
    end
  end

  # **Feature: sahaj-store, Property 3: Phone visibility controls display**
  # **Validates: Requirements 1.3, 1.4, 5.5**
  describe "Property 3: Phone visibility controls display" do
    property "phone is included in public data when phone_visible is true" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method],
          phone_visible: true
        }

        {:ok, item} = Store.create_item(attrs, user)
        item_with_user = Store.get_item_with_media!(item.id)

        # Use the same function as the LiveView to get public seller info
        seller_info = SahajyogWeb.StoreItemShowLive.get_public_seller_info(item_with_user)

        assert item_with_user.phone_visible == true
        assert Map.has_key?(seller_info, :phone)
        assert seller_info.phone == user.phone_number
      end
    end

    property "phone is excluded from public data when phone_visible is false" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method],
          phone_visible: false
        }

        {:ok, item} = Store.create_item(attrs, user)
        item_with_user = Store.get_item_with_media!(item.id)

        # Use the same function as the LiveView to get public seller info
        seller_info = SahajyogWeb.StoreItemShowLive.get_public_seller_info(item_with_user)

        assert item_with_user.phone_visible == false
        refute Map.has_key?(seller_info, :phone)
      end
    end

    property "phone visibility defaults to false" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        # Don't specify phone_visible - should default to false
        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method]
        }

        {:ok, item} = Store.create_item(attrs, user)
        item_with_user = Store.get_item_with_media!(item.id)

        # Use the same function as the LiveView to get public seller info
        seller_info = SahajyogWeb.StoreItemShowLive.get_public_seller_info(item_with_user)

        assert item_with_user.phone_visible == false
        refute Map.has_key?(seller_info, :phone)
      end
    end

    property "public seller info always includes name and email regardless of phone visibility" do
      check all(
              name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 200),
              quantity <- StreamData.positive_integer(),
              price_float <- StreamData.float(min: 0.01, max: 1000.0),
              delivery_method <- StreamData.member_of(StoreItem.delivery_methods()),
              phone_visible <- StreamData.boolean(),
              max_runs: 100
            ) do
        user = create_user()
        price = Decimal.from_float(price_float) |> Decimal.round(2)

        attrs = %{
          name: name,
          quantity: quantity,
          pricing_type: "fixed_price",
          price: price,
          delivery_methods: [delivery_method],
          phone_visible: phone_visible
        }

        {:ok, item} = Store.create_item(attrs, user)
        item_with_user = Store.get_item_with_media!(item.id)

        # Use the same function as the LiveView to get public seller info
        seller_info = SahajyogWeb.StoreItemShowLive.get_public_seller_info(item_with_user)

        # Name and email should always be present
        assert Map.has_key?(seller_info, :first_name)
        assert Map.has_key?(seller_info, :last_name)
        assert Map.has_key?(seller_info, :email)
        assert seller_info.email == user.email
      end
    end
  end
end
