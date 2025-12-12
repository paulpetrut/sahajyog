defmodule Sahajyog.EditAccessTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Events
  alias Sahajyog.Topics
  alias Sahajyog.Accounts.Scope

  import Sahajyog.AccountsFixtures

  describe "admin edit access property tests" do
    # **Feature: role-level-simplification, Property 7: Admin event edit access**
    # **Validates: Requirements 4.1**
    property "admin users can edit any event" do
      check all(
              event_level <- member_of(["Level1", "Level2", "Level3", nil]),
              max_runs: 100
            ) do
        # Create an admin user
        admin = user_fixture(%{email: "admin#{System.unique_integer()}@example.com"})
        admin = Sahajyog.Repo.update!(Ecto.Changeset.change(admin, role: "admin"))
        admin_scope = Scope.for_user(admin)

        # Create a different user who owns the event
        owner = user_fixture(%{email: "owner#{System.unique_integer()}@example.com"})

        # Create an event owned by the other user
        {:ok, event} =
          Events.create_event(
            %{user: owner},
            valid_event_attrs(%{
              title: "Event #{System.unique_integer()}",
              level: event_level
            })
          )

        # Property: Admin should always be able to edit any event
        assert Events.can_edit_event?(admin_scope, event),
               "Admin user should be able to edit event owned by another user"
      end
    end

    # **Feature: role-level-simplification, Property 8: Admin topic edit access**
    # **Validates: Requirements 4.2**
    property "admin users can edit any topic" do
      check all(
              _topic_status <- member_of(["draft", "published", "archived"]),
              max_runs: 100
            ) do
        # Create an admin user
        admin = user_fixture(%{email: "admin#{System.unique_integer()}@example.com"})
        admin = Sahajyog.Repo.update!(Ecto.Changeset.change(admin, role: "admin"))
        admin_scope = Scope.for_user(admin)

        # Create a different user who owns the topic
        owner = user_fixture(%{email: "owner#{System.unique_integer()}@example.com"})
        owner_scope = Scope.for_user(owner)

        # Create a topic owned by the other user
        {:ok, topic} =
          Topics.create_topic(
            owner_scope,
            valid_topic_attrs(%{
              title: "Topic #{System.unique_integer()}"
            })
          )

        # Property: Admin should always be able to edit any topic
        assert Topics.can_edit_topic?(admin_scope, topic),
               "Admin user should be able to edit topic owned by another user"
      end
    end
  end

  describe "non-admin edit restriction property tests" do
    # **Feature: role-level-simplification, Property 9: Non-admin event edit restriction**
    # **Validates: Requirements 4.3**
    property "non-admin users cannot edit events they don't own and aren't team members of" do
      check all(
              event_level <- member_of(["Level1", "Level2", "Level3", nil]),
              max_runs: 100
            ) do
        # Create a regular user (non-admin)
        regular_user = user_fixture(%{email: "regular#{System.unique_integer()}@example.com"})
        regular_scope = Scope.for_user(regular_user)

        # Create a different user who owns the event
        owner = user_fixture(%{email: "owner#{System.unique_integer()}@example.com"})

        # Create an event owned by the other user
        {:ok, event} =
          Events.create_event(
            %{user: owner},
            valid_event_attrs(%{
              title: "Event #{System.unique_integer()}",
              level: event_level
            })
          )

        # Property: Non-admin user should NOT be able to edit event they don't own
        # and are not a team member of
        refute Events.can_edit_event?(regular_scope, event),
               "Non-admin user should not be able to edit event owned by another user"
      end
    end

    # **Feature: role-level-simplification, Property 10: Non-admin topic edit restriction**
    # **Validates: Requirements 4.4**
    property "non-admin users cannot edit topics they don't own and aren't co-authors of" do
      check all(
              _topic_status <- member_of(["draft", "published", "archived"]),
              max_runs: 100
            ) do
        # Create a regular user (non-admin)
        regular_user = user_fixture(%{email: "regular#{System.unique_integer()}@example.com"})
        regular_scope = Scope.for_user(regular_user)

        # Create a different user who owns the topic
        owner = user_fixture(%{email: "owner#{System.unique_integer()}@example.com"})
        owner_scope = Scope.for_user(owner)

        # Create a topic owned by the other user
        {:ok, topic} =
          Topics.create_topic(
            owner_scope,
            valid_topic_attrs(%{
              title: "Topic #{System.unique_integer()}"
            })
          )

        # Property: Non-admin user should NOT be able to edit topic they don't own
        # and are not a co-author of
        refute Topics.can_edit_topic?(regular_scope, topic),
               "Non-admin user should not be able to edit topic owned by another user"
      end
    end
  end

  # Helper functions

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

  defp valid_topic_attrs(attrs) do
    defaults = %{
      "title" => "some title",
      "content" => "some content",
      "status" => "draft"
    }

    attrs
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(defaults)
  end
end
