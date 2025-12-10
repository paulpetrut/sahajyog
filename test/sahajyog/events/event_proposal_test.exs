defmodule Sahajyog.Events.EventProposalTest do
  use Sahajyog.DataCase
  use ExUnitProperties

  alias Sahajyog.Events

  import Sahajyog.AccountsFixtures

  # **Feature: online-event-enhancements, Property 6: Proposal to Event Data Transfer**
  # **Validates: Requirements 4.3**
  describe "Property 6: Proposal to Event Data Transfer" do
    setup do
      proposer = user_fixture()
      proposer_scope = user_scope_fixture(proposer)
      admin = user_fixture(%{email: "admin#{System.unique_integer()}@example.com"})
      admin = Sahajyog.Repo.update!(Ecto.Changeset.change(admin, role: "admin"))
      admin_scope = user_scope_fixture(admin)

      %{
        proposer: proposer,
        proposer_scope: proposer_scope,
        admin: admin,
        admin_scope: admin_scope
      }
    end

    property "approved proposal transfers meeting link and video data to event", %{
      proposer_scope: proposer_scope,
      admin_scope: admin_scope
    } do
      check all(
              meeting_link <- meeting_platform_link_gen(),
              video_type <- non_nil_video_type_gen(),
              video_url <- video_url_gen(video_type)
            ) do
        # Create proposal with online event data
        proposal_attrs = %{
          "title" => "Test Event #{System.unique_integer()}",
          "event_date" => Date.add(Date.utc_today(), 7),
          "start_time" => ~T[10:00:00],
          "is_online" => true,
          "online_url" => "https://example.com/event",
          "meeting_platform_link" => meeting_link,
          "presentation_video_type" => video_type,
          "presentation_video_url" => video_url
        }

        {:ok, proposal} = Events.create_proposal(proposer_scope, proposal_attrs)

        # Approve the proposal with minimal event attrs
        event_attrs = %{
          "title" => proposal.title,
          "event_date" => proposal.event_date,
          "is_online" => proposal.is_online,
          "online_url" => proposal.online_url
        }

        {:ok, {event, _updated_proposal}} =
          Events.approve_proposal(admin_scope, proposal, event_attrs)

        # Verify data was transferred from proposal to event
        assert event.meeting_platform_link == meeting_link
        assert event.presentation_video_type == video_type
        assert event.presentation_video_url == video_url
      end
    end

    test "approved proposal without video data transfers correctly", %{
      proposer_scope: proposer_scope,
      admin_scope: admin_scope
    } do
      proposal_attrs = %{
        "title" => "Test Event",
        "event_date" => Date.add(Date.utc_today(), 7),
        "start_time" => ~T[10:00:00],
        "is_online" => true,
        "online_url" => "https://example.com/event",
        "meeting_platform_link" => "https://zoom.us/j/123456789"
      }

      {:ok, proposal} = Events.create_proposal(proposer_scope, proposal_attrs)

      event_attrs = %{
        "title" => proposal.title,
        "event_date" => proposal.event_date,
        "is_online" => proposal.is_online,
        "online_url" => proposal.online_url
      }

      {:ok, {event, _updated_proposal}} =
        Events.approve_proposal(admin_scope, proposal, event_attrs)

      assert event.meeting_platform_link == "https://zoom.us/j/123456789"
      assert is_nil(event.presentation_video_type)
      assert is_nil(event.presentation_video_url)
    end

    test "event_attrs can override proposal values", %{
      proposer_scope: proposer_scope,
      admin_scope: admin_scope
    } do
      proposal_attrs = %{
        "title" => "Test Event",
        "event_date" => Date.add(Date.utc_today(), 7),
        "start_time" => ~T[10:00:00],
        "is_online" => true,
        "online_url" => "https://example.com/event",
        "meeting_platform_link" => "https://zoom.us/j/123456789",
        "presentation_video_type" => "youtube",
        "presentation_video_url" => "https://www.youtube.com/watch?v=abc123def45"
      }

      {:ok, proposal} = Events.create_proposal(proposer_scope, proposal_attrs)

      # Admin provides different meeting link in event_attrs
      event_attrs = %{
        "title" => proposal.title,
        "event_date" => proposal.event_date,
        "is_online" => proposal.is_online,
        "online_url" => proposal.online_url,
        "meeting_platform_link" => "https://teams.microsoft.com/l/meetup-join/override"
      }

      {:ok, {event, _updated_proposal}} =
        Events.approve_proposal(admin_scope, proposal, event_attrs)

      # Event should use the override value from event_attrs
      assert event.meeting_platform_link == "https://teams.microsoft.com/l/meetup-join/override"
      # But video data should still come from proposal
      assert event.presentation_video_type == "youtube"
      assert event.presentation_video_url == "https://www.youtube.com/watch?v=abc123def45"
    end
  end

  # **Feature: online-event-enhancements, Property 5: Data Persistence Round-Trip**
  # **Validates: Requirements 4.1, 4.2**
  describe "Property 5: Data Persistence Round-Trip" do
    setup do
      user = user_fixture()
      scope = user_scope_fixture(user)
      %{user: user, scope: scope}
    end

    property "meeting link and video data persist correctly through save and retrieve", %{
      scope: scope
    } do
      check all(
              meeting_link <- meeting_platform_link_gen(),
              video_type <- video_type_gen(),
              video_url <- video_url_gen(video_type)
            ) do
        # Create proposal with online event data
        attrs = %{
          "title" => "Test Event #{System.unique_integer()}",
          "event_date" => Date.add(Date.utc_today(), 7),
          "start_time" => ~T[10:00:00],
          "is_online" => true,
          "online_url" => "https://example.com/event",
          "meeting_platform_link" => meeting_link,
          "presentation_video_type" => video_type,
          "presentation_video_url" => video_url
        }

        {:ok, proposal} = Events.create_proposal(scope, attrs)

        # Retrieve from database
        retrieved = Events.get_proposal!(proposal.id)

        # Verify round-trip preserves data
        assert retrieved.meeting_platform_link == meeting_link
        assert retrieved.presentation_video_type == video_type
        assert retrieved.presentation_video_url == video_url
      end
    end

    test "proposal without video data persists correctly", %{scope: scope} do
      attrs = %{
        "title" => "Test Event",
        "event_date" => Date.add(Date.utc_today(), 7),
        "start_time" => ~T[10:00:00],
        "is_online" => true,
        "online_url" => "https://example.com/event",
        "meeting_platform_link" => "https://zoom.us/j/123456789"
      }

      {:ok, proposal} = Events.create_proposal(scope, attrs)
      retrieved = Events.get_proposal!(proposal.id)

      assert retrieved.meeting_platform_link == "https://zoom.us/j/123456789"
      assert is_nil(retrieved.presentation_video_type)
      assert is_nil(retrieved.presentation_video_url)
    end
  end

  # Generators

  defp meeting_platform_link_gen do
    one_of([
      constant("https://zoom.us/j/123456789"),
      constant("https://teams.microsoft.com/l/meetup-join/abc123"),
      constant("https://meet.google.com/abc-defg-hij"),
      gen all(id <- integer(100_000_000..999_999_999)) do
        "https://zoom.us/j/#{id}"
      end
    ])
  end

  defp video_type_gen do
    one_of([
      constant(nil),
      constant("youtube"),
      constant("r2")
    ])
  end

  defp non_nil_video_type_gen do
    one_of([
      constant("youtube"),
      constant("r2")
    ])
  end

  defp video_url_gen(nil), do: constant(nil)

  defp video_url_gen("youtube") do
    gen all(video_id <- youtube_video_id()) do
      "https://www.youtube.com/watch?v=#{video_id}"
    end
  end

  defp video_url_gen("r2") do
    gen all(
          slug <- string(:alphanumeric, min_length: 5, max_length: 15),
          uuid <- string(:alphanumeric, length: 8),
          filename <- string(:alphanumeric, min_length: 3, max_length: 10)
        ) do
      "Events/#{slug}/videos/#{uuid}-#{filename}.mp4"
    end
  end

  defp youtube_video_id do
    gen all(chars <- fixed_list(List.duplicate(youtube_id_char(), 11))) do
      Enum.join(chars)
    end
  end

  defp youtube_id_char do
    member_of(
      Enum.to_list(?a..?z) ++
        Enum.to_list(?A..?Z) ++
        Enum.to_list(?0..?9) ++
        [?_, ?-]
    )
    |> map(&<<&1>>)
  end
end
