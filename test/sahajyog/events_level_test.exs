defmodule Sahajyog.EventsLevelTest do
  use Sahajyog.DataCase

  alias Sahajyog.Events
  alias Sahajyog.Events

  import Sahajyog.AccountsFixtures

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

  defp valid_event_attrs(attrs \\ %{}) do
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
end
