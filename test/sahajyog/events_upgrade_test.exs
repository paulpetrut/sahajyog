defmodule Sahajyog.EventsUpgradeTest do
  use Sahajyog.DataCase

  alias Sahajyog.Admin
  alias Sahajyog.Events
  import Sahajyog.AccountsFixtures

  describe "level upgrade via AccessCode" do
    setup do
      user = user_fixture()
      {:ok, user: user}
    end

    test "admin can create access code and user can use it", %{user: user} do
      # Admin creates code
      {:ok, access_code} =
        Admin.create_access_code(%{
          "code" => "SUMMER-2025",
          "created_by_id" => user.id
        })

      assert access_code.code == "SUMMER-2025"

      # User attempts upgrade
      {:ok, updated_user} = Events.upgrade_user_via_code(user, "SUMMER-2025")
      assert updated_user.level == "Level2"
    end

    test "cannot upgrade with invalid code", %{user: user} do
      assert {:error, :invalid_code} = Events.upgrade_user_via_code(user, "WRONG-CODE")
    end

    test "enforces max uses", %{user: user} do
      # Create code with max 1 use
      {:ok, _code} =
        Admin.create_access_code(%{
          "code" => "LIMITED-1",
          "max_uses" => 1,
          "created_by_id" => user.id
        })

      # Use 1: Success
      {:ok, _} = Events.upgrade_user_via_code(user, "LIMITED-1")

      # User 2
      user2 = user_fixture()
      assert {:error, :code_max_uses_reached} = Events.upgrade_user_via_code(user2, "LIMITED-1")
    end
  end
end
