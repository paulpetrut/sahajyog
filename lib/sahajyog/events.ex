defmodule Sahajyog.Events do
  @moduledoc """
  Context for managing events, proposals, team members, tasks, transportation, carpools, and donations.
  """

  import Ecto.Query
  alias Sahajyog.Repo

  alias Sahajyog.Events.{
    Event,
    EventProposal,
    EventTeamMember,
    EventLocationPhoto,
    EventTask,
    EventTransportation,
    EventCarpool,
    EventCarpoolRequest,
    EventCarpoolRequest,
    EventDonation,
    EventAttendance,
    EventRideRequest
  }

  alias Sahajyog.Accounts.User

  ## Events

  @doc """
  Lists events with optional filters.
  Filters: :status, :country, :city, :upcoming, :time_range
  """
  def list_events(filters \\ %{}) do
    Event
    |> apply_event_filters(filters)
    |> order_by([e], asc: e.event_date)
    |> preload([:user, team_members: :user])
    |> Repo.all()
  end

  @doc """
  Lists upcoming public events (default view).
  """
  def list_upcoming_events do
    today = Date.utc_today()

    Event
    |> where([e], e.status == "public" and e.event_date >= ^today)
    |> order_by([e], asc: e.event_date)
    |> preload([:user, team_members: :user])
    |> Repo.all()
  end

  @doc """
  Lists past public events.
  """
  def list_past_public_events do
    today = Date.utc_today()

    Event
    |> where([e], e.status == "public" and e.event_date < ^today)
    |> order_by([e], desc: e.event_date)
    |> preload([:user, team_members: :user])
    |> Repo.all()
  end

  @doc """
  Lists events visible to a specific user:
  - Public events
  - Draft/archived events where user is the owner
  - Events where user is an accepted team member
  """
  def list_events_for_user(user_id) do
    today = Date.utc_today()

    Event
    |> join(:left, [e], tm in EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> where(
      [e, tm],
      (e.status == "public" and e.event_date >= ^today) or e.user_id == ^user_id or
        not is_nil(tm.id)
    )
    |> order_by([e], asc: e.event_date)
    |> preload([:user, team_members: :user])
    |> Repo.all()
  end

  @doc """
  Lists events where the user is directly involved (owner or team member).
  Does NOT include public events just because they are public.
  """
  def list_my_events(user_id) do
    Event
    |> join(:left, [e], tm in EventTeamMember,
      on: tm.event_id == e.id and tm.user_id == ^user_id and tm.status == "accepted"
    )
    |> join(:left, [e], a in EventAttendance,
      on: a.event_id == e.id and a.user_id == ^user_id and a.status == "attending"
    )
    |> where(
      [e, tm, a],
      e.user_id == ^user_id or not is_nil(tm.id) or not is_nil(a.id)
    )
    |> order_by([e], asc: e.event_date)
    |> preload([:user, team_members: :user])
    |> Repo.all()
  end

  def get_event!(id) do
    Event
    |> preload([
      :user,
      team_members: :user,
      location_photos: [],
      tasks: [:assigned_user, :volunteers],
      transportation_options: [],
      carpools: [requests: :passenger_user, driver_user: []],
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
      is_team_member?(user.id, event.id) -> true
      true -> false
    end
  end

  defp is_team_member?(user_id, event_id) do
    EventTeamMember
    |> where(
      [tm],
      tm.user_id == ^user_id and tm.event_id == ^event_id and tm.status == "accepted"
    )
    |> Repo.exists?()
  end

  ## Event Proposals

  def list_proposals(filters \\ %{}) do
    EventProposal
    |> apply_proposal_filters(filters)
    |> order_by([p], asc: p.inserted_at)
    |> preload([:proposed_by, :reviewed_by, :event])
    |> Repo.all()
  end

  def list_pending_proposals do
    list_proposals(%{status: "pending"})
  end

  def get_proposal!(id) do
    EventProposal
    |> preload([:proposed_by, :reviewed_by, :event])
    |> Repo.get!(id)
  end

  def create_proposal(current_scope, attrs) do
    attrs = Map.put(attrs, "proposed_by_id", current_scope.user.id)

    %EventProposal{}
    |> EventProposal.changeset(attrs)
    |> Repo.insert()
  end

  def approve_proposal(current_scope, %EventProposal{} = proposal, event_attrs) do
    Repo.transaction(fn ->
      # Set the event owner to the user who proposed it
      event_attrs = Map.put(event_attrs, "user_id", proposal.proposed_by_id)

      with {:ok, event} <- struct(Event, %{}) |> Event.changeset(event_attrs) |> Repo.insert(),
           {:ok, updated_proposal} <-
             update_proposal(proposal, %{
               status: "approved",
               reviewed_by_id: current_scope.user.id,
               event_id: event.id
             }) do
        {event, updated_proposal}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def reject_proposal(current_scope, %EventProposal{} = proposal, review_notes) do
    update_proposal(proposal, %{
      status: "rejected",
      reviewed_by_id: current_scope.user.id,
      review_notes: review_notes
    })
  end

  def update_proposal(%EventProposal{} = proposal, attrs) do
    proposal
    |> EventProposal.changeset(attrs)
    |> Repo.update()
  end

  def delete_proposal(%EventProposal{} = proposal) do
    Repo.delete(proposal)
  end

  def change_proposal(%EventProposal{} = proposal, attrs \\ %{}) do
    EventProposal.changeset(proposal, attrs)
  end

  ## Team Members

  def list_team_members(event_id) do
    EventTeamMember
    |> where([tm], tm.event_id == ^event_id)
    |> preload([:user, :invited_by])
    |> Repo.all()
  end

  def invite_team_member(current_scope, event_id, user_id, role \\ "co_author") do
    case %EventTeamMember{}
         |> EventTeamMember.changeset(%{
           event_id: event_id,
           user_id: user_id,
           invited_by_id: current_scope.user.id,
           role: role,
           status: "pending"
         })
         |> Repo.insert() do
      {:ok, member} ->
        broadcast(member.event_id, {:event_updated, member.event_id})
        {:ok, member}

      error ->
        error
    end
  end

  def accept_team_invitation(%EventTeamMember{} = member) do
    case member
         |> EventTeamMember.changeset(%{status: "accepted"})
         |> Repo.update() do
      {:ok, updated_member} ->
        broadcast(updated_member.event_id, {:event_updated, updated_member.event_id})
        {:ok, updated_member}

      error ->
        error
    end
  end

  def reject_team_invitation(%EventTeamMember{} = member) do
    case member
         |> EventTeamMember.changeset(%{status: "rejected"})
         |> Repo.update() do
      {:ok, updated_member} ->
        broadcast(updated_member.event_id, {:event_updated, updated_member.event_id})
        {:ok, updated_member}

      error ->
        error
    end
  end

  def remove_team_member(%EventTeamMember{} = member) do
    case Repo.delete(member) do
      {:ok, deleted_member} ->
        broadcast(deleted_member.event_id, {:event_updated, deleted_member.event_id})
        {:ok, deleted_member}

      error ->
        error
    end
  end

  ## Location Photos

  def list_location_photos(event_id) do
    EventLocationPhoto
    |> where([p], p.event_id == ^event_id)
    |> order_by([p], asc: p.position)
    |> Repo.all()
  end

  def create_location_photo(attrs) do
    %EventLocationPhoto{}
    |> EventLocationPhoto.changeset(attrs)
    |> Repo.insert()
  end

  def delete_location_photo(%EventLocationPhoto{} = photo) do
    Repo.delete(photo)
  end

  ## Tasks

  def list_tasks(event_id) do
    EventTask
    |> where([t], t.event_id == ^event_id)
    |> order_by([t], asc: t.position)
    |> preload([:assigned_user, :volunteers])
    |> Repo.all()
  end

  def get_task!(id) do
    EventTask
    |> preload([:assigned_user, :event, :volunteers])
    |> Repo.get!(id)
  end

  def create_task(attrs) do
    case %EventTask{}
         |> EventTask.changeset(attrs)
         |> Repo.insert() do
      {:ok, task} ->
        broadcast(task.event_id, {:event_updated, task.event_id})
        {:ok, task}

      error ->
        error
    end
  end

  def update_task(%EventTask{} = task, attrs) do
    case task
         |> EventTask.changeset(attrs)
         |> Repo.update() do
      {:ok, updated_task} ->
        broadcast(updated_task.event_id, {:event_updated, updated_task.event_id})
        {:ok, updated_task}

      error ->
        error
    end
  end

  def delete_task(%EventTask{} = task) do
    case Repo.delete(task) do
      {:ok, deleted} ->
        broadcast(deleted.event_id, {:event_updated, deleted.event_id})
        {:ok, deleted}

      error ->
        error
    end
  end

  def change_task(%EventTask{} = task, attrs \\ %{}) do
    EventTask.changeset(task, attrs)
  end

  def join_task(%User{} = user, task_id) do
    case %Sahajyog.Events.EventTaskParticipant{}
         |> Sahajyog.Events.EventTaskParticipant.changeset(%{user_id: user.id, task_id: task_id})
         |> Repo.insert() do
      {:ok, participant} ->
        # We need event_id to broadcast. Fetch task.
        task = get_task!(task_id)
        broadcast(task.event_id, {:event_updated, task.event_id})
        {:ok, participant}

      error ->
        error
    end
  end

  def leave_task(%User{} = user, task_id) do
    task = get_task!(task_id)

    {count, _} =
      Sahajyog.Events.EventTaskParticipant
      |> where([p], p.user_id == ^user.id and p.task_id == ^task_id)
      |> Repo.delete_all()

    if count > 0 do
      broadcast(task.event_id, {:event_updated, task.event_id})
    end

    {:ok, count}
  end

  ## Transportation

  def list_transportation(event_id) do
    EventTransportation
    |> where([t], t.event_id == ^event_id)
    |> order_by([t], asc: t.position)
    |> Repo.all()
  end

  def create_transportation(attrs) do
    %EventTransportation{}
    |> EventTransportation.changeset(attrs)
    |> Repo.insert()
  end

  def update_transportation(%EventTransportation{} = trans, attrs) do
    trans
    |> EventTransportation.changeset(attrs)
    |> Repo.update()
  end

  def delete_transportation(%EventTransportation{} = trans) do
    Repo.delete(trans)
  end

  def change_transportation(%EventTransportation{} = trans, attrs \\ %{}) do
    EventTransportation.changeset(trans, attrs)
  end

  ## Carpools

  def list_carpools(event_id) do
    EventCarpool
    |> where([c], c.event_id == ^event_id)
    |> preload([:driver_user, requests: :passenger_user])
    |> Repo.all()
  end

  def get_carpool!(id) do
    EventCarpool
    |> preload([:driver_user, :event, requests: :passenger_user])
    |> Repo.get!(id)
  end

  def create_carpool(current_scope, event_id, attrs) do
    attrs =
      attrs
      |> Map.put("event_id", event_id)
      |> Map.put("driver_user_id", current_scope.user.id)

    %EventCarpool{}
    |> EventCarpool.changeset(attrs)
    |> Repo.insert()
  end

  def update_carpool(%EventCarpool{} = carpool, attrs) do
    carpool
    |> EventCarpool.changeset(attrs)
    |> Repo.update()
  end

  def delete_carpool(%EventCarpool{} = carpool) do
    result =
      Repo.transaction(fn ->
        carpool = Repo.preload(carpool, requests: :passenger_user)

        # Iterate over accepted requests to restore pending status if they had one
        Enum.each(carpool.requests, fn request ->
          if request.status == "accepted" do
            restore_ride_request_status(carpool.event_id, request.passenger_user_id)
          end
        end)

        Repo.delete(carpool)
      end)

    case result do
      {:ok, deleted} ->
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, deleted}

      {:error, _} ->
        {:error, "Could not delete carpool"}
    end
  end

  def change_carpool(%EventCarpool{} = carpool, attrs \\ %{}) do
    EventCarpool.changeset(carpool, attrs)
  end

  ## Carpool Requests

  def list_ride_requests(event_id) do
    # Exclude pending requests from users who already have an accepted carpool
    accepted_passenger_ids =
      from(cr in EventCarpoolRequest,
        join: c in EventCarpool,
        on: c.id == cr.carpool_id,
        where: c.event_id == ^event_id and cr.status == "accepted",
        select: cr.passenger_user_id
      )

    EventRideRequest
    |> where([r], r.event_id == ^event_id)
    |> where(
      [r],
      r.status == "pending" and r.passenger_user_id not in subquery(accepted_passenger_ids)
    )
    |> preload([:passenger_user])
    |> Repo.all()
  end

  def request_carpool_seat(current_scope, carpool_id, notes \\ nil) do
    result =
      %EventCarpoolRequest{}
      |> EventCarpoolRequest.changeset(%{
        carpool_id: carpool_id,
        passenger_user_id: current_scope.user.id,
        notes: notes,
        status: "pending"
      })
      |> Repo.insert()

    case result do
      {:ok, request} ->
        carpool = Repo.get(EventCarpool, carpool_id)
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, request}

      error ->
        error
    end
  end

  def accept_carpool_request(%EventCarpoolRequest{} = request) do
    result =
      Repo.transaction(fn ->
        # 1. Accept the carpool request
        {:ok, updated_request} =
          request
          |> EventCarpoolRequest.changeset(%{status: "accepted"})
          |> Repo.update()

        # 2. Find and fulfill any generic ride request for this user/event
        request = Repo.preload(request, :carpool)

        ride_request =
          EventRideRequest
          |> where(
            [r],
            r.passenger_user_id == ^request.passenger_user_id and
              r.event_id == ^request.carpool.event_id and r.status == "pending"
          )
          |> Repo.one()

        if ride_request do
          {:ok, _} = update_ride_request(ride_request, %{status: "fulfilled"})
        end

        updated_request
      end)

    case result do
      {:ok, updated_request} ->
        # Need to fetch event_id. request is struct but might not have carpool loaded fully if transaction returns result directly.
        # But we preloaded inside transaction? No, transaction returns contents.
        # We know request.carpool_id.
        carpool = Repo.get(EventCarpool, updated_request.carpool_id)
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, updated_request}

      error ->
        error
    end
  end

  def reject_carpool_request(%EventCarpoolRequest{} = request) do
    result =
      request
      |> EventCarpoolRequest.changeset(%{status: "rejected"})
      |> Repo.update()

    case result do
      {:ok, updated_request} ->
        carpool = Repo.get(EventCarpool, updated_request.carpool_id)
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, updated_request}

      error ->
        error
    end
  end

  @doc """
  Updates a passenger's status to 'cancelled' (effectively leaving the carpool)
  and restores their generic ride request if it exists.
  """
  def leave_carpool(user, event_id) do
    result =
      Repo.transaction(fn ->
        # Find the active carpool request
        carpool_request =
          EventCarpoolRequest
          |> join(:inner, [r], c in EventCarpool, on: c.id == r.carpool_id)
          |> where(
            [r, c],
            c.event_id == ^event_id and r.passenger_user_id == ^user.id and r.status == "accepted"
          )
          |> select([r, c], r)
          |> Repo.one()

        if carpool_request do
          # Or update to "cancelled"? Delete is cleaner for now.
          Repo.delete(carpool_request)
          restore_ride_request_status(event_id, user.id)
        else
          {:error, :not_found}
        end
      end)

    case result do
      {:ok, _} ->
        broadcast(event_id, {:event_updated, event_id})
        {:ok, :left}

      error ->
        error
    end
  end

  defp restore_ride_request_status(event_id, user_id) do
    ride_request =
      EventRideRequest
      |> where(
        [r],
        r.event_id == ^event_id and r.passenger_user_id == ^user_id and r.status == "fulfilled"
      )
      |> Repo.one()

    if ride_request do
      update_ride_request(ride_request, %{status: "pending"})
    end
  end

  def get_carpool_request!(id) do
    EventCarpoolRequest
    |> preload([:passenger_user, carpool: :event])
    |> Repo.get!(id)
  end

  ## Donations

  def list_donations(event_id) do
    EventDonation
    |> where([d], d.event_id == ^event_id)
    |> order_by([d], desc: d.payment_date, desc: d.inserted_at)
    |> preload([:donor_user, :recorded_by])
    |> Repo.all()
  end

  def create_donation(current_scope, event_id, attrs) do
    attrs =
      attrs
      |> Map.put("event_id", event_id)
      |> Map.put("recorded_by_id", current_scope.user.id)

    %EventDonation{}
    |> EventDonation.changeset(attrs)
    |> Repo.insert()
  end

  def update_donation(%EventDonation{} = donation, attrs) do
    donation
    |> EventDonation.changeset(attrs)
    |> Repo.update()
  end

  def delete_donation(%EventDonation{} = donation) do
    Repo.delete(donation)
  end

  def change_donation(%EventDonation{} = donation, attrs \\ %{}) do
    EventDonation.changeset(donation, attrs)
  end

  @doc """
  Calculates the total donations for an event.
  """
  def total_donations(event_id) do
    EventDonation
    |> where([d], d.event_id == ^event_id)
    |> select([d], sum(d.amount))
    |> Repo.one() || Decimal.new(0)
  end

  @doc """
  Calculates the total actual expenses from tasks.
  """
  def total_expenses(event_id) do
    EventTask
    |> where([t], t.event_id == ^event_id and not is_nil(t.actual_expense))
    |> select([t], sum(t.actual_expense))
    |> Repo.one() || Decimal.new(0)
  end

  @doc """
  Generates a financial summary for the event.
  """
  def financial_summary(event_id) do
    income = total_donations(event_id)
    expenses = total_expenses(event_id)
    balance = Decimal.sub(income, expenses)

    is_profit = Decimal.compare(balance, 0) != :lt

    %{
      total_income: income,
      total_expenses: expenses,
      balance: balance,
      is_profit: is_profit
    }
  end

  ## Attendance

  def get_attendance(event_id, user_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.user_id == ^user_id)
    |> Repo.one()
  end

  def subscribe_to_event(user_id, event_id, notes \\ nil) do
    case get_attendance(event_id, user_id) do
      nil ->
        %EventAttendance{}
        |> EventAttendance.changeset(%{
          user_id: user_id,
          event_id: event_id,
          status: "attending",
          notes: notes
        })
        |> Repo.insert()

      attendance ->
        attendance
        |> EventAttendance.changeset(%{status: "attending", notes: notes})
        |> Repo.update()
    end
  end

  def unsubscribe_from_event(user_id, event_id) do
    case get_attendance(event_id, user_id) do
      nil ->
        {:ok, nil}

      attendance ->
        attendance
        |> EventAttendance.changeset(%{status: "not_attending"})
        |> Repo.update()
    end
  end

  def list_attendees(event_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.status == "attending")
    |> preload([:user])
    |> Repo.all()
  end

  def count_attendees(event_id) do
    EventAttendance
    |> where([a], a.event_id == ^event_id and a.status == "attending")
    |> Repo.aggregate(:count, :id)
  end

  ## Ride Requests

  def list_ride_requests_internal(event_id) do
    EventRideRequest
    |> where([r], r.event_id == ^event_id)
    |> preload([:passenger_user])
    |> Repo.all()
  end

  def create_ride_request(current_scope, event_id, attrs) do
    attrs =
      attrs
      |> Map.put("event_id", event_id)
      |> Map.put("passenger_user_id", current_scope.user.id)

    result =
      %EventRideRequest{}
      |> EventRideRequest.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, request} ->
        broadcast(event_id, {:event_updated, event_id})
        {:ok, request}

      error ->
        error
    end
  end

  def update_ride_request(%EventRideRequest{} = request, attrs) do
    result =
      request
      |> EventRideRequest.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        broadcast(updated.event_id, {:event_updated, updated.event_id})
        {:ok, updated}

      error ->
        error
    end
  end

  def delete_ride_request(%EventRideRequest{} = request) do
    result = Repo.delete(request)

    case result do
      {:ok, deleted} ->
        broadcast(deleted.event_id, {:event_updated, deleted.event_id})
        {:ok, deleted}

      error ->
        error
    end
  end

  def change_ride_request(%EventRideRequest{} = request, attrs \\ %{}) do
    EventRideRequest.changeset(request, attrs)
  end

  ## Private Helpers

  defp apply_event_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when is_binary(status) ->
        where(query, [e], e.status == ^status)

      {:country, country}, query when is_binary(country) and country != "" ->
        where(query, [e], e.country == ^country)

      {:city, city}, query when is_binary(city) and city != "" ->
        where(query, [e], e.city == ^city)

      {:upcoming, true}, query ->
        today = Date.utc_today()
        where(query, [e], e.event_date >= ^today)

      {:time_range, "1_month"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 30)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "3_months"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 90)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "6_months"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 180)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      {:time_range, "1_year"}, query ->
        from_date = Date.utc_today()
        to_date = Date.add(from_date, 365)
        where(query, [e], e.event_date >= ^from_date and e.event_date <= ^to_date)

      _, query ->
        query
    end)
  end

  defp apply_proposal_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when is_binary(status) ->
        where(query, [p], p.status == ^status)

      {:proposed_by_id, user_id}, query when is_integer(user_id) ->
        where(query, [p], p.proposed_by_id == ^user_id)

      _, query ->
        query
    end)
  end

  def pick_up_passenger(driver_user, carpool_id, ride_request_id) do
    result =
      Repo.transaction(fn ->
        ride_request = Repo.get!(EventRideRequest, ride_request_id)
        carpool = Repo.get!(EventCarpool, carpool_id)

        # Verify driver owns carpool
        if carpool.driver_user_id != driver_user.id do
          Repo.rollback(:unauthorized)
        end

        # Create Carpool Request (Accepted)
        carpool_attrs = %{
          carpool_id: carpool.id,
          passenger_user_id: ride_request.passenger_user_id,
          status: "accepted",
          notes: "Picked up via ride request"
        }

        with {:ok, _car_req} <-
               %EventCarpoolRequest{}
               |> EventCarpoolRequest.changeset(carpool_attrs)
               |> Repo.insert(),
             {:ok, _updated_ride_req} <-
               update_ride_request(ride_request, %{status: "fulfilled"}) do
          {:ok, :picked_up}
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, :picked_up} ->
        # We need event_id. Retrieve via carpool_id or ride_request_id
        carpool = Repo.get(EventCarpool, carpool_id)
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, :picked_up}

      error ->
        error
    end
  end

  def get_user_confirmed_carpool(event_id, user_id) do
    EventCarpool
    |> join(:inner, [c], r in assoc(c, :requests))
    |> where(
      [c, r],
      c.event_id == ^event_id and r.passenger_user_id == ^user_id and r.status == "accepted"
    )
    |> preload([:driver_user])
    |> Repo.one()
  end

  def is_carpool_driver?(%User{} = user, carpool_id) do
    case Repo.get(EventCarpool, carpool_id) do
      nil -> false
      carpool -> carpool.driver_user_id == user.id
    end
  end

  ## PubSub

  def subscribe(event_id) do
    Phoenix.PubSub.subscribe(Sahajyog.PubSub, "event:#{event_id}")
  end

  defp broadcast(event_id, message) do
    Phoenix.PubSub.broadcast(Sahajyog.PubSub, "event:#{event_id}", message)
  end
end
