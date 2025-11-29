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
    test "unauthenticated users can only access Welcome" do
      assert Content.accessible_categories(nil) == ["Welcome"]
    end

    test "Level3 users can access Welcome and Getting Started" do
      user = %User{level: "Level3"}
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

    test "Level1 users can access all categories" do
      user = %User{level: "Level1"}
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

    test "Level3 users cannot access Advanced Topics" do
      user = %User{level: "Level3"}
      refute Content.can_access_category?(user, "Advanced Topics")
    end

    test "Level1 users can access Advanced Topics" do
      user = %User{level: "Level1"}
      assert Content.can_access_category?(user, "Advanced Topics")
    end
  end
end
