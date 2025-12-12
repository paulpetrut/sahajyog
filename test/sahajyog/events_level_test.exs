defmodule Sahajyog.EventsLevelTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Events
  alias Sahajyog.Generators
  alias Sahajyog.Repo

  import Sahajyog.AccountsFixtures
  import Ecto.Query

  describe "events access levels" do
    setup do
      user = user_fixture()

      # Create events
      {:ok, event_l1} =
        Events.create_event(
          %{user: user},
          valid_event_attrs(%{title: "L1 Event", level: "Level1"})
        )

      {:ok, event_l2} =
        Events.create_event(
          %{user: user},
          valid_event_attrs(%{title: "L2 Event", level: "Level2"})
        )

      {:ok, event_l3} =
        Events.create_event(
          %{user: user},
          valid_event_attrs(%{title: "L3 Event", level: "Level3"})
        )

      # Publish them
      {:ok, event_l1} = Events.update_event(event_l1, %{status: "public"})
      {:ok, event_l2} = Events.update_event(event_l2, %{status: "public"})
      {:ok, event_l3} = Events.update_event(event_l3, %{status: "public"})

      %{l1: event_l1, l2: event_l2, l3: event_l3}
    end

    test "list_upcoming_events filters by level", %{l1: l1, l2: l2, l3: l3} do
      # Level 1
      events = Events.list_upcoming_events(user_level: "Level1")
      ids = Enum.map(events, & &1.id)
      assert l1.id in ids
      refute l2.id in ids
      refute l3.id in ids

      # Level 2
      events = Events.list_upcoming_events(user_level: "Level2")
      ids = Enum.map(events, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      refute l3.id in ids

      # Level 3
      events = Events.list_upcoming_events(user_level: "Level3")
      ids = Enum.map(events, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      assert l3.id in ids
    end

    test "list_events_for_user filters by level for public events", %{l1: l1, l2: l2, l3: l3} do
      # A new user, checking public visibility
      user = user_fixture()

      # Level 1
      events = Events.list_events_for_user(user.id, user_level: "Level1")
      ids = Enum.map(events, & &1.id)
      assert l1.id in ids
      refute l2.id in ids
      refute l3.id in ids

      # Level 2
      events = Events.list_events_for_user(user.id, user_level: "Level2")
      ids = Enum.map(events, & &1.id)
      assert l1.id in ids
      assert l2.id in ids
      refute l3.id in ids
    end
  end

  defp valid_event_attrs(attrs) do
    defaults = %{
      "title" => "some title",
      "description" => "some description",
      "event_date" => Date.add(Date.utc_today(), 1),
      "start_time" => ~T[10:00:00],
      "status" => "draft"
    }

    attrs
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(defaults)
  end

  describe "event level filtering property tests" do
    # **Feature: role-level-simplification, Property 4: Event level filtering**
    # **Validates: Requirements 3.4**
    property "list_upcoming_events returns only events with level <= user level" do
      check all(
              user_level <- Generators.user_level(),
              event_levels <-
                list_of(Generators.event_level_non_nil(), min_length: 1, max_length: 5),
              max_runs: 100
            ) do
        # Create a user to own the events
        owner = user_fixture()

        # Create events with various levels
        events =
          Enum.map(event_levels, fn level ->
            {:ok, event} =
              Events.create_event(
                %{user: owner},
                valid_event_attrs(%{
                  title: "Event #{System.unique_integer()}",
                  level: level,
                  status: "public"
                })
              )

            event
          end)

        # Get events for the user level
        returned_events = Events.list_upcoming_events(user_level: user_level)
        returned_ids = Enum.map(returned_events, & &1.id)

        # Define accessible levels based on user level
        # Level hierarchy: Level1 < Level2 < Level3 (higher levels have more access)
        # Note: After event-level-default-cleanup, nil is no longer a valid level
        accessible_levels =
          case user_level do
            "Level1" -> ["Level1"]
            "Level2" -> ["Level1", "Level2"]
            "Level3" -> ["Level1", "Level2", "Level3"]
          end

        # Property: All returned events must have accessible levels
        Enum.each(returned_events, fn event ->
          assert event.level in accessible_levels,
                 "Event with level #{inspect(event.level)} should not be accessible to user with level #{user_level}"
        end)

        # Property: All created events with accessible levels should be returned
        expected_ids =
          events
          |> Enum.filter(fn e -> e.level in accessible_levels end)
          |> Enum.map(& &1.id)
          |> MapSet.new()

        returned_created_ids =
          returned_ids
          |> Enum.filter(fn id -> id in Enum.map(events, & &1.id) end)
          |> MapSet.new()

        assert MapSet.equal?(expected_ids, returned_created_ids),
               "All accessible events should be returned and no inaccessible events should be returned"
      end
    end

    # **Feature: role-level-simplification, Property 4: Event level filtering**
    # **Validates: Requirements 3.4**
    property "event level hierarchy is monotonic - higher levels see at least as many events" do
      check all(
              event_levels <-
                list_of(Generators.event_level_non_nil(), min_length: 1, max_length: 5),
              max_runs: 100
            ) do
        # Create a user to own the events
        owner = user_fixture()

        # Create events with various levels
        Enum.each(event_levels, fn level ->
          {:ok, _event} =
            Events.create_event(
              %{user: owner},
              valid_event_attrs(%{
                title: "Event #{System.unique_integer()}",
                level: level,
                status: "public"
              })
            )
        end)

        # Get events for each level
        level1_events = Events.list_upcoming_events(user_level: "Level1")
        level2_events = Events.list_upcoming_events(user_level: "Level2")
        level3_events = Events.list_upcoming_events(user_level: "Level3")

        level1_ids = Enum.map(level1_events, & &1.id) |> MapSet.new()
        level2_ids = Enum.map(level2_events, & &1.id) |> MapSet.new()
        level3_ids = Enum.map(level3_events, & &1.id) |> MapSet.new()

        # Property: Level2 should see at least all events Level1 sees
        assert MapSet.subset?(level1_ids, level2_ids),
               "Level2 should see all events that Level1 sees"

        # Property: Level3 should see at least all events Level2 sees
        assert MapSet.subset?(level2_ids, level3_ids),
               "Level3 should see all events that Level2 sees"
      end
    end
  end

  describe "event level data integrity property tests" do
    # **Feature: event-level-default-cleanup, Property 1: No NULL levels in database**
    # **Validates: Requirements 1.1, 1.3**
    property "no events have NULL level in database" do
      check all(
              # Use non-nil levels only since the schema default should handle missing levels
              event_levels <-
                list_of(Generators.event_level_non_nil(), min_length: 1, max_length: 5),
              max_runs: 100
            ) do
        # Create a user to own the events
        owner = user_fixture()

        # Create events with various levels
        Enum.each(event_levels, fn level ->
          {:ok, _event} =
            Events.create_event(
              %{user: owner},
              valid_event_attrs(%{
                title: "Event #{System.unique_integer()}",
                level: level
              })
            )
        end)

        # Property: Query database directly - no events should have NULL level
        null_level_count =
          from(e in Sahajyog.Events.Event, where: is_nil(e.level))
          |> Repo.aggregate(:count)

        assert null_level_count == 0,
               "Expected no events with NULL level, but found #{null_level_count}"
      end
    end

    # **Feature: event-level-default-cleanup, Property 1: No NULL levels in database**
    # **Validates: Requirements 1.1, 1.3**
    property "events created without explicit level get Level1 default" do
      check all(
              count <- integer(1..5),
              max_runs: 100
            ) do
        # Create a user to own the events
        owner = user_fixture()

        # Create events without specifying level - should get default "Level1"
        events =
          Enum.map(1..count, fn _ ->
            {:ok, event} =
              Events.create_event(
                %{user: owner},
                valid_event_attrs(%{
                  title: "Event #{System.unique_integer()}"
                })
              )

            event
          end)

        # Property: All created events should have "Level1" as their level
        Enum.each(events, fn event ->
          assert event.level == "Level1",
                 "Expected event to have Level1 default, but got #{inspect(event.level)}"
        end)
      end
    end
  end
end
