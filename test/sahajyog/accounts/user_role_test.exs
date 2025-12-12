defmodule Sahajyog.Accounts.UserRoleTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Accounts
  alias Sahajyog.Accounts.User

  # **Feature: role-level-simplification, Property 1: Default role assignment**
  # **Validates: Requirements 1.1**
  describe "Property 1: Default role assignment" do
    property "newly created users without explicit role get 'user' as default" do
      check all(email_suffix <- StreamData.positive_integer()) do
        # Use System.unique_integer to ensure unique emails across test runs
        email = "test_user_#{System.unique_integer([:positive])}_#{email_suffix}@example.com"

        {:ok, user} = Accounts.register_user(%{email: email})

        assert user.role == "user"
      end
    end

    test "User struct default role is 'user'" do
      user = %User{}
      assert user.role == "user"
    end
  end

  # **Feature: role-level-simplification, Property 2: Role validation**
  # **Validates: Requirements 1.2**
  describe "Property 2: Role validation" do
    property "system only accepts 'admin' or 'user' as valid roles" do
      valid_roles = MapSet.new(["admin", "user"])

      check all(role <- StreamData.string(:alphanumeric, min_length: 1, max_length: 20)) do
        is_valid = role in User.roles()
        expected_valid = MapSet.member?(valid_roles, role)
        assert is_valid == expected_valid
      end
    end

    test "roles/0 returns exactly ['admin', 'user']" do
      assert User.roles() == ["admin", "user"]
    end

    property "admin?/1 returns true only for users with role 'admin'" do
      check all(role <- StreamData.member_of(["admin", "user", "manager", "regular", "other"])) do
        user = %User{role: role}
        assert User.admin?(user) == (role == "admin")
      end
    end

    property "user?/1 returns true only for users with role 'user'" do
      check all(role <- StreamData.member_of(["admin", "user", "manager", "regular", "other"])) do
        user = %User{role: role}
        assert User.user?(user) == (role == "user")
      end
    end
  end

  # Unit tests for migration behavior
  # **Validates: Requirements 1.3, 1.4**
  describe "Migration behavior: role conversion" do
    test "database does not contain any 'regular' roles after migration" do
      import Ecto.Query

      regular_count =
        Sahajyog.Repo.one(from(u in User, where: u.role == "regular", select: count(u.id)))

      assert regular_count == 0
    end

    test "database does not contain any 'manager' roles after migration" do
      import Ecto.Query

      manager_count =
        Sahajyog.Repo.one(from(u in User, where: u.role == "manager", select: count(u.id)))

      assert manager_count == 0
    end

    test "database only contains 'admin' or 'user' roles" do
      import Ecto.Query

      invalid_roles_count =
        Sahajyog.Repo.one(
          from(u in User, where: u.role not in ["admin", "user"], select: count(u.id))
        )

      assert invalid_roles_count == 0
    end

    test "admin users remain unchanged (role is still 'admin')" do
      # Create an admin user and verify it stays admin
      email = "admin_test_#{System.unique_integer([:positive])}@example.com"
      {:ok, user} = Accounts.register_user(%{email: email})

      # Manually set to admin
      {:ok, admin_user} =
        user
        |> Ecto.Changeset.change(role: "admin")
        |> Sahajyog.Repo.update()

      # Reload and verify
      reloaded = Sahajyog.Repo.get!(User, admin_user.id)
      assert reloaded.role == "admin"
    end
  end
end
