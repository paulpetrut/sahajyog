defmodule Sahajyog.Content.WeeklyVideoAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "weekly_video_assignments" do
    field :year, :integer
    field :week_number, :integer

    belongs_to :video, Sahajyog.Content.Video

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:year, :week_number, :video_id])
    |> validate_required([:year, :week_number, :video_id])
    |> validate_number(:week_number, greater_than_or_equal_to: 1, less_than_or_equal_to: 53)
    |> validate_number(:year, greater_than: 2000)
    |> foreign_key_constraint(:video_id)
    |> unique_constraint([:video_id, :year, :week_number])
  end
end
