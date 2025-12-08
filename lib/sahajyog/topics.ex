defmodule Sahajyog.Topics do
  @moduledoc """
  Context for managing topics, proposals, co-authors, and references.
  """

  import Ecto.Query
  alias Sahajyog.Repo
  alias Sahajyog.Topics.{Topic, TopicProposal, TopicCoAuthor, TopicReference}

  ## Topics

  def list_topics(filters \\ %{}) do
    Topic
    |> apply_topic_filters(filters)
    |> order_by([t], desc: t.published_at)
    |> preload([:user, co_authors: :user, references: []])
    |> Repo.all()
  end

  def list_published_topics do
    list_topics(%{status: "published"})
  end

  @doc """
  Lists topics that are flagged as publicly accessible (for Welcome page).
  """
  def list_publicly_accessible_topics do
    Topic
    |> where([t], t.status == "published")
    |> where([t], t.is_publicly_accessible == true)
    |> order_by([t], desc: t.published_at)
    |> preload([:user, co_authors: :user, references: []])
    |> Repo.all()
  end

  @doc """
  Lists topics visible to a specific user:
  - Published topics (everyone can see)
  - Draft/archived topics where user is the author
  - Draft/archived topics where user is an accepted co-author
  """
  def list_topics_for_user(user_id) do
    Topic
    |> join(:left, [t], ca in TopicCoAuthor,
      on: ca.topic_id == t.id and ca.user_id == ^user_id and ca.status == "accepted"
    )
    |> where(
      [t, ca],
      t.status == "published" or t.user_id == ^user_id or not is_nil(ca.id)
    )
    |> order_by([t], desc: t.published_at, desc: t.inserted_at)
    |> preload([:user, co_authors: :user, references: []])
    |> Repo.all()
  end

  def get_topic!(id) do
    Topic
    |> preload([:user, co_authors: :user, references: []])
    |> Repo.get!(id)
  end

  def get_topic_by_slug!(slug) do
    Topic
    |> where([t], t.slug == ^slug)
    |> preload([:user, co_authors: :user, references: []])
    |> Repo.one!()
  end

  def create_topic(current_scope, attrs) do
    attrs = Map.put(attrs, "user_id", current_scope.user.id)

    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  def increment_views(%Topic{} = topic) do
    topic
    |> Ecto.Changeset.change(views_count: topic.views_count + 1)
    |> Repo.update()
  end

  def can_edit_topic?(current_scope, %Topic{} = topic) do
    user = current_scope.user

    cond do
      user.role == "admin" -> true
      topic.user_id == user.id -> true
      is_co_author?(user.id, topic.id) -> true
      true -> false
    end
  end

  defp is_co_author?(user_id, topic_id) do
    TopicCoAuthor
    |> where(
      [ca],
      ca.user_id == ^user_id and ca.topic_id == ^topic_id and ca.status == "accepted"
    )
    |> Repo.exists?()
  end

  ## Topic Proposals

  def list_proposals(filters \\ %{}) do
    TopicProposal
    |> apply_proposal_filters(filters)
    |> order_by([p], desc: p.inserted_at)
    |> preload([:proposed_by, :reviewed_by, :topic])
    |> Repo.all()
  end

  def list_pending_proposals do
    list_proposals(%{status: "pending"})
  end

  def get_proposal!(id) do
    TopicProposal
    |> preload([:proposed_by, :reviewed_by, :topic])
    |> Repo.get!(id)
  end

  def create_proposal(current_scope, attrs) do
    attrs = Map.put(attrs, "proposed_by_id", current_scope.user.id)

    %TopicProposal{}
    |> TopicProposal.changeset(attrs)
    |> Repo.insert()
  end

  def approve_proposal(current_scope, %TopicProposal{} = proposal, topic_attrs) do
    Repo.transaction(fn ->
      # Set the topic owner to the user who proposed it, not the admin
      topic_attrs = Map.put(topic_attrs, "user_id", proposal.proposed_by_id)

      with {:ok, topic} <- %Topic{} |> Topic.changeset(topic_attrs) |> Repo.insert(),
           {:ok, updated_proposal} <-
             update_proposal(proposal, %{
               status: "approved",
               reviewed_by_id: current_scope.user.id,
               topic_id: topic.id
             }) do
        {topic, updated_proposal}
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def reject_proposal(current_scope, %TopicProposal{} = proposal, review_notes) do
    update_proposal(proposal, %{
      status: "rejected",
      reviewed_by_id: current_scope.user.id,
      review_notes: review_notes
    })
  end

  def update_proposal(%TopicProposal{} = proposal, attrs) do
    proposal
    |> TopicProposal.changeset(attrs)
    |> Repo.update()
  end

  def delete_proposal(%TopicProposal{} = proposal) do
    Repo.delete(proposal)
  end

  def change_proposal(%TopicProposal{} = proposal, attrs \\ %{}) do
    TopicProposal.changeset(proposal, attrs)
  end

  ## Topic Co-Authors

  def list_co_authors(topic_id) do
    TopicCoAuthor
    |> where([ca], ca.topic_id == ^topic_id)
    |> preload([:user, :invited_by])
    |> Repo.all()
  end

  def invite_co_author(current_scope, topic_id, user_id) do
    %TopicCoAuthor{}
    |> TopicCoAuthor.changeset(%{
      topic_id: topic_id,
      user_id: user_id,
      invited_by_id: current_scope.user.id,
      status: "pending"
    })
    |> Repo.insert()
  end

  def accept_co_author_invitation(%TopicCoAuthor{} = co_author) do
    co_author
    |> TopicCoAuthor.changeset(%{status: "accepted"})
    |> Repo.update()
  end

  def reject_co_author_invitation(%TopicCoAuthor{} = co_author) do
    co_author
    |> TopicCoAuthor.changeset(%{status: "rejected"})
    |> Repo.update()
  end

  def remove_co_author(%TopicCoAuthor{} = co_author) do
    Repo.delete(co_author)
  end

  ## Topic References

  def list_references(topic_id) do
    TopicReference
    |> where([r], r.topic_id == ^topic_id)
    |> order_by([r], asc: r.position)
    |> Repo.all()
  end

  def create_reference(attrs) do
    %TopicReference{}
    |> TopicReference.changeset(attrs)
    |> Repo.insert()
  end

  def update_reference(%TopicReference{} = reference, attrs) do
    reference
    |> TopicReference.changeset(attrs)
    |> Repo.update()
  end

  def delete_reference(%TopicReference{} = reference) do
    Repo.delete(reference)
  end

  def change_reference(%TopicReference{} = reference, attrs \\ %{}) do
    TopicReference.changeset(reference, attrs)
  end

  ## Private Helpers

  defp apply_topic_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query when is_binary(status) ->
        where(query, [t], t.status == ^status)

      {:user_id, user_id}, query when is_integer(user_id) ->
        where(query, [t], t.user_id == ^user_id)

      {:language, language}, query when is_binary(language) ->
        where(query, [t], t.language == ^language)

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
end
