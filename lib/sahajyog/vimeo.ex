defmodule Sahajyog.Vimeo do
  @moduledoc """
  Helper module for fetching Vimeo video metadata.
  """

  def extract_video_id(url) do
    if String.contains?(url, "vimeo.com/") do
      # Extract everything after vimeo.com/ including privacy hash
      url
      |> String.split("vimeo.com/")
      |> List.last()
      |> String.split("?")
      |> List.first()
    else
      nil
    end
  end

  def fetch_metadata(url) do
    case extract_video_id(url) do
      nil ->
        {:error, :invalid_url}

      video_id ->
        # Use Vimeo oEmbed API with the full URL (handles private videos with hash)
        # The oEmbed API needs the full URL to work with private videos
        clean_url = "https://vimeo.com/#{video_id}"
        oembed_url = "https://vimeo.com/api/oembed.json?url=#{URI.encode(clean_url)}"

        case Req.get(oembed_url) do
          {:ok, %{status: 200, body: body}} ->
            {:ok,
             %{
               title: body["title"],
               thumbnail_url: body["thumbnail_url"],
               author: body["author_name"],
               duration: format_duration(body["duration"])
             }}

          _ ->
            {:error, :fetch_failed}
        end
    end
  end

  defp format_duration(nil), do: nil

  defp format_duration(seconds) when is_integer(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(to_string(secs), 2, "0")}"
  end
end
