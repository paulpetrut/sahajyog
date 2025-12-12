defmodule Sahajyog.Store.StoreItemMediaTest do
  use Sahajyog.DataCase, async: true
  use ExUnitProperties

  alias Sahajyog.Store.StoreItemMedia

  # **Feature: sahaj-store, Property 9: Photo content type validation**
  # **Validates: Requirements 2.7**
  describe "Property 9: Photo content type validation" do
    property "photo media with valid content types are accepted" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.photo_content_types()),
              file_size <- StreamData.integer(1..StoreItemMedia.max_photo_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "photo"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end

    property "photo media with invalid content types are rejected" do
      invalid_content_types = ["text/plain", "application/json", "video/mp4", "audio/mpeg"]

      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(invalid_content_types),
              file_size <- StreamData.integer(1..StoreItemMedia.max_photo_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "photo"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        refute changeset.valid?
        assert {:content_type, _} = List.keyfind(changeset.errors, :content_type, 0)
      end
    end
  end

  # **Feature: sahaj-store, Property 10: Video content type validation**
  # **Validates: Requirements 2.8**
  describe "Property 10: Video content type validation" do
    property "video media with valid content types are accepted" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.video_content_types()),
              file_size <- StreamData.integer(1..StoreItemMedia.max_video_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "video"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end

    property "video media with invalid content types are rejected" do
      invalid_content_types = ["text/plain", "application/json", "image/jpeg", "audio/mpeg"]

      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(invalid_content_types),
              file_size <- StreamData.integer(1..StoreItemMedia.max_video_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "video"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        refute changeset.valid?
        assert {:content_type, _} = List.keyfind(changeset.errors, :content_type, 0)
      end
    end
  end

  # **Feature: sahaj-store, Property 28: Media file size validation**
  # **Validates: Requirements 8.6**
  describe "Property 28: Media file size validation" do
    property "photos exceeding 50MB are rejected" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.photo_content_types()),
              file_size <-
                StreamData.integer(
                  (StoreItemMedia.max_photo_size() + 1)..(StoreItemMedia.max_photo_size() +
                                                            10_000_000)
                ),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "photo"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        refute changeset.valid?
        assert {:file_size, _} = List.keyfind(changeset.errors, :file_size, 0)
      end
    end

    property "photos within 50MB are accepted" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.photo_content_types()),
              file_size <- StreamData.integer(1..StoreItemMedia.max_photo_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "photo"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end

    property "videos exceeding 500MB are rejected" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.video_content_types()),
              file_size <-
                StreamData.integer(
                  (StoreItemMedia.max_video_size() + 1)..(StoreItemMedia.max_video_size() +
                                                            10_000_000)
                ),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "video"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        refute changeset.valid?
        assert {:file_size, _} = List.keyfind(changeset.errors, :file_size, 0)
      end
    end

    property "videos within 500MB are accepted" do
      check all(
              file_name <- StreamData.string(:alphanumeric, min_length: 1, max_length: 100),
              content_type <- StreamData.member_of(StoreItemMedia.video_content_types()),
              file_size <- StreamData.integer(1..StoreItemMedia.max_video_size()),
              r2_key <- StreamData.string(:alphanumeric, min_length: 10, max_length: 100)
            ) do
        attrs = %{
          file_name: file_name,
          content_type: content_type,
          file_size: file_size,
          r2_key: "sahajaonline/sahajstore/#{r2_key}",
          media_type: "video"
        }

        changeset = StoreItemMedia.changeset(%StoreItemMedia{}, attrs)
        assert changeset.valid?, "Errors: #{inspect(changeset.errors)}"
      end
    end
  end
end
