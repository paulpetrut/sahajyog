defmodule Sahajyog.VideoProvider do
  @moduledoc """
  Unified interface for working with different video providers.
  """

  alias Sahajyog.Vimeo
  alias Sahajyog.YouTube

  def detect_provider(url) do
    cond do
      String.contains?(url, "youtube.com") or String.contains?(url, "youtu.be") ->
        :youtube

      String.contains?(url, "vimeo.com") ->
        :vimeo

      true ->
        :unknown
    end
  end

  def extract_video_id(url, provider) do
    case provider do
      :youtube -> YouTube.extract_video_id(url)
      :vimeo -> Vimeo.extract_video_id(url)
      _ -> nil
    end
  end

  def fetch_metadata(url, provider) do
    case provider do
      :youtube -> YouTube.fetch_metadata(url)
      :vimeo -> Vimeo.fetch_metadata(url)
      _ -> {:error, :unsupported_provider}
    end
  end

  # Supported subtitle languages
  @supported_subtitle_locales ["en", "ro", "it", "de", "es", "fr"]

  def embed_url(video_id, provider, locale \\ "en")

  def embed_url(video_id, :youtube, locale) do
    # rel=0 limits suggestions to same channel
    # modestbranding=1 reduces YouTube branding
    # enablejsapi=1 enables JavaScript API for better control
    base_params = "rel=0&modestbranding=1&controls=1&enablejsapi=1"

    # Normalize locale - if not in supported list, default to English
    normalized_locale = if locale in @supported_subtitle_locales, do: locale, else: "en"

    # Enable subtitles automatically for non-English locales
    subtitle_params =
      if normalized_locale != "en" do
        "&cc_load_policy=1&cc_lang_pref=#{normalized_locale}"
      else
        ""
      end

    # Use standard YouTube embed (youtube-nocookie.com can cause issues on some browsers)
    "https://www.youtube.com/embed/#{video_id}?#{base_params}#{subtitle_params}"
  end

  def embed_url(video_id, :vimeo, locale) do
    # video_id may include privacy hash like "88498806/98ec714f1d"
    # Convert to Vimeo's ?h= parameter format for private videos
    base_params = "app_id=122963&title=0&byline=0&portrait=0"

    # Normalize locale - if not in supported list, default to English
    normalized_locale = if locale in @supported_subtitle_locales, do: locale, else: "en"

    # Enable subtitles automatically for non-English locales
    subtitle_params =
      if normalized_locale != "en" do
        "&texttrack=#{normalized_locale}"
      else
        ""
      end

    case String.split(video_id, "/") do
      [id, hash] ->
        "https://player.vimeo.com/video/#{id}?h=#{hash}&#{base_params}#{subtitle_params}"

      [id] ->
        "https://player.vimeo.com/video/#{id}?#{base_params}#{subtitle_params}"
    end
  end

  def embed_url(_video_id, _provider, _locale), do: nil
end
