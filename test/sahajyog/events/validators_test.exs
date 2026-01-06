defmodule Sahajyog.Events.ValidatorsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Sahajyog.Events.Validators

  # **Feature: online-event-enhancements, Property 1: Meeting URL Validation**
  # **Validates: Requirements 1.2, 1.3**
  describe "Property 1: Meeting URL Validation" do
    property "accepts only valid HTTP or HTTPS URLs" do
      check all(url <- valid_http_url()) do
        assert Validators.valid_url?(url) == true
        assert Validators.valid_meeting_url?(url) == true
      end
    end

    property "rejects non-HTTP/HTTPS URLs" do
      check all(url <- invalid_url()) do
        assert Validators.valid_url?(url) == false
        assert Validators.valid_meeting_url?(url) == false
      end
    end

    property "accepts common meeting platform URLs" do
      check all(url <- meeting_platform_url()) do
        assert Validators.valid_url?(url) == true
        assert Validators.valid_meeting_url?(url) == true
      end
    end

    test "rejects nil and empty strings" do
      assert Validators.valid_url?(nil) == false
      assert Validators.valid_url?("") == false
      assert Validators.valid_meeting_url?(nil) == false
      assert Validators.valid_meeting_url?("") == false
    end
  end

  # Generators for Property 1

  defp valid_http_url do
    gen all(
          scheme <- member_of(["http", "https"]),
          host <- host_string(),
          path <- path_string()
        ) do
      "#{scheme}://#{host}#{path}"
    end
  end

  defp host_string do
    gen all(
          subdomain <- string(:alphanumeric, min_length: 1, max_length: 10),
          domain <- string(:alphanumeric, min_length: 1, max_length: 10),
          tld <- member_of(["com", "org", "net", "io", "us", "co"])
        ) do
      "#{subdomain}.#{domain}.#{tld}"
    end
  end

  defp path_string do
    gen all(
          segments <- list_of(string(:alphanumeric, min_length: 1, max_length: 10), max_length: 3)
        ) do
      case segments do
        [] -> ""
        _ -> "/" <> Enum.join(segments, "/")
      end
    end
  end

  defp invalid_url do
    one_of([
      # FTP URLs
      gen all(host <- host_string()) do
        "ftp://#{host}"
      end,
      # File URLs
      constant("file:///path/to/file"),
      # Mailto URLs
      gen all(email <- email_string()) do
        "mailto:#{email}"
      end,
      # Plain text (not URLs)
      string(:alphanumeric, min_length: 1, max_length: 50),
      # Missing scheme
      gen all(host <- host_string()) do
        host
      end
    ])
  end

  defp email_string do
    gen all(
          local <- string(:alphanumeric, min_length: 1, max_length: 10),
          domain <- string(:alphanumeric, min_length: 1, max_length: 10)
        ) do
      "#{local}@#{domain}.com"
    end
  end

  defp meeting_platform_url do
    one_of([
      # Microsoft Teams
      gen all(meeting_id <- string(:alphanumeric, min_length: 10, max_length: 20)) do
        "https://teams.microsoft.com/l/meetup-join/#{meeting_id}"
      end,
      # Zoom
      gen all(meeting_id <- integer(100_000_000..999_999_999)) do
        "https://zoom.us/j/#{meeting_id}"
      end,
      # Google Meet
      gen all(code <- string(:alphanumeric, min_length: 10, max_length: 12)) do
        "https://meet.google.com/#{code}"
      end,
      # Webex
      gen all(room <- string(:alphanumeric, min_length: 5, max_length: 15)) do
        "https://webex.com/meet/#{room}"
      end
    ])
  end

  # **Feature: online-event-enhancements, Property 2: YouTube URL Validation**
  # **Validates: Requirements 2.3**
  describe "Property 2: YouTube URL Validation" do
    property "accepts valid YouTube video URLs in all formats" do
      check all(url <- valid_youtube_url()) do
        assert Validators.valid_youtube_url?(url) == true
      end
    end

    property "extracts video ID from valid YouTube URLs" do
      check all({url, expected_id} <- youtube_url_with_id()) do
        assert {:ok, ^expected_id} = Validators.extract_youtube_id(url)
      end
    end

    property "rejects non-YouTube URLs" do
      check all(url <- non_youtube_url()) do
        assert Validators.valid_youtube_url?(url) == false
        assert Validators.extract_youtube_id(url) == :error
      end
    end

    test "rejects nil and empty strings" do
      assert Validators.valid_youtube_url?(nil) == false
      assert Validators.valid_youtube_url?("") == false
      assert Validators.extract_youtube_id(nil) == :error
      assert Validators.extract_youtube_id("") == :error
    end
  end

  # **Feature: online-event-enhancements, Property 3: Video File Format Validation**
  # **Validates: Requirements 2.6**
  describe "Property 3: Video File Format Validation" do
    property "accepts only supported video MIME types" do
      check all(mime_type <- supported_video_mime_type()) do
        assert Validators.valid_video_mime_type?(mime_type) == true
      end
    end

    property "rejects unsupported video MIME types" do
      check all(mime_type <- unsupported_video_mime_type()) do
        assert Validators.valid_video_mime_type?(mime_type) == false
      end
    end

    property "accepts only supported video file extensions" do
      check all(ext <- supported_video_extension()) do
        assert Validators.valid_video_extension?(ext) == true
      end
    end

    property "rejects unsupported video file extensions" do
      check all(ext <- unsupported_video_extension()) do
        assert Validators.valid_video_extension?(ext) == false
      end
    end

    test "rejects nil and empty strings for MIME types" do
      assert Validators.valid_video_mime_type?(nil) == false
      assert Validators.valid_video_mime_type?("") == false
    end

    test "rejects nil and empty strings for extensions" do
      assert Validators.valid_video_extension?(nil) == false
      assert Validators.valid_video_extension?("") == false
    end
  end

  # **Feature: online-event-enhancements, Property 4: R2 Storage Path Format**
  # **Validates: Requirements 2.5**
  describe "Property 4: R2 Storage Path Format" do
    property "generated keys follow the expected pattern" do
      check all(
              slug <- event_slug(),
              filename <- video_filename()
            ) do
        key = Validators.generate_event_video_key(slug, filename)
        assert Validators.valid_event_video_r2_key?(key) == true
        assert String.starts_with?(key, "Events/#{slug}/videos/")
      end
    end

    property "validates correct R2 key patterns" do
      check all(key <- valid_event_video_r2_key()) do
        assert Validators.valid_event_video_r2_key?(key) == true
      end
    end

    property "rejects invalid R2 key patterns" do
      check all(key <- invalid_event_video_r2_key()) do
        assert Validators.valid_event_video_r2_key?(key) == false
      end
    end

    test "rejects nil and empty strings" do
      assert Validators.valid_event_video_r2_key?(nil) == false
      assert Validators.valid_event_video_r2_key?("") == false
    end
  end

  # Generators for Property 3

  defp supported_video_mime_type do
    member_of(["video/mp4", "video/webm", "video/quicktime"])
  end

  defp unsupported_video_mime_type do
    one_of([
      constant("video/avi"),
      constant("video/x-msvideo"),
      constant("video/x-matroska"),
      constant("video/x-flv"),
      constant("video/3gpp"),
      constant("audio/mp3"),
      constant("image/jpeg"),
      constant("application/pdf"),
      # Random MIME types
      gen all(
            type <- member_of(["text", "application", "audio", "image"]),
            subtype <- string(:alphanumeric, min_length: 3, max_length: 10)
          ) do
        "#{type}/#{subtype}"
      end
    ])
  end

  defp supported_video_extension do
    one_of([
      # With dot prefix
      member_of([".mp4", ".webm", ".mov"]),
      # Without dot prefix
      member_of(["mp4", "webm", "mov"]),
      # Uppercase variants
      member_of([".MP4", ".WEBM", ".MOV", "MP4", "WEBM", "MOV"])
    ])
  end

  defp unsupported_video_extension do
    one_of([
      constant(".avi"),
      constant(".mkv"),
      constant(".flv"),
      constant(".wmv"),
      constant(".3gp"),
      constant(".gif"),
      constant(".jpg"),
      constant(".pdf"),
      constant("avi"),
      constant("mkv")
    ])
  end

  # Generators for Property 4

  defp event_slug do
    gen all(
          parts <-
            list_of(string(:alphanumeric, min_length: 1, max_length: 10),
              min_length: 1,
              max_length: 3
            )
        ) do
      Enum.map_join(parts, "-", &String.downcase/1)
    end
  end

  defp video_filename do
    gen all(
          name <- string(:alphanumeric, min_length: 1, max_length: 20),
          ext <- member_of(["mp4", "webm", "mov"])
        ) do
      "#{name}.#{ext}"
    end
  end

  defp valid_event_video_r2_key do
    gen all(
          slug <- event_slug(),
          uuid <- uuid_prefix(),
          filename <- video_filename()
        ) do
      "Events/#{slug}/videos/#{uuid}-#{filename}"
    end
  end

  defp uuid_prefix do
    # Generate 8 hex characters (first part of UUID)
    gen all(chars <- fixed_list(List.duplicate(hex_char(), 8))) do
      Enum.join(chars)
    end
  end

  defp hex_char do
    member_of(Enum.to_list(?a..?f) ++ Enum.to_list(?0..?9))
    |> map(&<<&1>>)
  end

  defp invalid_event_video_r2_key do
    one_of([
      # Wrong prefix
      gen all(slug <- event_slug(), filename <- video_filename()) do
        "Other/#{slug}/videos/#{filename}"
      end,
      # Missing videos folder
      gen all(slug <- event_slug(), filename <- video_filename()) do
        "Events/#{slug}/#{filename}"
      end,
      # Missing UUID prefix
      gen all(slug <- event_slug(), filename <- video_filename()) do
        "Events/#{slug}/videos/#{filename}"
      end,
      # Wrong UUID format (not hex)
      gen all(slug <- event_slug(), filename <- video_filename()) do
        "Events/#{slug}/videos/XXXXXXXX-#{filename}"
      end,
      # Plain paths
      constant("video.mp4"),
      constant("/path/to/video.mp4")
    ])
  end

  # Generators for Property 2

  defp youtube_video_id do
    # YouTube video IDs are exactly 11 characters: alphanumeric, underscore, hyphen
    gen all(chars <- fixed_list(List.duplicate(youtube_id_char(), 11))) do
      Enum.join(chars)
    end
  end

  defp youtube_id_char do
    # YouTube video IDs use: a-z, A-Z, 0-9, underscore, hyphen
    member_of(
      Enum.to_list(?a..?z) ++
        Enum.to_list(?A..?Z) ++
        Enum.to_list(?0..?9) ++
        [?_, ?-]
    )
    |> map(&<<&1>>)
  end

  defp valid_youtube_url do
    gen all({url, _id} <- youtube_url_with_id()) do
      url
    end
  end

  defp youtube_url_with_id do
    gen all(
          video_id <- youtube_video_id(),
          format <- member_of([:watch, :short, :embed, :shorts])
        ) do
      url =
        case format do
          :watch -> "https://www.youtube.com/watch?v=#{video_id}"
          :short -> "https://youtu.be/#{video_id}"
          :embed -> "https://youtube.com/embed/#{video_id}"
          :shorts -> "https://www.youtube.com/shorts/#{video_id}"
        end

      {url, video_id}
    end
  end

  defp non_youtube_url do
    one_of([
      # Other video platforms
      gen all(id <- string(:alphanumeric, min_length: 5, max_length: 15)) do
        "https://vimeo.com/#{id}"
      end,
      gen all(id <- string(:alphanumeric, min_length: 5, max_length: 15)) do
        "https://dailymotion.com/video/#{id}"
      end,
      # Regular websites
      gen all(host <- host_string()) do
        "https://#{host}/video"
      end,
      # YouTube channel/playlist URLs (not video URLs)
      gen all(channel <- string(:alphanumeric, min_length: 5, max_length: 15)) do
        "https://www.youtube.com/channel/#{channel}"
      end,
      gen all(playlist <- string(:alphanumeric, min_length: 5, max_length: 15)) do
        "https://www.youtube.com/playlist?list=#{playlist}"
      end
    ])
  end
end
