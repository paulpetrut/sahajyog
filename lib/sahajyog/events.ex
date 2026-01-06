defmodule Sahajyog.Events do
  @moduledoc """
  Context for managing events, proposals, team members, tasks, transportation, carpools, and donations.

  This module has been refactored to delegate to specialized context modules:
  - Sahajyog.EventProposals: Event proposal management
  - Sahajyog.EventTeam: Team member management
  - Sahajyog.EventLogistics: Tasks, transportation, and location photos
  - Sahajyog.EventFinance: Donations and financial summaries
  - Sahajyog.EventAttendance: Event attendance and ride requests
  - Sahajyog.EventReviews: Event reviews
  - Sahajyog.EventGallery: Event photos
  - Sahajyog.EventQueries: Query builder for complex event queries
  """

  import Ecto.Query

  alias Sahajyog.EventAttendance
  alias Sahajyog.EventFinance
  alias Sahajyog.EventGallery
  alias Sahajyog.EventLogistics
  alias Sahajyog.EventProposals
  alias Sahajyog.EventQueries
  alias Sahajyog.EventReviews
  alias Sahajyog.Events.{Event, EventInvitationMaterial}
  alias Sahajyog.EventTeam
  alias Sahajyog.Repo
  alias Sahajyog.Resources.R2Storage

  ## Events

  @doc """
  Upgrades a user to Level 2 using an Access Code.
  """
  def upgrade_user_via_code(user, code) do
    with %Sahajyog.Admin.AccessCode{} = access_code <-
           Sahajyog.Admin.get_access_code_by_code(code),
         true <- user.level == "Level1",
         true <- valid_access_code?(access_code) do
      # Perform upgrade and increment usage in a transaction or sequential updates
      Sahajyog.Repo.transaction(fn ->
        Sahajyog.Accounts.update_user_level(user, "Level2")
        Sahajyog.Admin.increment_usage(access_code)
      end)
      |> case do
        {:ok, _} -> {:ok, %{user | level: "Level2"}}
        error -> error
      end
    else
      nil ->
        {:error, :invalid_code}

      false ->
        if user.level != "Level1" do
          {:error, :already_upgraded}
        else
          {:error, :code_max_uses_reached}
        end

      _ ->
        {:error, :unknown}
    end
  end

  defp valid_access_code?(%{max_uses: nil}), do: true

  defp valid_access_code?(%{max_uses: max, usage_count: current}) when not is_nil(max),
    do: current < max

  @doc """
  Lists events with optional filters.
  Filters: :status, :country, :city, :upcoming, :time_range, :month, :search, :user_level
  """
  @spec list_events(map()) :: [Event.t()]
  def list_events(filters \\ %{}) do
    EventQueries.list_events(filters)
  end

  @doc """
  Lists events with pagination.
  Returns {events, total_count}
  """
  def list_events_paginated(filters \\ %{}, page \\ 1, per_page \\ 12) do
    EventQueries.list_events_paginated(filters, page, per_page)
  end

  @doc """
  Lists upcoming public events (default view).
  """
  def list_upcoming_events(opts \\ []) do
    EventQueries.list_upcoming_events(opts)
  end

  @doc """
  Lists upcoming events that are flagged as publicly accessible (for Welcome page).
  """
  def list_publicly_accessible_events do
    EventQueries.list_publicly_accessible_events()
  end

  @doc """
  Lists past public events.
  """
  def list_past_public_events(opts \\ []) do
    EventQueries.list_past_public_events(opts)
  end

  @doc """
  Lists past public events with pagination and filters.
  Returns {events, total_count}
  """
  def list_past_public_events_paginated(filters \\ %{}, page \\ 1, per_page \\ 12) do
    EventQueries.list_past_public_events_paginated(filters, page, per_page)
  end

  @doc """
  Fetches unique countries, cities and months for filtering events.
  Options are filtered based on the visibility rules for the given user.
  """
  def get_event_filter_options(user_id, user_level, type) do
    EventQueries.get_event_filter_options(user_id, user_level, type)
  end

  @doc """
  Lists events visible to a specific user:
  - Public events
  - Draft/archived events where user is the owner
  - Events where user is an accepted team member
  """
  def list_events_for_user(user_id, opts \\ []) do
    EventQueries.list_events_for_user(user_id, opts)
  end

  @doc """
  Lists events for user with pagination and filters.
  Returns {events, total_count}
  """
  def list_events_for_user_paginated(user_id, filters \\ %{}, page \\ 1, per_page \\ 12) do
    EventQueries.list_events_for_user_paginated(user_id, filters, page, per_page)
  end

  @doc """
  Lists events where the user is directly involved (owner or team member).
  Does NOT include public events just because they are public.
  """
  def list_my_events(user_id) do
    EventQueries.list_my_events(user_id)
  end

  @doc """
  Lists user's personal events with pagination.
  Returns {events, total_count}
  """
  def list_my_events_paginated(user_id, page \\ 1, per_page \\ 12) do
    EventQueries.list_my_events_paginated(user_id, page, per_page)
  end

  @spec get_event!(integer()) :: Event.t()
  def get_event!(id) do
    Event
    |> preload([
      :user,
      :invitation_materials,
      team_members: :user,
      location_photos: [],
      tasks: [:assigned_user, :volunteers],
      transportation_options: [],
      carpools: [requests: :passenger_user, driver_user: []],
      donations: [],
      attendances: :user,
      ride_requests: :passenger_user
    ])
    |> Repo.get!(id)
  end

  def get_event_by_slug!(slug) do
    Event
    |> where([e], e.slug == ^slug)
    |> preload([
      :user,
      :invitation_materials,
      team_members: :user,
      location_photos: [],
      tasks: [:assigned_user, :volunteers],
      transportation_options: [],
      carpools: [requests: :passenger_user, driver_user: []],
      donations: []
    ])
    |> Repo.one!()
  end

  def create_event(current_scope, attrs) do
    attrs = Map.put(attrs, "user_id", current_scope.user.id)

    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    # Clean up R2-hosted video if present
    if event.presentation_video_type == "r2" && event.presentation_video_url do
      R2Storage.delete(event.presentation_video_url)
    end

    # Clean up invitation materials from R2
    delete_event_invitation_materials(event.id)

    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def can_edit_event?(current_scope, %Event{} = event) do
    user = current_scope.user

    cond do
      user.role == "admin" -> true
      event.user_id == user.id -> true
      EventTeam.team_member?(user.id, event.id) -> true
      true -> false
    end
  end

  ## Event Proposals (delegated to EventProposals)

  defdelegate list_proposals(filters \\ %{}), to: EventProposals
  defdelegate list_pending_proposals, to: EventProposals
  defdelegate get_proposal!(id), to: EventProposals
  defdelegate create_proposal(current_scope, attrs), to: EventProposals
  defdelegate approve_proposal(current_scope, proposal, event_attrs), to: EventProposals
  defdelegate reject_proposal(current_scope, proposal, review_notes), to: EventProposals
  defdelegate update_proposal(proposal, attrs), to: EventProposals
  defdelegate delete_proposal(proposal), to: EventProposals
  defdelegate change_proposal(proposal, attrs \\ %{}), to: EventProposals

  ## Team Members (delegated to EventTeam)

  defdelegate list_team_members(event_id), to: EventTeam

  defdelegate invite_team_member(current_scope, event_id, user_id, role \\ "co_author"),
    to: EventTeam

  defdelegate accept_team_invitation(member), to: EventTeam
  defdelegate reject_team_invitation(member), to: EventTeam
  defdelegate remove_team_member(member), to: EventTeam

  ## Location Photos (delegated to EventLogistics)

  defdelegate list_location_photos(event_id), to: EventLogistics
  defdelegate create_location_photo(attrs), to: EventLogistics
  defdelegate delete_location_photo(photo), to: EventLogistics

  ## Tasks (delegated to EventLogistics)

  defdelegate list_tasks(event_id), to: EventLogistics
  defdelegate get_task!(id), to: EventLogistics
  defdelegate create_task(attrs), to: EventLogistics
  defdelegate update_task(task, attrs), to: EventLogistics
  defdelegate delete_task(task), to: EventLogistics
  defdelegate change_task(task, attrs \\ %{}), to: EventLogistics
  defdelegate join_task(user, task_id), to: EventLogistics
  defdelegate leave_task(user, task_id), to: EventLogistics

  ## Transportation (delegated to EventLogistics)

  defdelegate list_transportation(event_id), to: EventLogistics
  defdelegate create_transportation(attrs), to: EventLogistics
  defdelegate update_transportation(trans, attrs), to: EventLogistics
  defdelegate delete_transportation(trans), to: EventLogistics
  defdelegate change_transportation(trans, attrs \\ %{}), to: EventLogistics

  ## Carpools (delegated to EventLogistics)

  defdelegate list_carpools(event_id), to: EventLogistics
  defdelegate get_carpool!(id), to: EventLogistics
  defdelegate get_user_carpool(event_id, user_id), to: EventLogistics
  defdelegate create_carpool(current_scope, event_id, attrs), to: EventLogistics
  defdelegate update_carpool(carpool, attrs), to: EventLogistics
  defdelegate delete_carpool(carpool), to: EventLogistics
  defdelegate change_carpool(carpool, attrs \\ %{}), to: EventLogistics

  ## Carpool Requests (delegated to EventLogistics)

  defdelegate list_ride_requests(event_id), to: EventLogistics
  defdelegate request_carpool_seat(current_scope, carpool_id, notes \\ nil), to: EventLogistics
  defdelegate accept_carpool_request(request), to: EventLogistics
  defdelegate reject_carpool_request(request), to: EventLogistics
  defdelegate leave_carpool(user, event_id), to: EventLogistics
  defdelegate get_carpool_request!(id), to: EventLogistics
  defdelegate get_user_confirmed_carpool(event_id, user_id), to: EventLogistics
  defdelegate carpool_driver?(user, carpool_id), to: EventLogistics
  defdelegate pick_up_passenger(driver_user, carpool_id, ride_request_id), to: EventLogistics

  ## Donations (delegated to EventFinance)

  defdelegate list_donations(event_id), to: EventFinance
  defdelegate create_donation(current_scope, event_id, attrs), to: EventFinance
  defdelegate update_donation(donation, attrs), to: EventFinance
  defdelegate delete_donation(donation), to: EventFinance
  defdelegate change_donation(donation, attrs \\ %{}), to: EventFinance
  defdelegate total_donations(event_id), to: EventFinance
  defdelegate total_expenses(event_id), to: EventFinance
  defdelegate financial_summary(event_id), to: EventFinance

  ## Attendance (delegated to EventAttendance)

  defdelegate get_attendance(event_id, user_id), to: EventAttendance
  defdelegate subscribe_to_event(user_id, event_id, notes \\ nil), to: EventAttendance
  defdelegate unsubscribe_from_event(user_id, event_id), to: EventAttendance
  defdelegate list_attendees(event_id), to: EventAttendance
  defdelegate count_attendees(event_id), to: EventAttendance

  ## Ride Requests (delegated to EventLogistics)

  defdelegate list_ride_requests_internal(event_id), to: EventLogistics
  defdelegate get_user_ride_request(event_id, user_id), to: EventLogistics
  defdelegate create_ride_request(current_scope, event_id, attrs), to: EventLogistics
  defdelegate update_ride_request(request, attrs), to: EventLogistics
  defdelegate delete_ride_request(request), to: EventLogistics
  defdelegate change_ride_request(request, attrs \\ %{}), to: EventLogistics

  ## Event Reviews (delegated to EventReviews)

  defdelegate list_event_reviews(event_id), to: EventReviews
  defdelegate create_event_review(user, event, attrs), to: EventReviews
  defdelegate delete_event_review(review), to: EventReviews
  defdelegate can_review?(user, event), to: EventReviews
  defdelegate get_event_review!(id), to: EventReviews

  ## Event Gallery (delegated to EventGallery)

  defdelegate list_event_photos(event_id), to: EventGallery
  defdelegate count_user_event_photos(event_id, user_id), to: EventGallery
  defdelegate create_event_photo(attrs), to: EventGallery
  defdelegate delete_event_photo(photo), to: EventGallery
  defdelegate get_event_photo!(id), to: EventGallery

  ## PubSub

  def subscribe(event_id) do
    Phoenix.PubSub.subscribe(Sahajyog.PubSub, "event:#{event_id}")
  end

  ## Invitation Materials

  @doc """
  Lists all invitation materials for an event.
  """
  def list_invitation_materials(event_id) do
    EventInvitationMaterial
    |> where([m], m.event_id == ^event_id)
    |> order_by([m], asc: m.uploaded_at)
    |> Repo.all()
  end

  @doc """
  Gets a single invitation material.
  """
  def get_invitation_material!(id), do: Repo.get!(EventInvitationMaterial, id)

  @doc """
  Creates an invitation material record.
  """
  def create_invitation_material(attrs \\ %{}) do
    %EventInvitationMaterial{}
    |> EventInvitationMaterial.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an invitation material and its R2 file.
  """
  def delete_invitation_material(%EventInvitationMaterial{} = material) do
    # Delete from R2 first
    R2Storage.delete(material.r2_key)
    # Then delete from database
    Repo.delete(material)
  end

  @doc """
  Deletes all invitation materials for an event.
  Used when deleting an event to clean up R2 storage.
  """
  def delete_event_invitation_materials(event_id) do
    materials = list_invitation_materials(event_id)

    Enum.each(materials, fn material ->
      R2Storage.delete(material.r2_key)
    end)

    EventInvitationMaterial
    |> where([m], m.event_id == ^event_id)
    |> Repo.delete_all()
  end

  @doc """
  Generates a unique R2 key for an invitation material.
  """
  def generate_invitation_key(event_slug, filename) do
    uuid = Ecto.UUID.generate() |> String.slice(0, 8)
    sanitized = sanitize_invitation_filename(filename)
    "Events/#{event_slug}/invitations/#{uuid}-#{sanitized}"
  end

  defp sanitize_invitation_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 200)
  end

  @doc """
  Detects the file type from a filename extension.
  Returns the normalized extension (lowercase) or nil if invalid.
  """
  def detect_invitation_file_type(filename) when is_binary(filename) do
    extension = EventInvitationMaterial.extract_extension(filename)

    if EventInvitationMaterial.valid_file_type?(extension) do
      extension
    else
      nil
    end
  end

  def detect_invitation_file_type(_), do: nil

  @doc """
  Gets the content type for an invitation material file.
  """
  def invitation_content_type(file_type) do
    case file_type do
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "png" -> "image/png"
      "pdf" -> "application/pdf"
      _ -> "application/octet-stream"
    end
  end

  @doc """
  Returns a changeset for tracking invitation material changes.
  """
  def change_invitation_material(%EventInvitationMaterial{} = material, attrs \\ %{}) do
    EventInvitationMaterial.changeset(material, attrs)
  end
end
