defmodule Sahajyog.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias Sahajyog.Accounts.User

  alias Sahajyog.Events.{
    EventTeamMember,
    EventLocationPhoto,
    EventTask,
    EventTransportation,
    EventCarpool,
    EventCarpool,
    EventDonation,
    EventAttendance,
    EventRideRequest
  }

  @statuses ~w(draft public archived cancelled)
  @invitation_types ~w(none pdf image)
  @languages ~w(en es fr de it ro)
  @video_types ~w(youtube r2)

  schema "events" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :status, :string, default: "draft"
    field :event_date, :date
    field :event_time, :time
    field :end_date, :date
    field :end_time, :time
    field :estimated_participants, :integer
    field :city, :string
    field :country, :string
    field :address, :string
    field :google_maps_link, :string
    field :google_maps_embed_url, :string
    field :venue_name, :string
    field :venue_website, :string
    field :invitation_type, :string, default: "none"
    field :invitation_url, :string
    field :budget_total, :decimal
    field :budget_notes, :string
    field :resources_required, :string
    field :banking_name, :string
    field :banking_iban, :string
    field :banking_swift, :string
    field :banking_notes, :string
    field :budget_type, :string, default: "open_for_donations"
    field :level, :string, default: "Level1"
    field :published_at, :utc_datetime
    field :online_url, :string
    field :is_online, :boolean, default: false
    field :timezone, :string, default: "Etc/UTC"
    field :languages, {:array, :string}, default: ["en"]
    field :is_publicly_accessible, :boolean, default: false
    field :meeting_platform_link, :string
    field :presentation_video_type, :string
    field :presentation_video_url, :string

    belongs_to :user, User
    has_many :reviews, Sahajyog.Events.EventReview
    has_many :photos, Sahajyog.Events.EventPhoto
    has_many :team_members, EventTeamMember
    has_many :location_photos, EventLocationPhoto
    has_many :tasks, EventTask
    has_many :transportation_options, EventTransportation
    has_many :carpools, EventCarpool
    has_many :donations, EventDonation
    has_many :attendances, EventAttendance
    has_many :ride_requests, EventRideRequest

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def invitation_types, do: @invitation_types
  def languages, do: @languages
  def video_types, do: @video_types

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :slug,
      :description,
      :status,
      :event_date,
      :event_time,
      :end_date,
      :end_time,
      :estimated_participants,
      :city,
      :country,
      :address,
      :google_maps_link,
      :online_url,
      :is_online,
      :google_maps_embed_url,
      :venue_name,
      :venue_website,
      :invitation_type,
      :invitation_url,
      :budget_total,
      :budget_notes,
      :resources_required,
      :banking_name,
      :banking_iban,
      :banking_swift,
      :banking_notes,
      :published_at,
      :user_id,
      :budget_type,
      :timezone,
      :timezone,
      :level,
      :languages,
      :is_publicly_accessible,
      :meeting_platform_link,
      :presentation_video_type,
      :presentation_video_url
    ])
    |> validate_required([:title, :user_id])
    |> validate_subset(:languages, @languages)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:level, ["Level1", "Level2", "Level3"])
    |> validate_inclusion(:invitation_type, @invitation_types)
    |> generate_slug()
    |> unique_constraint(:slug)
    |> maybe_set_published_at()
  end

  # generate_upgrade_code has been removed as it's no longer used

  defp generate_slug(changeset) do
    case get_change(changeset, :title) do
      nil ->
        changeset

      title ->
        slug =
          title
          |> String.downcase()
          |> String.replace(~r/[^\w\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")

        slug = if slug == "", do: "event-#{Ecto.UUID.generate()}", else: slug

        put_change(changeset, :slug, slug)
    end
  end

  defp maybe_set_published_at(changeset) do
    status = get_field(changeset, :status)
    published_at = get_field(changeset, :published_at)

    cond do
      status == "public" && is_nil(published_at) ->
        put_change(changeset, :published_at, DateTime.utc_now(:second))

      status != "public" && !is_nil(published_at) ->
        put_change(changeset, :published_at, nil)

      true ->
        changeset
    end
  end
end
