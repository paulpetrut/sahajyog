defmodule Sahajyog.VideoProvider do
  @moduledoc """
  Unified interface for working with different video providers.
  """

  alias Sahajyog.YouTube
  alias Sahajyog.Vimeo

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

  def embed_url(video_id, :youtube) do
    "https://www.youtube.com/embed/#{video_id}?rel=0&modestbranding=1&showinfo=0&controls=1"
  end

  def embed_url(video_id, :vimeo) do
    # video_id may include privacy hash like "88498806/98ec714f1d"
    # Convert to Vimeo's ?h= parameter format for private videos
    case String.split(video_id, "/") do
      [id, hash] ->
        "https://player.vimeo.com/video/#{id}?h=#{hash}&app_id=122963&title=0&byline=0&portrait=0"

      [id] ->
        "https://player.vimeo.com/video/#{id}?app_id=122963&title=0&byline=0&portrait=0"
    end
  end

  def embed_url(_video_id, _provider), do: nil
end
