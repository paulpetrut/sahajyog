defmodule Sahajyog.EventLogistics do
  @moduledoc """
  Context for managing event logistics: transportation, carpools, ride requests, tasks, and location photos.
  """

  import Ecto.Query

  alias Sahajyog.Accounts.User

  alias Sahajyog.Events.{
    EventCarpool,
    EventCarpoolRequest,
    EventLocationPhoto,
    EventRideRequest,
    EventTask,
    EventTaskParticipant,
    EventTransportation
  }

  alias Sahajyog.Repo

  ## Transportation

  @doc """
  Lists transportation options for an event.
  """
  def list_transportation(event_id) do
    EventTransportation
    |> where([t], t.event_id == ^event_id)
    |> order_by([t], asc: t.position)
    |> Repo.all()
  end

  @doc """
  Creates a transportation option.
  """
  def create_transportation(attrs) do
    %EventTransportation{}
    |> EventTransportation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a transportation option.
  """
  def update_transportation(%EventTransportation{} = trans, attrs) do
    trans
    |> EventTransportation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transportation option.
  """
  def delete_transportation(%EventTransportation{} = trans) do
    Repo.delete(trans)
  end

  @doc """
  Returns a changeset for tracking transportation changes.
  """
  def change_transportation(%EventTransportation{} = trans, attrs \\ %{}) do
    EventTransportation.changeset(trans, attrs)
  end

  ## Carpools

  @doc """
  Lists carpools for an event.
  """
  def list_carpools(event_id) do
    EventCarpool
    |> where([c], c.event_id == ^event_id)
    |> preload([:driver_user, requests: :passenger_user])
    |> Repo.all()
  end

  @doc """
  Gets a carpool by ID.
  """
  def get_carpool!(id) do
    EventCarpool
    |> preload([:driver_user, :event, requests: :passenger_user])
    |> Repo.get!(id)
  end

  @doc """
  Gets a user's carpool for an event (if they're a driver).
  """
  def get_user_carpool(event_id, user_id) do
    EventCarpool
    |> where([c], c.event_id == ^event_id and c.driver_user_id == ^user_id)
    |> Repo.one()
  end

  @doc """
  Gets a user's pending ride request for an event.
  """
  def get_user_ride_request(event_id, user_id) do
    EventRideRequest
    |> where([r], r.event_id == ^event_id and r.passenger_user_id == ^user_id)
    |> where([r], r.status == "pending")
    |> Repo.one()
  end

  @doc """
  Creates a carpool.
  Automatically cancels any pending ride requests the user has for this event.
  """
  def create_carpool(current_scope, event_id, attrs) do
    attrs =
      attrs
      |> Map.put("event_id", event_id)
      |> Map.put("driver_user_id", current_scope.user.id)

    result =
      Repo.transaction(fn ->
        # Cancel any pending ride requests for this user/event
        case get_user_ride_request(event_id, current_scope.user.id) do
          nil ->
            :ok

          ride_request ->
            case update_ride_request(ride_request, %{status: "cancelled"}) do
              {:ok, _} -> :ok
              {:error, changeset} -> Repo.rollback(changeset)
            end
        end

        # Create the carpool
        case %EventCarpool{}
             |> EventCarpool.changeset(attrs)
             |> Repo.insert() do
          {:ok, carpool} -> carpool
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)

    case result do
      {:ok, carpool} ->
        broadcast(event_id, {:event_updated, event_id})
        {:ok, carpool}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a carpool.
  """
  def update_carpool(%EventCarpool{} = carpool, attrs) do
    carpool
    |> EventCarpool.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a carpool and restores ride requests for accepted passengers.
  """
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

  @doc """
  Returns a changeset for tracking carpool changes.
  """
  def change_carpool(%EventCarpool{} = carpool, attrs \\ %{}) do
    EventCarpool.changeset(carpool, attrs)
  end

  @doc """
  Gets a carpool request by ID.
  """
  def get_carpool_request!(id) do
    EventCarpoolRequest
    |> preload([:carpool, :passenger_user])
    |> Repo.get!(id)
  end

  ## Carpool Requests

  @doc """
  Lists available ride requests for an event (excluding users with accepted carpools).
  """
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

  @doc """
  Requests a seat in a carpool.
  """
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

  @doc """
  Accepts a carpool request.
  """
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
        # Need to fetch event_id. request is struct but might not have carpool loaded fully
        # if transaction returns result directly.
        # But we preloaded inside transaction? No, transaction returns contents.
        # We know request.carpool_id.
        carpool = Repo.get(EventCarpool, updated_request.carpool_id)
        broadcast(carpool.event_id, {:event_updated, carpool.event_id})
        {:ok, updated_request}

      error ->
        error
    end
  end

  @doc """
  Rejects a carpool request.
  """
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

  @doc """
  Gets user's confirmed carpool for an event.
  """
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

  @doc """
  Checks if a user is driver of a carpool.
  """
  def carpool_driver?(%User{} = user, carpool_id) do
    case Repo.get(EventCarpool, carpool_id) do
      nil -> false
      carpool -> carpool.driver_user_id == user.id
    end
  end

  ## Ride Requests

  @doc """
  Lists all ride requests for an event.
  """
  def list_ride_requests_internal(event_id) do
    EventRideRequest
    |> where([r], r.event_id == ^event_id)
    |> preload([:passenger_user])
    |> Repo.all()
  end

  @doc """
  Creates a ride request.
  Prevents creation if the user already has an active carpool for this event.
  """
  def create_ride_request(current_scope, event_id, attrs) do
    # Check if user already has a carpool for this event
    case get_user_carpool(event_id, current_scope.user.id) do
      nil ->
        # No carpool, proceed with creating ride request
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

      _carpool ->
        # User has a carpool, return error
        {:error, :has_carpool}
    end
  end

  @doc """
  Updates a ride request.
  """
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

  @doc """
  Deletes a ride request.
  """
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

  @doc """
  Returns a changeset for tracking ride request changes.
  """
  def change_ride_request(%EventRideRequest{} = request, attrs \\ %{}) do
    EventRideRequest.changeset(request, attrs)
  end

  @doc """
  Driver picks up a passenger from ride request.
  """
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
          :picked_up
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

  # Private helpers

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

  defp broadcast(event_id, message) do
    Phoenix.PubSub.broadcast(Sahajyog.PubSub, "event:#{event_id}", message)
  end

  ## Location Photos

  @doc """
  Lists location photos for an event.
  """
  def list_location_photos(event_id) do
    EventLocationPhoto
    |> where([p], p.event_id == ^event_id)
    |> order_by([p], asc: p.position)
    |> Repo.all()
  end

  @doc """
  Creates a location photo.
  """
  def create_location_photo(attrs) do
    %EventLocationPhoto{}
    |> EventLocationPhoto.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a location photo.
  """
  def delete_location_photo(%EventLocationPhoto{} = photo) do
    Repo.delete(photo)
  end

  ## Tasks

  @doc """
  Lists tasks for an event.
  """
  def list_tasks(event_id) do
    EventTask
    |> where([t], t.event_id == ^event_id)
    |> order_by([t], asc: t.position)
    |> preload([:assigned_user, participants: :user])
    |> Repo.all()
  end

  @doc """
  Gets a task by ID.
  """
  def get_task!(id) do
    EventTask
    |> preload([:event, :assigned_user, participants: :user])
    |> Repo.get!(id)
  end

  @doc """
  Creates a task.
  """
  def create_task(attrs) do
    %EventTask{}
    |> EventTask.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%EventTask{} = task, attrs) do
    task
    |> EventTask.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%EventTask{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns a changeset for tracking task changes.
  """
  def change_task(%EventTask{} = task, attrs \\ %{}) do
    EventTask.changeset(task, attrs)
  end

  @doc """
  Adds a user as a volunteer to a task.
  """
  def join_task(user, task_id) do
    %EventTaskParticipant{}
    |> EventTaskParticipant.changeset(%{task_id: task_id, user_id: user.id})
    |> Repo.insert()
  end

  @doc """
  Removes a user from a task.
  """
  def leave_task(user, task_id) do
    EventTaskParticipant
    |> where([p], p.task_id == ^task_id and p.user_id == ^user.id)
    |> Repo.delete_all()

    :ok
  end
end
