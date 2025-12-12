defmodule Sahajyog.ResourcesLevelTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Resources
  alias Sahajyog.Generators

  import Sahajyog.AccountsFixtures

  describe "resources access levels" do
    setup do
      user = user_fixture()

      # Create resources at each level
      {:ok, resource_l1} =
        Resources.create_resource(
          valid_resource_attrs(%{title: "L1 Resource", level: "Level1", user_id: user.id})
        )

      {:ok, resource_l2} =
        Resources.create_resource(
          valid_resource_attrs(%{title: "L2 Resource", level: "Level2", user_id: user.id})
        )

      {:ok, resource_l3} =
        Resources.create_resource(
          valid_resource_attrs(%{title: "L3 Resource", level: "Level3", user_id: user.id})
        )

      %{l1: resource_l1, l2: resource_l2, l3: resource_l3, user: user}
    end

    test "list_resources filters by level", %{l1: l1, l2: l2, l3: l3} do
      # Level 1 user sees only Level1 resources
      resources = Resources.list_resources(%{level: "Level1"})
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      refute l2.id in ids
      refute l3.id in ids

      # Level 2 user sees Level1 + Level2 resources
      resources = Resources.list_resources(%{level: "Level2"})
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      refute l3.id in ids

      # Level 3 user sees all resources
      resources = Resources.list_resources(%{level: "Level3"})
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      assert l3.id in ids
    end

    test "list_resources_for_user filters by user level", %{l1: l1, l2: l2, l3: l3} do
      alias Sahajyog.Accounts

      # Level 1 user (default level)
      user_l1 = user_fixture()
      resources = Resources.list_resources_for_user(user_l1)
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      refute l2.id in ids
      refute l3.id in ids

      # Level 2 user
      user_l2 = user_fixture()
      {:ok, user_l2} = Accounts.update_user_level(user_l2, "Level2")
      resources = Resources.list_resources_for_user(user_l2)
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      refute l3.id in ids

      # Level 3 user
      user_l3 = user_fixture()
      {:ok, user_l3} = Accounts.update_user_level(user_l3, "Level3")
      resources = Resources.list_resources_for_user(user_l3)
      ids = Enum.map(resources, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      assert l3.id in ids
    end
  end

  defp valid_resource_attrs(attrs) do
    defaults = %{
      title: "Test Resource",
      file_name: "test_file_#{System.unique_integer()}.pdf",
      file_size: 1024,
      content_type: "application/pdf",
      r2_key: "resources/test_#{System.unique_integer()}.pdf",
      level: "Level1",
      resource_type: "Books"
    }

    Map.merge(defaults, attrs)
  end

  describe "resource level filtering property tests" do
    # **Feature: role-level-simplification, Property 5: Resource level filtering**
    # **Validates: Requirements 3.5**
    property "list_resources returns only resources with level <= user level" do
      check all(
              user_level <- Generators.resource_level(),
              resource_levels <-
                list_of(Generators.resource_level(), min_length: 1, max_length: 5),
              max_runs: 100
            ) do
        # Create a user to own the resources
        owner = user_fixture()

        # Create resources with various levels
        resources =
          Enum.map(resource_levels, fn level ->
            {:ok, resource} =
              Resources.create_resource(
                valid_resource_attrs(%{
                  title: "Resource #{System.unique_integer()}",
                  level: level,
                  user_id: owner.id
                })
              )

            resource
          end)

        # Get resources for the user level
        returned_resources = Resources.list_resources(%{level: user_level})
        returned_ids = Enum.map(returned_resources, & &1.id)

        # Define accessible levels based on user level
        # Level hierarchy: Level1 < Level2 < Level3 (higher levels have more access)
        accessible_levels =
          case user_level do
            "Level1" -> ["Level1"]
            "Level2" -> ["Level1", "Level2"]
            "Level3" -> ["Level1", "Level2", "Level3"]
          end

        # Property: All returned resources must have accessible levels
        Enum.each(returned_resources, fn resource ->
          assert resource.level in accessible_levels,
                 "Resource with level #{inspect(resource.level)} should not be accessible to user with level #{user_level}"
        end)

        # Property: All created resources with accessible levels should be returned
        expected_ids =
          resources
          |> Enum.filter(fn r -> r.level in accessible_levels end)
          |> Enum.map(& &1.id)
          |> MapSet.new()

        returned_created_ids =
          returned_ids
          |> Enum.filter(fn id -> id in Enum.map(resources, & &1.id) end)
          |> MapSet.new()

        assert MapSet.equal?(expected_ids, returned_created_ids),
               "All accessible resources should be returned and no inaccessible resources should be returned"
      end
    end

    # **Feature: role-level-simplification, Property 5: Resource level filtering**
    # **Validates: Requirements 3.5**
    property "resource level hierarchy is monotonic - higher levels see at least as many resources" do
      check all(
              resource_levels <-
                list_of(Generators.resource_level(), min_length: 1, max_length: 5),
              max_runs: 100
            ) do
        # Create a user to own the resources
        owner = user_fixture()

        # Create resources with various levels
        Enum.each(resource_levels, fn level ->
          {:ok, _resource} =
            Resources.create_resource(
              valid_resource_attrs(%{
                title: "Resource #{System.unique_integer()}",
                level: level,
                user_id: owner.id
              })
            )
        end)

        # Get resources for each level
        level1_resources = Resources.list_resources(%{level: "Level1"})
        level2_resources = Resources.list_resources(%{level: "Level2"})
        level3_resources = Resources.list_resources(%{level: "Level3"})

        level1_ids = Enum.map(level1_resources, & &1.id) |> MapSet.new()
        level2_ids = Enum.map(level2_resources, & &1.id) |> MapSet.new()
        level3_ids = Enum.map(level3_resources, & &1.id) |> MapSet.new()

        # Property: Level2 should see at least all resources Level1 sees
        assert MapSet.subset?(level1_ids, level2_ids),
               "Level2 should see all resources that Level1 sees"

        # Property: Level3 should see at least all resources Level2 sees
        assert MapSet.subset?(level2_ids, level3_ids),
               "Level3 should see all resources that Level2 sees"
      end
    end
  end
end
