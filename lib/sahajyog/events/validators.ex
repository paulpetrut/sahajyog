defmodule Sahajyog.Events.Validators do
  @moduledoc """
  URL validation helpers for event-related fields.
  """

  @youtube_patterns [
    # Standard watch URL: youtube.com/watch?v=VIDEO_ID
    ~r/^https?:\/\/(?:www\.)?youtube\.com\/watch\?(?:.*&)?v=([a-zA-Z0-9_-]{11})(?:&.*)?$/,
    # Short URL: youtu.be/VIDEO_ID
    ~r/^https?:\/\/youtu\.be\/([a-zA-Z0-9_-]{11})(?:\?.*)?$/,
    # Embed URL: youtube.com/embed/VIDEO_ID
    ~r/^https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]{11})(?:\?.*)?$/,
    # Shorts URL: youtube.com/shorts/VIDEO_ID
    ~r/^https?:\/\/(?:www\.)?youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})(?:\?.*)?$/
  ]

  @doc """
  Validates that a URL is a valid HTTP or HTTPS URL.

  Returns `true` if the URL starts with http:// or https:// and has a valid structure.
  Returns `false` for nil, empty strings, or invalid URLs.

  ## Examples

      iex> Sahajyog.Events.Validators.valid_url?("https://zoom.us/j/123456")
      true

      iex> Sahajyog.Events.Validators.valid_url?("ftp://example.com")
      false

      iex> Sahajyog.Events.Validators.valid_url?(nil)
      false
  """
  @spec valid_url?(String.t() | nil) :: boolean()
  def valid_url?(nil), do: false
  def valid_url?(""), do: false

  def valid_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host}
      when scheme in ["http", "https"] and is_binary(host) and host != "" ->
        true

      _ ->
        false
    end
  end

  def valid_url?(_), do: false

  @doc """
  Validates that a URL is a valid YouTube video URL.

  Accepts the following YouTube URL formats:
  - youtube.com/watch?v=VIDEO_ID
  - youtu.be/VIDEO_ID
  - youtube.com/embed/VIDEO_ID
  - youtube.com/shorts/VIDEO_ID

  Returns `true` if the URL matches any valid YouTube video URL pattern.
  Returns `false` for nil, empty strings, or non-YouTube URLs.

  ## Examples

      iex> Sahajyog.Events.Validators.valid_youtube_url?("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      true

      iex> Sahajyog.Events.Validators.valid_youtube_url?("https://youtu.be/dQw4w9WgXcQ")
      true

      iex> Sahajyog.Events.Validators.valid_youtube_url?("https://example.com/video")
      false
  """
  @spec valid_youtube_url?(String.t() | nil) :: boolean()
  def valid_youtube_url?(nil), do: false
  def valid_youtube_url?(""), do: false

  def valid_youtube_url?(url) when is_binary(url) do
    Enum.any?(@youtube_patterns, fn pattern ->
      Regex.match?(pattern, url)
    end)
  end

  def valid_youtube_url?(_), do: false

  @doc """
  Extracts the video ID from a YouTube URL.

  Returns `{:ok, video_id}` if the URL is a valid YouTube URL.
  Returns `:error` if the URL is not a valid YouTube URL.

  ## Examples

      iex> Sahajyog.Events.Validators.extract_youtube_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> Sahajyog.Events.Validators.extract_youtube_id("https://youtu.be/dQw4w9WgXcQ")
      {:ok, "dQw4w9WgXcQ"}

      iex> Sahajyog.Events.Validators.extract_youtube_id("https://example.com")
      :error
  """
  @spec extract_youtube_id(String.t() | nil) :: {:ok, String.t()} | :error
  def extract_youtube_id(nil), do: :error
  def extract_youtube_id(""), do: :error

  def extract_youtube_id(url) when is_binary(url) do
    result =
      Enum.find_value(@youtube_patterns, fn pattern ->
        case Regex.run(pattern, url) do
          [_, video_id] -> video_id
          _ -> nil
        end
      end)

    case result do
      nil -> :error
      video_id -> {:ok, video_id}
    end
  end

  def extract_youtube_id(_), do: :error

  @doc """
  Validates a meeting platform URL.

  This is an alias for `valid_url?/1` since meeting URLs from various platforms
  (Teams, Zoom, Google Meet, Webex, etc.) are all valid HTTP/HTTPS URLs.

  ## Examples

      iex> Sahajyog.Events.Validators.valid_meeting_url?("https://teams.microsoft.com/l/meetup-join/...")
      true

      iex> Sahajyog.Events.Validators.valid_meeting_url?("https://zoom.us/j/123456789")
      true
  """
  @spec valid_meeting_url?(String.t() | nil) :: boolean()
  def valid_meeting_url?(url), do: valid_url?(url)

  @supported_video_mime_types ~w(video/mp4 video/webm video/quicktime)
  @supported_video_extensions ~w(.mp4 .webm .mov)

  @doc """
  Returns the list of supported video MIME types.
  """
  @spec supported_video_mime_types() :: [String.t()]
  def supported_video_mime_types, do: @supported_video_mime_types

  @doc """
  Returns the list of supported video file extensions.
  """
  @spec supported_video_extensions() :: [String.t()]
  def supported_video_extensions, do: @supported_video_extensions

  @doc """
  Validates that a MIME type is a supported video format.

  Supported formats: video/mp4, video/webm, video/quicktime

  ## Examples

      iex> Sahajyog.Events.Validators.valid_video_mime_type?("video/mp4")
      true

      iex> Sahajyog.Events.Validators.valid_video_mime_type?("video/avi")
      false

      iex> Sahajyog.Events.Validators.valid_video_mime_type?(nil)
      false
  """
  @spec valid_video_mime_type?(String.t() | nil) :: boolean()
  def valid_video_mime_type?(nil), do: false
  def valid_video_mime_type?(""), do: false

  def valid_video_mime_type?(mime_type) when is_binary(mime_type) do
    mime_type in @supported_video_mime_types
  end

  def valid_video_mime_type?(_), do: false

  @doc """
  Validates that a file extension is a supported video format.

  Supported extensions: .mp4, .webm, .mov

  ## Examples

      iex> Sahajyog.Events.Validators.valid_video_extension?(".mp4")
      true

      iex> Sahajyog.Events.Validators.valid_video_extension?("mp4")
      true

      iex> Sahajyog.Events.Validators.valid_video_extension?(".avi")
      false
  """
  @spec valid_video_extension?(String.t() | nil) :: boolean()
  def valid_video_extension?(nil), do: false
  def valid_video_extension?(""), do: false

  def valid_video_extension?(ext) when is_binary(ext) do
    normalized = if String.starts_with?(ext, "."), do: ext, else: ".#{ext}"
    String.downcase(normalized) in @supported_video_extensions
  end

  def valid_video_extension?(_), do: false

  @doc """
  Validates that an R2 storage key follows the expected pattern for event videos.

  Expected pattern: Events/{slug}/videos/{uuid}-{filename}

  ## Examples

      iex> Sahajyog.Events.Validators.valid_event_video_r2_key?("Events/my-event/videos/abc12345-video.mp4")
      true

      iex> Sahajyog.Events.Validators.valid_event_video_r2_key?("other/path/video.mp4")
      false
  """
  @spec valid_event_video_r2_key?(String.t() | nil) :: boolean()
  def valid_event_video_r2_key?(nil), do: false
  def valid_event_video_r2_key?(""), do: false

  def valid_event_video_r2_key?(key) when is_binary(key) do
    # Pattern: Events/{slug}/videos/{uuid}-{filename}
    # UUID is 8 characters (first part of Ecto.UUID)
    Regex.match?(~r/^Events\/[a-z0-9-]+\/videos\/[a-f0-9]{8}-[a-zA-Z0-9._-]+$/, key)
  end

  def valid_event_video_r2_key?(_), do: false

  @doc """
  Generates an R2 storage key for an event video.

  ## Examples

      iex> key = Sahajyog.Events.Validators.generate_event_video_key("my-event", "video.mp4")
      iex> String.starts_with?(key, "Events/my-event/videos/")
      true
  """
  @spec generate_event_video_key(String.t(), String.t()) :: String.t()
  def generate_event_video_key(slug, filename) when is_binary(slug) and is_binary(filename) do
    uuid = Ecto.UUID.generate() |> String.slice(0, 8)
    sanitized_filename = sanitize_filename(filename)
    "Events/#{slug}/videos/#{uuid}-#{sanitized_filename}"
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 200)
  end
end
