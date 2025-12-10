defmodule Sahajyog.Events.EventProposal do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User
  alias Sahajyog.Events.Event
  alias Sahajyog.Events.Validators

  @statuses ~w(pending approved rejected)
  @budget_types ~w(open_for_donations fixed_budget)
  @video_types ~w(youtube r2)

  schema "event_proposals" do
    field :title, :string
    field :description, :string
    field :event_date, :date
    field :start_time, :time
    field :online_url, :string
    field :is_online, :boolean, default: false
    field :city, :string
    field :country, :string
    field :budget_type, :string, default: "open_for_donations"
    field :status, :string, default: "pending"
    field :review_notes, :string
    field :meeting_platform_link, :string
    field :presentation_video_type, :string
    field :presentation_video_url, :string

    belongs_to :proposed_by, User
    belongs_to :reviewed_by, User
    belongs_to :event, Event

    timestamps(type: :utc_datetime)
  end

  def video_types, do: @video_types

  def statuses, do: @statuses
  def budget_types, do: @budget_types

  def changeset(proposal, attrs) do
    proposal
    |> cast(attrs, [
      :title,
      :description,
      :event_date,
      :start_time,
      :online_url,
      :is_online,
      :city,
      :country,
      :budget_type,
      :status,
      :review_notes,
      :proposed_by_id,
      :reviewed_by_id,
      :event_id,
      :meeting_platform_link,
      :presentation_video_type,
      :presentation_video_url
    ])
    |> validate_required([:title, :event_date, :proposed_by_id])
    |> validate_online_fields()
    |> validate_in_person_fields()
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:budget_type, @budget_types)
    |> validate_presentation_video()
  end

  defp validate_online_fields(changeset) do
    if get_field(changeset, :is_online) do
      changeset
      |> validate_required([:start_time])
      |> validate_online_link_or_meeting_platform()
      |> validate_meeting_platform_link()
    else
      # Clear meeting_platform_link when is_online is unchecked
      changeset
      |> put_change(:meeting_platform_link, nil)
    end
  end

  defp validate_online_link_or_meeting_platform(changeset) do
    online_url = get_field(changeset, :online_url)
    meeting_link = get_field(changeset, :meeting_platform_link)

    has_online_url = is_binary(online_url) && String.trim(online_url) != ""
    has_meeting_link = is_binary(meeting_link) && String.trim(meeting_link) != ""

    if has_online_url || has_meeting_link do
      changeset
    else
      add_error(
        changeset,
        :online_url,
        "either YouTube link or meeting platform link is required for online events"
      )
    end
  end

  defp validate_meeting_platform_link(changeset) do
    meeting_link = get_field(changeset, :meeting_platform_link)

    if meeting_link && !Validators.valid_url?(meeting_link) do
      add_error(
        changeset,
        :meeting_platform_link,
        "must be a valid URL starting with http:// or https://"
      )
    else
      changeset
    end
  end

  defp validate_presentation_video(changeset) do
    video_type = get_field(changeset, :presentation_video_type)
    video_url = get_field(changeset, :presentation_video_url)

    cond do
      is_nil(video_type) && is_nil(video_url) ->
        # No video - valid
        changeset

      is_nil(video_type) && !is_nil(video_url) ->
        add_error(
          changeset,
          :presentation_video_type,
          "must be specified when video URL is provided"
        )

      !is_nil(video_type) && is_nil(video_url) ->
        add_error(
          changeset,
          :presentation_video_url,
          "must be provided when video type is specified"
        )

      video_type not in @video_types ->
        add_error(changeset, :presentation_video_type, "must be youtube or r2")

      video_type == "youtube" && !Validators.valid_youtube_url?(video_url) ->
        add_error(changeset, :presentation_video_url, "must be a valid YouTube video URL")

      video_type == "r2" && !is_binary(video_url) ->
        add_error(changeset, :presentation_video_url, "must be a valid R2 storage path")

      true ->
        changeset
    end
  end

  defp validate_in_person_fields(changeset) do
    if !get_field(changeset, :is_online) do
      changeset
      |> validate_required([:city, :country, :budget_type])
    else
      changeset
    end
  end
end
