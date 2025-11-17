defmodule Sahajyog.YouTube do
  @moduledoc """
  Helper module for fetching YouTube video metadata.
  """

  def extract_video_id(url) do
    cond do
      String.contains?(url, "youtube.com/watch?v=") ->
        url |> String.split("v=") |> List.last() |> String.split("&") |> List.first()

      String.contains?(url, "youtu.be/") ->
        url |> String.split("youtu.be/") |> List.last() |> String.split("?") |> List.first()

      true ->
        nil
    end
  end

  def fetch_metadata(url) do
    case extract_video_id(url) do
      nil ->
        {:error, :invalid_url}

      video_id ->
        # Use YouTube oEmbed API (no API key required)
        oembed_url =
          "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=#{video_id}&format=json"

        case Req.get(oembed_url) do
          {:ok, %{status: 200, body: body}} ->
            {:ok,
             %{
               title: body["title"],
               thumbnail_url: body["thumbnail_url"],
               author: body["author_name"]
             }}

          _ ->
            # Fallback to basic metadata
            {:ok,
             %{
               title: nil,
               thumbnail_url: "https://img.youtube.com/vi/#{video_id}/maxresdefault.jpg",
               author: nil
             }}
        end
    end
  end
end
