defmodule Sahajyog.ContentPoolTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Content
  alias Sahajyog.Content.Video
  alias Sahajyog.Content.WeeklyVideoAssignment

  # Helper to clear all pool videos before each property iteration
  defp clear_pool do
    Repo.update_all(
      from(v in Video, where: v.in_pool == true),
      set: [in_pool: false, pool_position: nil]
    )
  end

  # Helper to create a Welcome video and add it to the pool
  defp create_pool_video(position \\ nil) do
    {:ok, video} =
      Content.create_video(%{
        title: "Welcome Video #{System.unique_integer()}",
        url: "https://youtube.com/watch?v=#{System.unique_integer()}",
        category: "Welcome",
        provider: "youtube"
      })

    if position do
      video
      |> Ecto.Changeset.change(%{in_pool: true, pool_position: position})
      |> Repo.update!()
    else
      video
    end
  end

  # Helper to create N videos in the pool with sequential positions
  defp create_pool_with_videos(count) when count >= 1 and count <= 31 do
    Enum.map(1..count, fn position ->
      create_pool_video(position)
    end)
  end

  describe "list_welcome_pool_videos/0" do
    test "returns empty list when no videos in pool" do
      assert Content.list_welcome_pool_videos() == []
    end

    test "returns videos ordered by pool_position" do
      _videos = create_pool_with_videos(3)

      pool_videos = Content.list_welcome_pool_videos()

      assert length(pool_videos) == 3
      assert Enum.map(pool_videos, & &1.pool_position) == [1, 2, 3]
    end
  end

  describe "add_to_welcome_pool/1" do
    test "adds a Welcome video to the pool" do
      video = create_pool_video()

      assert {:ok, updated} = Content.add_to_welcome_pool(video.id)
      assert updated.in_pool == true
      assert updated.pool_position == 1
    end

    test "returns error for non-existent video" do
      assert {:error, :video_not_found} = Content.add_to_welcome_pool(-1)
    end

    test "returns error for non-Welcome category video" do
      {:ok, video} =
        Content.create_video(%{
          title: "Advanced Video",
          url: "https://youtube.com/watch?v=test",
          category: "Advanced Topics",
          provider: "youtube"
        })

      assert {:error, :invalid_category} = Content.add_to_welcome_pool(video.id)
    end

    test "returns error when video already in pool" do
      video = create_pool_video(1)

      assert {:error, :already_in_pool} = Content.add_to_welcome_pool(video.id)
    end

    test "returns error when pool is full (31 videos)" do
      _videos = create_pool_with_videos(31)
      new_video = create_pool_video()

      assert {:error, :pool_full} = Content.add_to_welcome_pool(new_video.id)
    end
  end

  describe "remove_from_welcome_pool/1" do
    # **Feature: video-access-control-and-pools, Property 6: Pool Removal Renumbering**
    # **Validates: Requirements 2.5**
    property "remaining videos have sequential positions from 1 to N-1 after removal" do
      check all(
              pool_size <- integer(2..10),
              removal_index <- integer(0..(pool_size - 1)),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        videos = create_pool_with_videos(pool_size)
        video_to_remove = Enum.at(videos, removal_index)

        # Remove the video
        {:ok, _removed} = Content.remove_from_welcome_pool(video_to_remove.id)

        # Get remaining pool videos
        remaining = Content.list_welcome_pool_videos()

        # Property: Remaining videos should have sequential positions 1 to N-1
        assert length(remaining) == pool_size - 1

        positions = Enum.map(remaining, & &1.pool_position)
        expected_positions = Enum.to_list(1..(pool_size - 1))

        assert positions == expected_positions,
               "Positions should be sequential 1 to #{pool_size - 1}, got: #{inspect(positions)}"
      end
    end

    test "returns error for non-existent video" do
      assert {:error, :video_not_found} = Content.remove_from_welcome_pool(-1)
    end

    test "is idempotent for video not in pool" do
      video = create_pool_video()

      assert {:ok, returned} = Content.remove_from_welcome_pool(video.id)
      assert returned.in_pool == false
    end
  end

  describe "reorder_welcome_pool/1" do
    # **Feature: video-access-control-and-pools, Property 5: Pool Reorder Consistency**
    # **Validates: Requirements 2.3, 6.3**
    property "videos have positions 1 through N matching input order after reorder" do
      check all(
              pool_size <- integer(1..10),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        videos = create_pool_with_videos(pool_size)
        original_ids = Enum.map(videos, & &1.id)

        # Generate a random permutation of the IDs
        shuffled_ids = Enum.shuffle(original_ids)

        # Reorder the pool
        {:ok, reordered} = Content.reorder_welcome_pool(shuffled_ids)

        # Property: Videos should have positions 1 through N
        positions = Enum.map(reordered, & &1.pool_position)
        assert positions == Enum.to_list(1..pool_size)

        # Property: Order should match the input order
        reordered_ids = Enum.map(reordered, & &1.id)

        assert reordered_ids == shuffled_ids,
               "Reordered IDs should match input order"
      end
    end

    test "returns error for invalid video IDs" do
      videos = create_pool_with_videos(3)
      valid_ids = Enum.map(videos, & &1.id)

      # Try with an extra invalid ID
      assert {:error, :invalid_video_ids} =
               Content.reorder_welcome_pool(valid_ids ++ [-1])

      # Try with missing ID
      assert {:error, :invalid_video_ids} =
               Content.reorder_welcome_pool(Enum.take(valid_ids, 2))
    end
  end

  describe "shuffle_welcome_pool/0" do
    # **Feature: video-access-control-and-pools, Property 7: Pool Shuffle Validity**
    # **Validates: Requirements 2.6**
    property "all videos remain in pool with positions 1 through N after shuffle" do
      check all(
              pool_size <- integer(1..10),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        videos = create_pool_with_videos(pool_size)
        original_ids = MapSet.new(Enum.map(videos, & &1.id))

        # Shuffle the pool
        {:ok, shuffled} = Content.shuffle_welcome_pool()

        # Property: All N videos should still be in the pool
        assert length(shuffled) == pool_size

        # Property: Same video IDs should be present
        shuffled_ids = MapSet.new(Enum.map(shuffled, & &1.id))

        assert MapSet.equal?(original_ids, shuffled_ids),
               "Same videos should be in pool after shuffle"

        # Property: Positions should be 1 through N with no gaps or duplicates
        positions = Enum.map(shuffled, & &1.pool_position)

        assert Enum.sort(positions) == Enum.to_list(1..pool_size),
               "Positions should be sequential 1 to #{pool_size}"
      end
    end

    test "returns empty list for empty pool" do
      assert {:ok, []} = Content.shuffle_welcome_pool()
    end
  end

  describe "pool position validity" do
    # **Feature: video-access-control-and-pools, Property 4: Pool Position Validity**
    # **Validates: Requirements 2.1**
    property "pool positions are unique integers between 1 and 31" do
      check all(
              pool_size <- integer(1..15),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        _videos = create_pool_with_videos(pool_size)

        # Get pool videos
        pool_videos = Content.list_welcome_pool_videos()

        # Property: All positions should be between 1 and 31
        Enum.each(pool_videos, fn video ->
          assert video.pool_position >= 1 and video.pool_position <= 31,
                 "Position #{video.pool_position} should be between 1 and 31"
        end)

        # Property: No duplicate positions
        positions = Enum.map(pool_videos, & &1.pool_position)

        assert length(positions) == length(Enum.uniq(positions)),
               "Positions should be unique, got: #{inspect(positions)}"
      end
    end
  end

  describe "get_daily_video/1" do
    # **Feature: video-access-control-and-pools, Property 2: Daily Rotation Cycle**
    # **Validates: Requirements 5.1, 5.2, 5.3, 6.2**
    property "daily rotation cycles through pool positions correctly" do
      check all(
              pool_size <- integer(1..15),
              day_offset <- integer(0..100),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        _videos = create_pool_with_videos(pool_size)

        # Calculate the date based on offset from reference date
        reference_date = Content.reference_date()
        test_date = Date.add(reference_date, day_offset)

        # Get the daily video for this date
        daily_video = Content.get_daily_video(test_date)

        # Calculate expected position using the formula: rem(day_counter - 1, pool_size) + 1
        # day_counter = day_offset + 1 (since day 1 is the reference date)
        day_counter = day_offset + 1
        expected_position = rem(day_counter - 1, pool_size) + 1

        # Property: The returned video should have the expected position
        assert daily_video != nil, "Daily video should not be nil for non-empty pool"

        assert daily_video.pool_position == expected_position,
               "Day #{day_counter} with pool size #{pool_size} should select position #{expected_position}, got #{daily_video.pool_position}"

        # Property: Day 1 selects position 1
        day1_video = Content.get_daily_video(reference_date)
        assert day1_video.pool_position == 1, "Day 1 should select position 1"

        # Property: Day N selects position N (when N <= pool_size)
        if pool_size > 1 do
          day_n_date = Date.add(reference_date, pool_size - 1)
          day_n_video = Content.get_daily_video(day_n_date)

          assert day_n_video.pool_position == pool_size,
                 "Day #{pool_size} should select position #{pool_size}"
        end

        # Property: Day N+1 wraps back to position 1
        day_n_plus_1_date = Date.add(reference_date, pool_size)
        day_n_plus_1_video = Content.get_daily_video(day_n_plus_1_date)

        assert day_n_plus_1_video.pool_position == 1,
               "Day #{pool_size + 1} should wrap back to position 1"
      end
    end

    test "returns nil for empty pool" do
      clear_pool()
      assert Content.get_daily_video() == nil
    end

    # **Feature: video-access-control-and-pools, Property 3: Daily Video Determinism**
    # **Validates: Requirements 1.1, 1.2, 5.5**
    property "get_daily_video returns the same video for the same date regardless of caller" do
      check all(
              pool_size <- integer(1..15),
              day_offset <- integer(0..365),
              num_calls <- integer(2..10),
              max_runs: 100
            ) do
        # Clear pool before each iteration
        clear_pool()

        # Create pool with videos
        _videos = create_pool_with_videos(pool_size)

        # Calculate a test date
        reference_date = Content.reference_date()
        test_date = Date.add(reference_date, day_offset)

        # Call get_daily_video multiple times for the same date
        results =
          Enum.map(1..num_calls, fn _ ->
            Content.get_daily_video(test_date)
          end)

        # Property: All calls should return the same video
        first_result = hd(results)

        Enum.each(results, fn result ->
          assert result.id == first_result.id,
                 "All calls to get_daily_video for the same date should return the same video"

          assert result.pool_position == first_result.pool_position,
                 "All calls should return video at the same position"
        end)

        # Property: The result should be deterministic (same date = same video)
        # Call again to verify
        another_call = Content.get_daily_video(test_date)

        assert another_call.id == first_result.id,
               "Subsequent calls should return the same video"
      end
    end
  end

  # ============================================================================
  # Weekly Video Assignments
  # ============================================================================

  # Helper to create a video in a specific category
  defp create_video_in_category(category) do
    {:ok, video} =
      Content.create_video(%{
        title: "#{category} Video #{System.unique_integer()}",
        url: "https://youtube.com/watch?v=#{System.unique_integer()}",
        category: category,
        provider: "youtube"
      })

    video
  end

  # Helper to clear all weekly assignments
  defp clear_weekly_assignments do
    Repo.delete_all(WeeklyVideoAssignment)
  end

  describe "assign_videos_to_week/3" do
    # **Feature: video-access-control-and-pools, Property 8: Weekly Assignment Storage**
    # **Validates: Requirements 4.1, 7.3**
    property "querying assignments for year/week returns exactly the assigned video IDs" do
      check all(
              num_videos <- integer(1..5),
              year <- integer(2024..2030),
              week_number <- integer(1..53),
              max_runs: 100
            ) do
        # Clear assignments before each iteration
        clear_weekly_assignments()

        # Create videos in Advanced Topics category
        videos = Enum.map(1..num_videos, fn _ -> create_video_in_category("Advanced Topics") end)
        video_ids = Enum.map(videos, & &1.id)

        # Assign videos to the week
        {:ok, assignments} = Content.assign_videos_to_week(video_ids, year, week_number)

        # Property: The returned assignments should have exactly the video IDs we assigned
        assigned_video_ids = Enum.map(assignments, fn a -> a.video.id end) |> MapSet.new()
        expected_ids = MapSet.new(video_ids)

        assert MapSet.equal?(assigned_video_ids, expected_ids),
               "Assigned video IDs should match input IDs"

        # Property: Querying assignments for that year/week should return the same videos
        queried_assignments = Content.list_weekly_assignments(year, week_number)
        queried_video_ids = Enum.map(queried_assignments, fn a -> a.video.id end) |> MapSet.new()

        assert MapSet.equal?(queried_video_ids, expected_ids),
               "Queried assignments should match assigned video IDs"

        # Property: All assignments should have correct year and week_number
        Enum.each(assignments, fn assignment ->
          assert assignment.year == year, "Assignment year should match"
          assert assignment.week_number == week_number, "Assignment week_number should match"
        end)
      end
    end

    test "returns error for invalid week number (< 1)" do
      video = create_video_in_category("Advanced Topics")
      assert {:error, :invalid_week} = Content.assign_videos_to_week([video.id], 2025, 0)
    end

    test "returns error for invalid week number (> 53)" do
      video = create_video_in_category("Advanced Topics")
      assert {:error, :invalid_week} = Content.assign_videos_to_week([video.id], 2025, 54)
    end

    test "returns error for non-existent video" do
      assert {:error, :video_not_found} = Content.assign_videos_to_week([-1], 2025, 10)
    end

    test "returns empty list for empty video_ids" do
      assert {:ok, []} = Content.assign_videos_to_week([], 2025, 10)
    end

    test "handles upsert for re-assignments" do
      clear_weekly_assignments()
      video = create_video_in_category("Advanced Topics")

      # First assignment
      {:ok, _} = Content.assign_videos_to_week([video.id], 2025, 10)

      # Re-assign same video to same week (should upsert, not duplicate)
      {:ok, assignments} = Content.assign_videos_to_week([video.id], 2025, 10)

      assert length(assignments) == 1, "Should have exactly one assignment after upsert"
    end
  end

  describe "remove_video_from_week/3" do
    # **Feature: video-access-control-and-pools, Property 10: Weekly Assignment Partial Removal**
    # **Validates: Requirements 7.4**
    property "removing one video preserves all other video assignments for that week" do
      check all(
              num_videos <- integer(2..5),
              removal_index <- integer(0..(num_videos - 1)),
              year <- integer(2024..2030),
              week_number <- integer(1..53),
              max_runs: 100
            ) do
        # Clear assignments before each iteration
        clear_weekly_assignments()

        # Create videos in Advanced Topics category
        videos = Enum.map(1..num_videos, fn _ -> create_video_in_category("Advanced Topics") end)
        video_ids = Enum.map(videos, & &1.id)

        # Assign all videos to the week
        {:ok, _} = Content.assign_videos_to_week(video_ids, year, week_number)

        # Select a video to remove
        video_to_remove = Enum.at(videos, removal_index)
        remaining_video_ids = List.delete(video_ids, video_to_remove.id) |> MapSet.new()

        # Remove one video from the week
        {:ok, deleted_count} =
          Content.remove_video_from_week(video_to_remove.id, year, week_number)

        # Property: Exactly one assignment should be deleted
        assert deleted_count == 1, "Should delete exactly one assignment"

        # Property: All other videos should still be assigned to that week
        remaining_assignments = Content.list_weekly_assignments(year, week_number)

        remaining_assigned_ids =
          Enum.map(remaining_assignments, fn a -> a.video.id end) |> MapSet.new()

        assert MapSet.equal?(remaining_assigned_ids, remaining_video_ids),
               "Remaining assignments should preserve all other videos"

        # Property: The removed video should no longer be in the assignments
        refute MapSet.member?(remaining_assigned_ids, video_to_remove.id),
               "Removed video should not be in assignments"
      end
    end

    test "returns 0 when video is not assigned to the week" do
      clear_weekly_assignments()
      video = create_video_in_category("Advanced Topics")

      {:ok, deleted_count} = Content.remove_video_from_week(video.id, 2025, 10)
      assert deleted_count == 0
    end

    test "only removes assignment for specific year/week" do
      clear_weekly_assignments()
      video = create_video_in_category("Advanced Topics")

      # Assign to two different weeks
      {:ok, _} = Content.assign_videos_to_week([video.id], 2025, 10)
      {:ok, _} = Content.assign_videos_to_week([video.id], 2025, 11)

      # Remove from week 10 only
      {:ok, 1} = Content.remove_video_from_week(video.id, 2025, 10)

      # Week 10 should have no assignments
      assert Content.list_weekly_assignments(2025, 10) == []

      # Week 11 should still have the assignment
      week_11_assignments = Content.list_weekly_assignments(2025, 11)
      assert length(week_11_assignments) == 1
      assert hd(week_11_assignments).video.id == video.id
    end
  end

  describe "get_videos_for_week/3" do
    # **Feature: video-access-control-and-pools, Property 9: Weekly Video Retrieval**
    # **Validates: Requirements 4.2, 4.3, 5.4**
    property "returns exactly the videos assigned to that week for that category" do
      check all(
              num_advanced <- integer(1..3),
              num_excerpts <- integer(1..3),
              year <- integer(2024..2030),
              week_number <- integer(1..53),
              max_runs: 100
            ) do
        # Clear assignments before each iteration
        clear_weekly_assignments()

        # Create videos in both categories
        advanced_videos =
          Enum.map(1..num_advanced, fn _ -> create_video_in_category("Advanced Topics") end)

        excerpts_videos =
          Enum.map(1..num_excerpts, fn _ -> create_video_in_category("Excerpts") end)

        advanced_ids = Enum.map(advanced_videos, & &1.id)
        excerpts_ids = Enum.map(excerpts_videos, & &1.id)

        # Assign videos to the week
        {:ok, _} = Content.assign_videos_to_week(advanced_ids, year, week_number)
        {:ok, _} = Content.assign_videos_to_week(excerpts_ids, year, week_number)

        # Property: get_videos_for_week for "Advanced Topics" returns exactly those videos
        retrieved_advanced = Content.get_videos_for_week("Advanced Topics", year, week_number)
        retrieved_advanced_ids = Enum.map(retrieved_advanced, & &1.id) |> MapSet.new()

        assert MapSet.equal?(retrieved_advanced_ids, MapSet.new(advanced_ids)),
               "Should return exactly the Advanced Topics videos assigned to the week"

        # Property: All returned videos should be in the correct category
        Enum.each(retrieved_advanced, fn video ->
          assert video.category == "Advanced Topics",
                 "All returned videos should be Advanced Topics"
        end)

        # Property: get_videos_for_week for "Excerpts" returns exactly those videos
        retrieved_excerpts = Content.get_videos_for_week("Excerpts", year, week_number)
        retrieved_excerpts_ids = Enum.map(retrieved_excerpts, & &1.id) |> MapSet.new()

        assert MapSet.equal?(retrieved_excerpts_ids, MapSet.new(excerpts_ids)),
               "Should return exactly the Excerpts videos assigned to the week"

        # Property: All returned videos should be in the correct category
        Enum.each(retrieved_excerpts, fn video ->
          assert video.category == "Excerpts",
                 "All returned videos should be Excerpts"
        end)
      end
    end

    test "returns empty list when no videos assigned to week" do
      clear_weekly_assignments()
      assert Content.get_videos_for_week("Advanced Topics", 2025, 10) == []
    end

    test "returns empty list for category with no assignments even if other categories have assignments" do
      clear_weekly_assignments()
      video = create_video_in_category("Advanced Topics")
      {:ok, _} = Content.assign_videos_to_week([video.id], 2025, 10)

      # Excerpts should return empty even though Advanced Topics has assignments
      assert Content.get_videos_for_week("Excerpts", 2025, 10) == []
    end
  end
end
