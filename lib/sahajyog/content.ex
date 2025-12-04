defmodule Sahajyog.Content do
  @moduledoc """
  The Content context for managing videos.
  """

  import Ecto.Query, warn: false
  alias Sahajyog.Repo
  alias Sahajyog.Content.Video
  alias Sahajyog.Content.WeeklyVideoAssignment
  alias Sahajyog.Accounts.User

  # Category access rules - maps each category to the levels that can access it
  # :public means accessible to unauthenticated users
  @category_access %{
    "Welcome" => [:public, "Level1", "Level2", "Level3"],
    "Getting Started" => [:public, "Level1", "Level2", "Level3"],
    "Advanced Topics" => ["Level1", "Level2"],
    "Excerpts" => ["Level1", "Level2"]
  }

  @doc """
  Returns the list of categories accessible to a user based on their level.

  ## Examples

      iex> accessible_categories(nil)
      ["Welcome"]

      iex> accessible_categories(%User{level: "Level3"})
      ["Welcome", "Getting Started"]

      iex> accessible_categories(%User{level: "Level1"})
      ["Welcome", "Getting Started", "Advanced Topics", "Excerpts"]
  """
  def accessible_categories(nil) do
    # Unauthenticated users can only access categories with :public
    @category_access
    |> Enum.filter(fn {_category, levels} -> :public in levels end)
    |> Enum.map(fn {category, _levels} -> category end)
  end

  def accessible_categories(%User{level: level}) when level in ["Level1", "Level2", "Level3"] do
    @category_access
    |> Enum.filter(fn {_category, levels} -> level in levels end)
    |> Enum.map(fn {category, _levels} -> category end)
  end

  def accessible_categories(_user) do
    # Default to most restrictive for invalid/unknown users
    accessible_categories(nil)
  end

  @doc """
  Checks if a user can access a specific category.

  ## Examples

      iex> can_access_category?(nil, "Welcome")
      true

      iex> can_access_category?(nil, "Advanced Topics")
      false

      iex> can_access_category?(%User{level: "Level1"}, "Advanced Topics")
      true
  """
  def can_access_category?(user, category) do
    category in accessible_categories(user)
  end

  @doc """
  Returns the category access configuration map.
  Useful for testing and introspection.
  """
  def category_access_config, do: @category_access

  def list_videos do
    Repo.all(from v in Video, order_by: [desc: v.inserted_at])
  end

  def list_videos_ordered do
    Repo.all(from v in Video, order_by: [asc: v.step_number, desc: v.inserted_at])
  end

  def list_videos_by_category(category) do
    Repo.all(from v in Video, where: v.category == ^category, order_by: [desc: v.inserted_at])
  end

  @doc """
  Returns videos filtered by the user's access level.

  For unauthenticated users (nil), returns only Welcome videos.
  For Level3 users, returns Welcome and Getting Started videos.
  For Level1/Level2 users, returns all categories.

  ## Examples

      iex> list_videos_for_user(nil)
      [%Video{category: "Welcome", ...}]

      iex> list_videos_for_user(%User{level: "Level1"})
      [%Video{}, ...]  # All categories
  """
  def list_videos_for_user(user) do
    categories = accessible_categories(user)

    Repo.all(
      from v in Video,
        where: v.category in ^categories,
        order_by: [asc: v.step_number, desc: v.inserted_at]
    )
  end

  @doc """
  Returns videos for a specific category, filtered by user access.

  Returns empty list if user doesn't have access to the category.
  """
  def list_videos_for_user(user, category) do
    if can_access_category?(user, category) do
      list_videos_by_category(category)
    else
      []
    end
  end

  def get_video!(id), do: Repo.get!(Video, id)

  def create_video(attrs \\ %{}) do
    Repo.transaction(fn ->
      changeset = Video.changeset(%Video{}, attrs)

      # Get category from changeset
      category = Ecto.Changeset.get_field(changeset, :category)

      # If step_number is provided, shift existing videos in the same category
      case Ecto.Changeset.fetch_change(changeset, :step_number) do
        {:ok, step_number} when not is_nil(step_number) and not is_nil(category) ->
          shift_videos_up(step_number, category, nil)

        _ ->
          :ok
      end

      case Repo.insert(changeset) do
        {:ok, video} -> video
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def update_video(%Video{} = video, attrs) do
    Repo.transaction(fn ->
      changeset = Video.changeset(video, attrs)

      old_category = video.category
      new_category = Ecto.Changeset.get_field(changeset, :category)
      old_step_number = video.step_number
      new_step_number = Ecto.Changeset.get_field(changeset, :step_number)

      cond do
        # Category changed - handle moving between categories
        old_category != new_category ->
          # Shift down in old category
          if old_step_number do
            shift_videos_down(old_step_number + 1, old_category, video.id)
          end

          # Shift up in new category
          if new_step_number do
            shift_videos_up(new_step_number, new_category, video.id)
          end

        # Same category but step_number changed
        old_step_number != new_step_number and not is_nil(new_step_number) ->
          # Shift down videos in the old range
          if old_step_number do
            shift_videos_down(old_step_number + 1, old_category, video.id)
          end

          # Shift up videos at the new position
          shift_videos_up(new_step_number, new_category, video.id)

        true ->
          :ok
      end

      case Repo.update(changeset) do
        {:ok, video} -> video
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def delete_video(%Video{} = video) do
    Repo.transaction(fn ->
      case Repo.delete(video) do
        {:ok, deleted_video} ->
          # Shift down videos that were after this one in the same category
          if video.step_number && video.category do
            shift_videos_down(video.step_number + 1, video.category, nil)
          end

          deleted_video

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  # Shift videos up (increment step_number) for videos at or above the given step in the same category
  defp shift_videos_up(from_step, category, exclude_id) do
    query =
      from v in Video,
        where: v.step_number >= ^from_step and v.category == ^category

    query =
      if exclude_id do
        from v in query, where: v.id != ^exclude_id
      else
        query
      end

    Repo.update_all(query, inc: [step_number: 1])
  end

  # Shift videos down (decrement step_number) for videos at or above the given step in the same category
  defp shift_videos_down(from_step, category, exclude_id) do
    query =
      from v in Video,
        where: v.step_number >= ^from_step and v.category == ^category

    query =
      if exclude_id do
        from v in query, where: v.id != ^exclude_id
      else
        query
      end

    Repo.update_all(query, inc: [step_number: -1])
  end

  def change_video(%Video{} = video, attrs \\ %{}) do
    Video.changeset(video, attrs)
  end

  @doc """
  Returns the next available step number for a given category (max + 1, or 1 if no videos exist)
  """
  def next_step_number(category) when is_binary(category) do
    case Repo.one(from v in Video, where: v.category == ^category, select: max(v.step_number)) do
      nil -> 1
      max_step when is_integer(max_step) -> max_step + 1
      _ -> 1
    end
  end

  def next_step_number(_), do: 1

  # ============================================================================
  # Welcome Pool Management
  # ============================================================================

  @max_pool_size 31

  @doc """
  Returns all videos in the Welcome pool, ordered by pool_position.

  ## Examples

      iex> list_welcome_pool_videos()
      [%Video{pool_position: 1, ...}, %Video{pool_position: 2, ...}]
  """
  def list_welcome_pool_videos do
    Repo.all(
      from v in Video,
        where: v.category == "Welcome" and v.in_pool == true,
        order_by: [asc: v.pool_position]
    )
  end

  @doc """
  Adds a video to the Welcome pool.

  Returns `{:ok, video}` on success, or an error tuple:
  - `{:error, :video_not_found}` if video doesn't exist
  - `{:error, :invalid_category}` if video is not in Welcome category
  - `{:error, :pool_full}` if pool already has 31 videos
  - `{:error, :already_in_pool}` if video is already in the pool

  ## Examples

      iex> add_to_welcome_pool(video_id)
      {:ok, %Video{in_pool: true, pool_position: 5}}

      iex> add_to_welcome_pool(non_welcome_video_id)
      {:error, :invalid_category}
  """
  def add_to_welcome_pool(video_id) do
    case Repo.get(Video, video_id) do
      nil ->
        {:error, :video_not_found}

      %Video{category: category} when category != "Welcome" ->
        {:error, :invalid_category}

      %Video{in_pool: true} ->
        {:error, :already_in_pool}

      video ->
        pool_size = get_welcome_pool_size()

        if pool_size >= @max_pool_size do
          {:error, :pool_full}
        else
          next_position = pool_size + 1

          video
          |> Video.changeset(%{in_pool: true, pool_position: next_position})
          |> Repo.update()
        end
    end
  end

  defp get_welcome_pool_size do
    Repo.one(
      from v in Video,
        where: v.category == "Welcome" and v.in_pool == true,
        select: count(v.id)
    )
  end

  @doc """
  Removes a video from the Welcome pool and renumbers remaining videos sequentially.

  Returns `{:ok, video}` on success. If the video is not in the pool,
  returns `{:ok, video}` (idempotent operation).

  ## Examples

      iex> remove_from_welcome_pool(video_id)
      {:ok, %Video{in_pool: false, pool_position: nil}}
  """
  def remove_from_welcome_pool(video_id) do
    case Repo.get(Video, video_id) do
      nil ->
        {:error, :video_not_found}

      %Video{in_pool: false} = video ->
        # Idempotent - already not in pool
        {:ok, video}

      %Video{in_pool: true, pool_position: removed_position} = video ->
        Repo.transaction(fn ->
          # Remove the video from pool
          {:ok, updated_video} =
            video
            |> Video.changeset(%{in_pool: false, pool_position: nil})
            |> Repo.update()

          # Renumber remaining videos to fill the gap
          renumber_pool_after_removal(removed_position)

          updated_video
        end)
    end
  end

  defp renumber_pool_after_removal(removed_position) do
    # Decrement pool_position for all videos with position > removed_position
    from(v in Video,
      where: v.category == "Welcome" and v.in_pool == true and v.pool_position > ^removed_position
    )
    |> Repo.update_all(inc: [pool_position: -1])
  end

  @doc """
  Reorders videos in the Welcome pool according to the given list of video IDs.

  The first ID in the list gets position 1, second gets position 2, etc.
  Uses a transaction for atomicity.

  Returns `{:ok, videos}` on success with the reordered videos,
  or `{:error, :invalid_video_ids}` if any ID is not in the pool.

  ## Examples

      iex> reorder_welcome_pool([3, 1, 2])
      {:ok, [%Video{id: 3, pool_position: 1}, %Video{id: 1, pool_position: 2}, ...]}
  """
  def reorder_welcome_pool(video_ids) when is_list(video_ids) do
    Repo.transaction(fn ->
      # Get all pool videos to validate
      pool_videos = list_welcome_pool_videos()
      pool_video_ids = MapSet.new(Enum.map(pool_videos, & &1.id))
      requested_ids = MapSet.new(video_ids)

      # Validate that all requested IDs are in the pool and vice versa
      if MapSet.equal?(pool_video_ids, requested_ids) do
        # Update each video's position
        video_ids
        |> Enum.with_index(1)
        |> Enum.each(fn {video_id, position} ->
          from(v in Video, where: v.id == ^video_id)
          |> Repo.update_all(set: [pool_position: position])
        end)

        # Return the reordered videos
        list_welcome_pool_videos()
      else
        Repo.rollback(:invalid_video_ids)
      end
    end)
  end

  @doc """
  Randomly shuffles all videos in the Welcome pool.

  Gets all pool videos, randomizes their order using Enum.shuffle,
  and calls reorder_welcome_pool with the shuffled IDs.

  Returns `{:ok, videos}` with the shuffled videos,
  or `{:ok, []}` if the pool is empty.

  ## Examples

      iex> shuffle_welcome_pool()
      {:ok, [%Video{pool_position: 1}, %Video{pool_position: 2}, ...]}
  """
  def shuffle_welcome_pool do
    pool_videos = list_welcome_pool_videos()

    case pool_videos do
      [] ->
        {:ok, []}

      videos ->
        shuffled_ids =
          videos
          |> Enum.shuffle()
          |> Enum.map(& &1.id)

        reorder_welcome_pool(shuffled_ids)
    end
  end

  # ============================================================================
  # Daily Video Rotation
  # ============================================================================

  # Reference date for day counter calculation (January 1, 2025)
  @reference_date ~D[2025-01-01]

  @doc """
  Returns the reference date used for daily video rotation calculation.
  Useful for testing and debugging.
  """
  def reference_date, do: @reference_date

  @doc """
  Returns today's video from the Welcome pool based on deterministic rotation.

  The rotation uses a day counter starting from a reference date (January 1, 2025).
  The position is calculated as: `rem(day_counter - 1, pool_size) + 1`

  This ensures:
  - Day 1 selects position 1
  - Day N selects position N
  - Day N+1 wraps back to position 1

  Returns `nil` if the pool is empty.

  ## Examples

      iex> get_daily_video()
      %Video{pool_position: 3, ...}

      iex> get_daily_video()  # Empty pool
      nil
  """
  def get_daily_video do
    get_daily_video(Date.utc_today())
  end

  @doc """
  Returns the video for a specific date from the Welcome pool.

  This variant allows specifying a date for testing and preview purposes.

  ## Examples

      iex> get_daily_video(~D[2025-01-15])
      %Video{pool_position: 15, ...}
  """
  def get_daily_video(date) do
    pool_size = get_welcome_pool_size()

    if pool_size == 0 do
      nil
    else
      position = calculate_daily_position(date, pool_size)
      get_video_at_pool_position(position)
    end
  end

  @doc """
  Calculates the pool position for a given date.

  Uses the formula: `rem(day_counter - 1, pool_size) + 1`
  where day_counter is the number of days since the reference date + 1.

  ## Examples

      iex> calculate_daily_position(~D[2025-01-01], 5)
      1

      iex> calculate_daily_position(~D[2025-01-05], 5)
      5

      iex> calculate_daily_position(~D[2025-01-06], 5)
      1
  """
  def calculate_daily_position(date, pool_size) when pool_size > 0 do
    day_counter = Date.diff(date, @reference_date) + 1
    rem(day_counter - 1, pool_size) + 1
  end

  defp get_video_at_pool_position(position) do
    Repo.one(
      from v in Video,
        where: v.category == "Welcome" and v.in_pool == true and v.pool_position == ^position
    )
  end

  # ============================================================================
  # Weekly Video Assignments
  # ============================================================================

  @doc """
  Assigns videos to a specific week.

  Creates WeeklyVideoAssignment records for each video ID. Uses upsert to handle
  re-assignments (if a video is already assigned to that week, it's updated).

  Returns `{:ok, assignments}` on success, or an error tuple:
  - `{:error, :invalid_week}` if week_number is not between 1 and 53
  - `{:error, :video_not_found}` if any video ID doesn't exist

  ## Examples

      iex> assign_videos_to_week([1, 2, 3], 2025, 10)
      {:ok, [%WeeklyVideoAssignment{}, ...]}

      iex> assign_videos_to_week([1], 2025, 54)
      {:error, :invalid_week}
  """
  def assign_videos_to_week(video_ids, year, week_number)
      when is_list(video_ids) and is_integer(year) and is_integer(week_number) do
    cond do
      week_number < 1 or week_number > 53 ->
        {:error, :invalid_week}

      video_ids == [] ->
        {:ok, []}

      true ->
        # Verify all videos exist
        existing_videos =
          Repo.all(from v in Video, where: v.id in ^video_ids, select: v.id)

        missing_ids = MapSet.difference(MapSet.new(video_ids), MapSet.new(existing_videos))

        if MapSet.size(missing_ids) > 0 do
          {:error, :video_not_found}
        else
          Repo.transaction(fn ->
            now = DateTime.utc_now() |> DateTime.truncate(:second)

            assignments =
              Enum.map(video_ids, fn video_id ->
                %{
                  video_id: video_id,
                  year: year,
                  week_number: week_number,
                  inserted_at: now,
                  updated_at: now
                }
              end)

            # Use insert_all with on_conflict to handle upserts
            Repo.insert_all(
              WeeklyVideoAssignment,
              assignments,
              on_conflict: {:replace, [:updated_at]},
              conflict_target: [:video_id, :year, :week_number]
            )

            # Return the created/updated assignments
            list_weekly_assignments(year, week_number)
          end)
        end
    end
  end

  @doc """
  Removes a video from a specific week's assignment.

  Deletes the assignment for the specific video/year/week combination.
  Preserves other assignments for that week.

  Returns `{:ok, deleted_count}` where deleted_count is 0 or 1.

  ## Examples

      iex> remove_video_from_week(video_id, 2025, 10)
      {:ok, 1}

      iex> remove_video_from_week(non_assigned_video_id, 2025, 10)
      {:ok, 0}
  """
  def remove_video_from_week(video_id, year, week_number)
      when is_integer(video_id) and is_integer(year) and is_integer(week_number) do
    {deleted_count, _} =
      from(a in WeeklyVideoAssignment,
        where: a.video_id == ^video_id and a.year == ^year and a.week_number == ^week_number
      )
      |> Repo.delete_all()

    {:ok, deleted_count}
  end

  @doc """
  Returns videos assigned to the current week for a specific category.

  Calculates the current year and ISO week number, then queries for
  videos with matching assignments in that category.

  Returns a list of videos (may be empty if no assignments).

  ## Examples

      iex> get_videos_for_current_week("Advanced Topics")
      [%Video{category: "Advanced Topics", ...}]

      iex> get_videos_for_current_week("Excerpts")
      []
  """
  def get_videos_for_current_week(category) do
    {year, week_number} = current_iso_week()
    get_videos_for_week(category, year, week_number)
  end

  @doc """
  Returns videos assigned to a specific week for a category.

  ## Examples

      iex> get_videos_for_week("Advanced Topics", 2025, 10)
      [%Video{category: "Advanced Topics", ...}]
  """
  def get_videos_for_week(category, year, week_number) do
    Repo.all(
      from v in Video,
        join: a in WeeklyVideoAssignment,
        on: a.video_id == v.id,
        where: v.category == ^category and a.year == ^year and a.week_number == ^week_number,
        order_by: [asc: v.title]
    )
  end

  @doc """
  Returns all weekly assignments for a specific year and week.

  Optionally filters by category. Returns assignments with preloaded videos.

  ## Examples

      iex> list_weekly_assignments(2025, 10)
      [%WeeklyVideoAssignment{video: %Video{}, ...}]

      iex> list_weekly_assignments(2025, 10, "Advanced Topics")
      [%WeeklyVideoAssignment{video: %Video{category: "Advanced Topics"}, ...}]
  """
  def list_weekly_assignments(year, week_number, category \\ nil)

  def list_weekly_assignments(year, week_number, nil) do
    Repo.all(
      from a in WeeklyVideoAssignment,
        where: a.year == ^year and a.week_number == ^week_number,
        preload: [:video],
        order_by: [asc: a.id]
    )
  end

  def list_weekly_assignments(year, week_number, category) do
    Repo.all(
      from a in WeeklyVideoAssignment,
        join: v in Video,
        on: a.video_id == v.id,
        where: a.year == ^year and a.week_number == ^week_number and v.category == ^category,
        preload: [:video],
        order_by: [asc: a.id]
    )
  end

  @doc """
  Returns the current ISO year and week number.

  ## Examples

      iex> current_iso_week()
      {2025, 48}
  """
  def current_iso_week do
    Date.utc_today() |> iso_week_from_date()
  end

  @doc """
  Returns the ISO year and week number for a given date.

  ## Examples

      iex> iso_week_from_date(~D[2025-01-01])
      {2025, 1}
  """
  def iso_week_from_date(date) do
    {year, week} = :calendar.iso_week_number(Date.to_erl(date))
    {year, week}
  end
end
