defmodule Sahajyog.EventReviews do
  @moduledoc """
  Context for managing event reviews.
  """

  import Ecto.Query
  alias Sahajyog.Events.EventReview
  alias Sahajyog.Repo

  @doc """
  Lists reviews for an event.
  """
  def list_event_reviews(event_id) do
    EventReview
    |> where([r], r.event_id == ^event_id)
    |> order_by([r], desc: r.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Creates an event review.
  """
  def create_event_review(user, event, attrs) do
    if can_review?(user, event) do
      case %EventReview{}
           |> EventReview.changeset(
             Map.merge(attrs, %{"user_id" => user.id, "event_id" => event.id})
           )
           |> Repo.insert() do
        {:ok, review} ->
          review = Repo.preload(review, :user)
          broadcast(event.id, {:review_created, review})
          {:ok, review}

        error ->
          error
      end
    else
      {:error, :cannot_review}
    end
  end

  @doc """
  Deletes an event review.
  """
  def delete_event_review(%EventReview{} = review) do
    case Repo.delete(review) do
      {:ok, _} ->
        broadcast(review.event_id, {:review_deleted, review.id})
        {:ok, review}

      error ->
        error
    end
  end

  @doc """
  Gets a review by ID.
  """
  def get_event_review!(id), do: Repo.get!(EventReview, id)

  @doc """
  Checks if a user can review an event.
  """
  def can_review?(user, event) do
    # 1. Check time window (Event period + 7 days)
    end_date = event.end_date || event.event_date
    review_deadline = Date.add(end_date, 7)
    today = Date.utc_today()

    within_window = Date.compare(today, review_deadline) != :gt

    # 2. Check max reviews (3 per user)
    review_count =
      EventReview
      |> where([r], r.event_id == ^event.id and r.user_id == ^user.id)
      |> Repo.aggregate(:count, :id)

    within_window && review_count < 3
  end

  @doc """
  Returns a changeset for tracking review changes.
  """
  def change_event_review(%EventReview{} = review, attrs \\ %{}) do
    EventReview.changeset(review, attrs)
  end

  # Private helpers

  defp broadcast(event_id, message) do
    Phoenix.PubSub.broadcast(Sahajyog.PubSub, "event:#{event_id}", message)
  end
end
