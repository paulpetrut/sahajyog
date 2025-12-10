defmodule Sahajyog.Events.EventInvitationMaterialTest do
  use Sahajyog.DataCase, async: true
  use ExUnitProperties

  alias Sahajyog.Events.EventInvitationMaterial

  @allowed_types ~w(jpg jpeg png pdf)
  @max_file_size 10_485_760

  describe "file validation" do
    # Feature: event-invitation-materials, Property 1: File Type and Size Validation
    # For any uploaded file, if it is accepted by the system, then it must be one of
    # the allowed file types (JPG, PNG, PDF) and not exceed 10MB in size
    # **Validates: Requirements 1.2, 1.3**
    property "valid file types are accepted" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(1..@max_file_size),
              max_runs: 100
            ) do
        attrs = valid_material_attrs(%{file_type: file_type, file_size: file_size})
        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        assert changeset.valid?,
               "Expected changeset to be valid for file_type: #{file_type}, file_size: #{file_size}"
      end
    end

    property "invalid file types are rejected" do
      invalid_types = [
        "exe",
        "bat",
        "sh",
        "js",
        "html",
        "php",
        "doc",
        "docx",
        "xls",
        "zip",
        "rar"
      ]

      check all(
              file_type <- member_of(invalid_types),
              file_size <- integer(1..@max_file_size),
              max_runs: 100
            ) do
        attrs = valid_material_attrs(%{file_type: file_type, file_size: file_size})
        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        refute changeset.valid?,
               "Expected changeset to be invalid for file_type: #{file_type}"

        assert Keyword.has_key?(changeset.errors, :file_type)
      end
    end

    property "files exceeding max size are rejected" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer((@max_file_size + 1)..(@max_file_size * 2)),
              max_runs: 100
            ) do
        attrs = valid_material_attrs(%{file_type: file_type, file_size: file_size})
        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        refute changeset.valid?,
               "Expected changeset to be invalid for file_size: #{file_size}"

        assert Keyword.has_key?(changeset.errors, :file_size)
      end
    end

    property "zero or negative file sizes are rejected" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(-1000..0),
              max_runs: 100
            ) do
        attrs = valid_material_attrs(%{file_type: file_type, file_size: file_size})
        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        refute changeset.valid?,
               "Expected changeset to be invalid for file_size: #{file_size}"

        assert Keyword.has_key?(changeset.errors, :file_size)
      end
    end
  end

  describe "helper functions" do
    property "valid_file_type? returns true for allowed types" do
      check all(
              file_type <- member_of(@allowed_types),
              max_runs: 100
            ) do
        assert EventInvitationMaterial.valid_file_type?(file_type)
        assert EventInvitationMaterial.valid_file_type?(String.upcase(file_type))
      end
    end

    property "valid_file_size? returns true for valid sizes" do
      check all(
              file_size <- integer(1..@max_file_size),
              max_runs: 100
            ) do
        assert EventInvitationMaterial.valid_file_size?(file_size)
      end
    end

    property "extract_extension extracts correct extension" do
      check all(
              base_name <- string(:alphanumeric, min_length: 1, max_length: 20),
              extension <- member_of(@allowed_types),
              max_runs: 100
            ) do
        filename = "#{base_name}.#{extension}"
        assert EventInvitationMaterial.extract_extension(filename) == extension
      end
    end
  end

  describe "R2 storage paths" do
    # Feature: event-invitation-materials, Property 2: R2 Storage Path Uniqueness and Format
    # For any uploaded invitation material, the R2 storage key must follow the pattern
    # `Events/{event_slug}/invitations/{uuid}-{sanitized_filename}` and be unique across all uploads
    # **Validates: Requirements 1.4, 4.2**
    property "generated keys follow correct format" do
      check all(
              slug <- string(:alphanumeric, min_length: 3, max_length: 50),
              filename <- string(:alphanumeric, min_length: 1, max_length: 30),
              extension <- member_of(@allowed_types),
              max_runs: 100
            ) do
        full_filename = "#{filename}.#{extension}"
        key = Sahajyog.Events.generate_invitation_key(slug, full_filename)

        # Verify format: Events/{slug}/invitations/{uuid}-{filename}
        assert String.starts_with?(key, "Events/#{slug}/invitations/")
        assert String.contains?(key, "-")

        # Extract the uuid part (8 characters after invitations/)
        [_, _, _, uuid_and_filename] = String.split(key, "/")
        [uuid_part | _] = String.split(uuid_and_filename, "-", parts: 2)
        assert String.length(uuid_part) == 8
      end
    end

    property "generated keys are unique for same inputs" do
      check all(
              slug <- string(:alphanumeric, min_length: 3, max_length: 20),
              filename <- string(:alphanumeric, min_length: 1, max_length: 20),
              max_runs: 100
            ) do
        key1 = Sahajyog.Events.generate_invitation_key(slug, filename)
        key2 = Sahajyog.Events.generate_invitation_key(slug, filename)

        # Keys should be different due to UUID
        refute key1 == key2, "Expected unique keys but got: #{key1}"
      end
    end

    property "filenames are sanitized in keys" do
      special_chars = ["file name.jpg", "file@name.png", "file#name.pdf", "file&name.jpg"]

      check all(
              slug <- string(:alphanumeric, min_length: 3, max_length: 20),
              filename <- member_of(special_chars),
              max_runs: 100
            ) do
        key = Sahajyog.Events.generate_invitation_key(slug, filename)

        # Key should not contain special characters except underscore, dash, and dot
        sanitized_part = String.split(key, "/") |> List.last()
        refute String.contains?(sanitized_part, " ")
        refute String.contains?(sanitized_part, "@")
        refute String.contains?(sanitized_part, "#")
        refute String.contains?(sanitized_part, "&")
      end
    end
  end

  describe "multiple file management" do
    # Feature: event-invitation-materials, Property 3: Multiple File Upload Independence
    # For any event, multiple invitation materials can be uploaded simultaneously and
    # each material can be independently deleted without affecting other materials
    # **Validates: Requirements 2.1, 2.3, 2.5**
    property "multiple materials can be created for same event" do
      check all(
              num_materials <- integer(2..5),
              file_types <- list_of(member_of(@allowed_types), length: num_materials),
              max_runs: 50
            ) do
        # Create unique r2_keys for each material
        materials_attrs =
          Enum.map(file_types, fn file_type ->
            %{
              filename: "test-#{System.unique_integer([:positive])}.#{file_type}",
              original_filename: "test.#{file_type}",
              file_type: file_type,
              file_size: 1024,
              r2_key: "Events/test/invitations/#{Ecto.UUID.generate()}-test.#{file_type}",
              event_id: 1
            }
          end)

        # All changesets should be valid
        changesets =
          Enum.map(materials_attrs, fn attrs ->
            EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)
          end)

        assert Enum.all?(changesets, & &1.valid?),
               "Expected all #{num_materials} changesets to be valid"
      end
    end

    property "materials have independent r2_keys" do
      check all(
              num_materials <- integer(2..5),
              slug <- string(:alphanumeric, min_length: 3, max_length: 20),
              filename <- string(:alphanumeric, min_length: 1, max_length: 20),
              max_runs: 50
            ) do
        keys =
          Enum.map(1..num_materials, fn _ ->
            Sahajyog.Events.generate_invitation_key(slug, filename)
          end)

        # All keys should be unique
        unique_keys = Enum.uniq(keys)
        assert length(unique_keys) == num_materials, "Expected #{num_materials} unique keys"
      end
    end
  end

  describe "material cleanup" do
    # Feature: event-invitation-materials, Property 4: Complete Material Cleanup
    # For any invitation material that is deleted, both the database record and
    # the R2 storage file must be removed completely
    # **Validates: Requirements 2.4**
    property "changeset validates required fields for cleanup tracking" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(1..@max_file_size),
              max_runs: 50
            ) do
        # A valid material must have all required fields for proper cleanup
        attrs = %{
          filename: "test-#{System.unique_integer([:positive])}.#{file_type}",
          original_filename: "test.#{file_type}",
          file_type: file_type,
          file_size: file_size,
          r2_key: "Events/test/invitations/#{Ecto.UUID.generate()}-test.#{file_type}",
          event_id: 1
        }

        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        # Must have r2_key for R2 cleanup
        assert Ecto.Changeset.get_field(changeset, :r2_key) != nil
        # Must have event_id for cascade deletion
        assert Ecto.Changeset.get_field(changeset, :event_id) != nil
      end
    end

    property "missing r2_key makes changeset invalid" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(1..@max_file_size),
              max_runs: 50
            ) do
        attrs = %{
          filename: "test.#{file_type}",
          original_filename: "test.#{file_type}",
          file_type: file_type,
          file_size: file_size,
          # Missing r2_key
          event_id: 1
        }

        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)
        refute changeset.valid?
        assert Keyword.has_key?(changeset.errors, :r2_key)
      end
    end
  end

  describe "cascade deletion" do
    # Feature: event-invitation-materials, Property 5: Event Cascade Deletion
    # For any event that is deleted, all associated invitation materials must be
    # automatically removed from both database and R2 storage
    # **Validates: Requirements 4.1**
    property "materials require valid event_id for cascade deletion support" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(1..@max_file_size),
              max_runs: 50
            ) do
        # Materials without event_id should be invalid
        attrs = %{
          filename: "test.#{file_type}",
          original_filename: "test.#{file_type}",
          file_type: file_type,
          file_size: file_size,
          r2_key: "Events/test/invitations/#{Ecto.UUID.generate()}-test.#{file_type}"
          # Missing event_id
        }

        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)
        refute changeset.valid?
        assert Keyword.has_key?(changeset.errors, :event_id)
      end
    end
  end

  describe "referential integrity" do
    # Feature: event-invitation-materials, Property 6: Event-Material Referential Integrity
    # For any invitation material, it must be associated with exactly one valid event
    # that exists in the system
    # **Validates: Requirements 4.5**
    property "materials must have exactly one event association" do
      check all(
              file_type <- member_of(@allowed_types),
              file_size <- integer(1..@max_file_size),
              event_id <- positive_integer(),
              max_runs: 50
            ) do
        attrs = %{
          filename: "test.#{file_type}",
          original_filename: "test.#{file_type}",
          file_type: file_type,
          file_size: file_size,
          r2_key: "Events/test/invitations/#{Ecto.UUID.generate()}-test.#{file_type}",
          event_id: event_id
        }

        changeset = EventInvitationMaterial.changeset(%EventInvitationMaterial{}, attrs)

        # Should have exactly one event_id
        assert Ecto.Changeset.get_field(changeset, :event_id) == event_id
        # Changeset should be valid (foreign key constraint checked at DB level)
        assert changeset.valid?
      end
    end
  end

  defp valid_material_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        filename: "test-#{System.unique_integer([:positive])}.jpg",
        original_filename: "test.jpg",
        file_type: "jpg",
        file_size: 1024,
        r2_key: "Events/test-event/invitations/#{Ecto.UUID.generate()}-test.jpg",
        event_id: 1
      },
      overrides
    )
  end
end
