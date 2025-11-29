defmodule SahajyogWeb.FormatHelpers do
  @moduledoc """
  Shared formatting helpers used across the application.
  """

  @doc """
  Formats a file size in bytes to a human-readable string.

  ## Examples

      iex> format_file_size(500)
      "500 B"

      iex> format_file_size(1536)
      "1.5 KB"

      iex> format_file_size(1_048_576)
      "1.0 MB"
  """
  def format_file_size(bytes) when is_nil(bytes), do: "0 B"
  def format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  def format_file_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  def format_file_size(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 1)} MB"

  def format_file_size(bytes),
    do: "#{Float.round(bytes / (1024 * 1024 * 1024), 1)} GB"

  @doc """
  Strips HTML tags from a string.

  ## Examples

      iex> strip_html_tags("<p>Hello <strong>World</strong></p>")
      "Hello World"
  """
  def strip_html_tags(html) when is_binary(html) do
    html
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  def strip_html_tags(_), do: ""

  @doc """
  Truncates text to a specified length with ellipsis.

  ## Examples

      iex> truncate_text("Hello World", 5)
      "Hello..."

      iex> truncate_text("Hi", 5)
      "Hi"
  """
  def truncate_text(text, max_length) when is_binary(text) and byte_size(text) > max_length do
    String.slice(text, 0, max_length) <> "..."
  end

  def truncate_text(text, _max_length), do: text || ""

  @doc """
  Formats a duration in seconds to a human-readable string.

  ## Examples

      iex> format_duration(3661)
      "1h 1m"

      iex> format_duration(125)
      "2m 5s"

      iex> format_duration(45)
      "45s"

      iex> format_duration(nil)
      nil
  """
  def format_duration(seconds) when is_integer(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    cond do
      hours > 0 -> "#{hours}h #{minutes}m"
      minutes > 0 -> "#{minutes}m #{secs}s"
      true -> "#{secs}s"
    end
  end

  def format_duration(_), do: nil
end
