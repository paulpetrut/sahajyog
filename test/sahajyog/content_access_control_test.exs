defmodule Sahajyog.ContentAccessControlTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Content
  alias Sahajyog.Accounts.User
  alias Sahajyog.Generators

  describe "access control" do
    # **Feature: video-access-control-and-pools, Property 1: Access Control by Level**
    # **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    property "videos returned match user's access level" do
      check all(
              user_or_nil <- Generators.user_or_nil(),
              categories_to_create <-
                list_of(Generators.video_category(), min_length: 1, max_length: 10),
              max_runs: 100
            ) do
        # Create videos in the database for each category
        videos =
          Enum.map(categories_to_create, fn category ->
            {:ok, video} =
              Content.create_video(%{
                title: "Test Video #{System.unique_integer()}",
                url: "https://youtube.com/watch?v=#{System.unique_integer()}",
                category: category,
                provider: "youtube"
              })

            video
          end)

        # Get videos for the user
        returned_videos = Content.list_videos_for_user(user_or_nil)

        # Get the expected accessible categories for this user
        accessible_cats = Content.accessible_categories(user_or_nil)

        # Property: All returned videos must have categories accessible to the user
        Enum.each(returned_videos, fn video ->
          assert video.category in accessible_cats,
                 "Video with category #{video.category} should not be accessible to user with level #{inspect(user_or_nil && user_or_nil.level)}"
        end)

        # Property: All created videos with accessible categories should be returned
        expected_video_ids =
          videos
          |> Enum.filter(fn v -> v.category in accessible_cats end)
          |> Enum.map(& &1.id)
          |> MapSet.new()

        returned_video_ids =
          returned_videos
          |> Enum.filter(fn v -> v.id in Enum.map(videos, & &1.id) end)
          |> Enum.map(& &1.id)
          |> MapSet.new()

        assert MapSet.subset?(expected_video_ids, returned_video_ids),
               "All accessible videos should be returned"
      end
    end
  end

  describe "accessible_categories/1" do
    test "unauthenticated users can access Welcome and Getting Started" do
      categories = Content.accessible_categories(nil)
      assert "Welcome" in categories
      assert "Getting Started" in categories
      refute "Advanced Topics" in categories
      refute "Excerpts" in categories
    end

    # Level hierarchy: Level1 < Level2 < Level3 (higher levels have more access)
    test "Level1 users can access Welcome and Getting Started only" do
      user = %User{level: "Level1"}
      categories = Content.accessible_categories(user)
      assert "Welcome" in categories
      assert "Getting Started" in categories
      refute "Advanced Topics" in categories
      refute "Excerpts" in categories
    end

    test "Level2 users can access all categories" do
      user = %User{level: "Level2"}
      categories = Content.accessible_categories(user)
      assert "Welcome" in categories
      assert "Getting Started" in categories
      assert "Advanced Topics" in categories
      assert "Excerpts" in categories
    end

    test "Level3 users can access all categories" do
      user = %User{level: "Level3"}
      categories = Content.accessible_categories(user)
      assert "Welcome" in categories
      assert "Getting Started" in categories
      assert "Advanced Topics" in categories
      assert "Excerpts" in categories
    end
  end

  describe "can_access_category?/2" do
    test "unauthenticated users can access Welcome" do
      assert Content.can_access_category?(nil, "Welcome")
    end

    test "unauthenticated users cannot access Advanced Topics" do
      refute Content.can_access_category?(nil, "Advanced Topics")
    end

    # Level hierarchy: Level1 < Level2 < Level3 (higher levels have more access)
    test "Level1 users cannot access Advanced Topics" do
      user = %User{level: "Level1"}
      refute Content.can_access_category?(user, "Advanced Topics")
    end

    test "Level2 users can access Advanced Topics" do
      user = %User{level: "Level2"}
      assert Content.can_access_category?(user, "Advanced Topics")
    end

    test "Level3 users can access Advanced Topics" do
      user = %User{level: "Level3"}
      assert Content.can_access_category?(user, "Advanced Topics")
    end
  end

  describe "video category access property tests" do
    # **Feature: role-level-simplification, Property 6: Video category access**
    # **Validates: Requirements 3.6, 5.1, 5.2, 5.3**
    property "higher levels include all lower-level category access" do
      check all(
              level <- Generators.user_level(),
              max_runs: 100
            ) do
        user = %User{level: level}
        accessible = Content.accessible_categories(user)

        # Define the expected category access based on level hierarchy
        # Level1 < Level2 < Level3 (higher levels have more access)
        base_categories = ["Welcome", "Getting Started"]
        advanced_categories = ["Advanced Topics", "Excerpts"]

        case level do
          "Level1" ->
            # Level1 users should only have access to base categories
            Enum.each(base_categories, fn cat ->
              assert cat in accessible,
                     "Level1 user should have access to #{cat}"
            end)

            Enum.each(advanced_categories, fn cat ->
              refute cat in accessible,
                     "Level1 user should NOT have access to #{cat}"
            end)

          "Level2" ->
            # Level2 users should have access to all categories
            Enum.each(base_categories ++ advanced_categories, fn cat ->
              assert cat in accessible,
                     "Level2 user should have access to #{cat}"
            end)

          "Level3" ->
            # Level3 users should have access to all categories (includes all lower levels)
            Enum.each(base_categories ++ advanced_categories, fn cat ->
              assert cat in accessible,
                     "Level3 user should have access to #{cat}"
            end)
        end
      end
    end

    # **Feature: role-level-simplification, Property 6: Video category access**
    # **Validates: Requirements 3.6, 5.1, 5.2, 5.3**
    property "level hierarchy is monotonic - higher levels have at least as much access" do
      check all(
              # Generate a random category to verify the hierarchy holds for any category
              category <- Generators.video_category(),
              max_runs: 100
            ) do
        level1_cats = Content.accessible_categories(%User{level: "Level1"}) |> MapSet.new()
        level2_cats = Content.accessible_categories(%User{level: "Level2"}) |> MapSet.new()
        level3_cats = Content.accessible_categories(%User{level: "Level3"}) |> MapSet.new()

        # Level2 should have at least all categories that Level1 has
        assert MapSet.subset?(level1_cats, level2_cats),
               "Level2 should have access to all categories Level1 has"

        # Level3 should have at least all categories that Level2 has
        assert MapSet.subset?(level2_cats, level3_cats),
               "Level3 should have access to all categories Level2 has"

        # If Level1 can access a category, Level2 and Level3 must also be able to
        if category in level1_cats do
          assert category in level2_cats,
                 "If Level1 can access #{category}, Level2 must also be able to"

          assert category in level3_cats,
                 "If Level1 can access #{category}, Level3 must also be able to"
        end

        # If Level2 can access a category, Level3 must also be able to
        if category in level2_cats do
          assert category in level3_cats,
                 "If Level2 can access #{category}, Level3 must also be able to"
        end
      end
    end
  end
end
