defmodule Sahajyog.Resources.R2StorageTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Sahajyog.Resources.R2Storage

  # Note: Unit tests for generate_store_media_url/2 and generate_store_media_urls/2
  # require R2 configuration and are tested via integration tests.
  # The functions are thin wrappers around generate_download_url/2 which is
  # already tested in the existing codebase.
  # **Validates: Requirements 8.8**

  # **Feature: sahaj-store, Property 7: R2 key format consistency**
  # **Validates: Requirements 2.5**
  describe "Property 7: R2 key format consistency" do
    property "generated store item key matches expected pattern" do
      check all(
              item_id <- StreamData.positive_integer(),
              filename <- StreamData.string(:alphanumeric, min_length: 1, max_length: 50),
              extension <-
                StreamData.member_of(["jpg", "png", "webp", "gif", "mp4", "webm", "mov"]),
              media_type <- StreamData.member_of(["photo", "video"]),
              max_runs: 100
            ) do
        full_filename = "#{filename}.#{extension}"
        key = R2Storage.generate_store_item_key(item_id, full_filename, media_type)

        # Verify key matches pattern: sahajaonline/sahajstore/{item_id}/{media_type}/{uuid}-{filename}
        pattern = ~r/^sahajaonline\/sahajstore\/#{item_id}\/#{media_type}\/[a-f0-9]{8}-.+$/

        assert Regex.match?(pattern, key),
               "Key '#{key}' does not match expected pattern for item_id=#{item_id}, media_type=#{media_type}"

        # Verify key contains the item_id
        assert String.contains?(key, "/#{item_id}/"),
               "Key should contain item_id #{item_id}"

        # Verify key contains the media_type
        assert String.contains?(key, "/#{media_type}/"),
               "Key should contain media_type #{media_type}"

        # Verify key starts with correct prefix
        assert String.starts_with?(key, "sahajaonline/sahajstore/"),
               "Key should start with 'sahajaonline/sahajstore/'"

        # Verify the filename portion contains a UUID prefix
        filename_part = key |> String.split("/") |> List.last()

        assert Regex.match?(~r/^[a-f0-9]{8}-.+$/, filename_part),
               "Filename part '#{filename_part}' should have UUID prefix"
      end
    end

    property "extract_store_item_filename removes UUID prefix correctly" do
      check all(
              item_id <- StreamData.positive_integer(),
              filename <- StreamData.string(:alphanumeric, min_length: 1, max_length: 50),
              extension <-
                StreamData.member_of(["jpg", "png", "webp", "gif", "mp4", "webm", "mov"]),
              media_type <- StreamData.member_of(["photo", "video"]),
              max_runs: 100
            ) do
        full_filename = "#{filename}.#{extension}"
        key = R2Storage.generate_store_item_key(item_id, full_filename, media_type)

        extracted = R2Storage.extract_store_item_filename(key)

        # The extracted filename should be the sanitized version of the original
        # (without the UUID prefix)
        refute Regex.match?(~r/^[a-f0-9]{8}-/, extracted),
               "Extracted filename should not have UUID prefix"

        # The extracted filename should contain the extension
        assert String.ends_with?(extracted, ".#{extension}") or
                 String.contains?(extracted, extension),
               "Extracted filename should preserve extension"
      end
    end

    property "store item keys are unique for same item and filename" do
      check all(
              item_id <- StreamData.positive_integer(),
              filename <- StreamData.string(:alphanumeric, min_length: 1, max_length: 50),
              media_type <- StreamData.member_of(["photo", "video"]),
              max_runs: 50
            ) do
        full_filename = "#{filename}.jpg"

        key1 = R2Storage.generate_store_item_key(item_id, full_filename, media_type)
        key2 = R2Storage.generate_store_item_key(item_id, full_filename, media_type)

        # Keys should be different due to UUID
        assert key1 != key2,
               "Generated keys should be unique even for same item and filename"
      end
    end
  end
end
