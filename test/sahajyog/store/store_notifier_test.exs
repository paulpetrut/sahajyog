defmodule Sahajyog.Store.StoreNotifierTest do
  use Sahajyog.DataCase, async: true

  alias Sahajyog.Repo
  alias Sahajyog.Store.{StoreItem, StoreItemInquiry}
  alias Sahajyog.Store.StoreNotifier

  import Sahajyog.AccountsFixtures

  defp update_user_name(user, first_name, last_name) do
    user
    |> Ecto.Changeset.change(%{first_name: first_name, last_name: last_name})
    |> Repo.update!()
  end

  describe "deliver_item_approved/2" do
    test "sends approval email with required fields" do
      seller = user_fixture() |> update_user_name("John", "Doe")

      item = %StoreItem{
        id: 1,
        name: "Test Item",
        quantity: 5,
        pricing_type: "fixed_price",
        price: Decimal.new("25.00")
      }

      assert {:ok, email} = StoreNotifier.deliver_item_approved(item, seller)

      # Verify email is sent to seller
      assert [{_, recipient_email}] = email.to
      assert recipient_email == seller.email

      # Verify subject contains item name
      assert String.contains?(email.subject, "Test Item")
      assert String.contains?(email.subject, "approved")

      # Verify body contains required fields
      assert String.contains?(email.text_body, "John")
      assert String.contains?(email.text_body, "Test Item")
      assert String.contains?(email.text_body, "5")
      assert String.contains?(email.text_body, "Fixed Price")
    end

    test "formats donation pricing correctly" do
      seller = user_fixture() |> update_user_name("Jane", "Smith")

      item = %StoreItem{
        id: 2,
        name: "Donation Item",
        quantity: 1,
        pricing_type: "accepts_donation",
        price: nil
      }

      assert {:ok, email} = StoreNotifier.deliver_item_approved(item, seller)

      assert String.contains?(email.text_body, "Accepts Donation")
    end
  end

  describe "deliver_item_rejected/3" do
    test "sends rejection email with review notes" do
      seller = user_fixture() |> update_user_name("Alice", "Smith")

      item = %StoreItem{
        id: 3,
        name: "Rejected Item"
      }

      review_notes = "Please provide clearer photos of the item."

      assert {:ok, email} = StoreNotifier.deliver_item_rejected(item, seller, review_notes)

      # Verify email is sent to seller
      assert [{_, recipient_email}] = email.to
      assert recipient_email == seller.email

      # Verify subject contains item name
      assert String.contains?(email.subject, "Rejected Item")
      assert String.contains?(email.subject, "requires changes")

      # Verify body contains required fields
      assert String.contains?(email.text_body, "Alice")
      assert String.contains?(email.text_body, "Rejected Item")
      assert String.contains?(email.text_body, review_notes)
    end
  end

  describe "deliver_inquiry_to_seller/4" do
    test "sends inquiry email with buyer info and message" do
      seller = user_fixture() |> update_user_name("Bob", "Wilson")
      buyer = user_fixture() |> update_user_name("Carol", "Davis")

      item = %StoreItem{
        id: 4,
        name: "Inquiry Item"
      }

      inquiry = %StoreItemInquiry{
        id: 1,
        requested_quantity: 3,
        message: "Is this item still available?"
      }

      assert {:ok, email} = StoreNotifier.deliver_inquiry_to_seller(inquiry, item, seller, buyer)

      # Verify email is sent to seller
      assert [{_, recipient_email}] = email.to
      assert recipient_email == seller.email

      # Verify reply-to is set to buyer's email
      assert {_, reply_to_email} = email.reply_to
      assert reply_to_email == buyer.email

      # Verify subject contains item name
      assert String.contains?(email.subject, "Inquiry Item")
      assert String.contains?(email.subject, "inquiry")

      # Verify body contains buyer info
      assert String.contains?(email.text_body, "Carol")
      assert String.contains?(email.text_body, "Davis")
      assert String.contains?(email.text_body, buyer.email)

      # Verify body contains inquiry details
      assert String.contains?(email.text_body, "3")
      assert String.contains?(email.text_body, "Is this item still available?")
    end
  end
end
