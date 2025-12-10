defmodule Sahajyog.Events.EventInvitationMaterial do
  @moduledoc """
  Schema for event invitation materials (photos and PDFs).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @allowed_types ~w(jpg jpeg png pdf)
  @max_file_size 10_485_760

  schema "event_invitation_materials" do
    field :filename, :string
    field :original_filename, :string
    field :file_type, :string
    field :file_size, :integer
    field :r2_key, :string
    field :uploaded_at, :utc_datetime

    belongs_to :event, Sahajyog.Events.Event

    timestamps()
  end

  @doc """
  Returns the list of allowed file types.
  """
  def allowed_types, do: @allowed_types

  @doc """
  Returns the maximum file size in bytes (10MB).
  """
  def max_file_size, do: @max_file_size

  @doc """
  Creates a changeset for an invitation material.
  """
  def changeset(material, attrs) do
    material
    |> cast(attrs, [
      :filename,
      :original_filename,
      :file_type,
      :file_size,
      :r2_key,
      :event_id,
      :uploaded_at
    ])
    |> validate_required([
      :filename,
      :original_filename,
      :file_type,
      :file_size,
      :r2_key,
      :event_id
    ])
    |> validate_file_type()
    |> validate_number(:file_size, greater_than: 0, less_than_or_equal_to: @max_file_size)
    |> foreign_key_constraint(:event_id)
    |> unique_constraint(:r2_key)
    |> set_uploaded_at()
  end

  defp validate_file_type(changeset) do
    validate_change(changeset, :file_type, fn :file_type, file_type ->
      normalized = String.downcase(file_type)

      if normalized in @allowed_types do
        []
      else
        [file_type: "must be one of: #{Enum.join(@allowed_types, ", ")}"]
      end
    end)
  end

  defp set_uploaded_at(changeset) do
    if get_field(changeset, :uploaded_at) do
      changeset
    else
      put_change(changeset, :uploaded_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  @doc """
  Checks if a file extension is valid.
  """
  def valid_file_type?(extension) when is_binary(extension) do
    String.downcase(extension) in @allowed_types
  end

  def valid_file_type?(_), do: false

  @doc """
  Checks if a file size is within the allowed limit.
  """
  def valid_file_size?(size) when is_integer(size) and size > 0 and size <= @max_file_size,
    do: true

  def valid_file_size?(_), do: false

  @doc """
  Extracts the file extension from a filename.
  """
  def extract_extension(filename) when is_binary(filename) do
    filename
    |> Path.extname()
    |> String.trim_leading(".")
    |> String.downcase()
  end

  def extract_extension(_), do: nil

  @doc """
  Checks if a material is an image (jpg, jpeg, png).
  """
  def image?(material) do
    material.file_type in ~w(jpg jpeg png)
  end

  @doc """
  Checks if a material is a PDF.
  """
  def pdf?(material) do
    material.file_type == "pdf"
  end
end
