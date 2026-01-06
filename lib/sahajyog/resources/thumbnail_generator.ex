defmodule Sahajyog.Resources.ThumbnailGenerator do
  @moduledoc """
  Generates thumbnails for various file types using Thumbnex.
  Supports images, PDFs, videos, and audio files.
  """

  require Logger

  @thumbnail_width 300
  @thumbnail_height 300

  @doc """
  Generates a thumbnail for the given file.
  Returns {:ok, thumbnail_path} or {:error, reason}.
  """
  def generate(file_path, content_type) do
    cond do
      String.starts_with?(content_type, "image/") ->
        generate_image_thumbnail(file_path)

      String.contains?(content_type, "pdf") ->
        generate_pdf_thumbnail(file_path)

      String.starts_with?(content_type, "video/") ->
        generate_video_thumbnail(file_path)

      String.starts_with?(content_type, "audio/") ->
        generate_audio_thumbnail(file_path)

      true ->
        {:error, :unsupported_type}
    end
  end

  defp generate_image_thumbnail(file_path) do
    output_path = temp_thumbnail_path("jpg")

    # Use Thumbnex for safer image processing - no shell commands
    case Thumbnex.create_thumbnail(file_path, output_path,
           max_width: @thumbnail_width,
           max_height: @thumbnail_height
         ) do
      :ok ->
        {:ok, output_path}

      {:error, reason} ->
        Logger.error("Image thumbnail generation failed: #{inspect(reason)}")
        {:error, :thumbnail_generation_failed}
    end
  rescue
    e ->
      Logger.error("Image thumbnail generation error: #{inspect(e)}")
      {:error, :thumbnail_generation_failed}
  end

  defp generate_pdf_thumbnail(file_path) do
    output_path = temp_thumbnail_path("jpg")

    # Thumbnex supports PDF thumbnails - maintain aspect ratio
    case Thumbnex.create_thumbnail(file_path, output_path,
           max_width: @thumbnail_width,
           max_height: @thumbnail_height
         ) do
      :ok ->
        {:ok, output_path}

      {:error, reason} ->
        Logger.error("PDF thumbnail generation failed: #{inspect(reason)}")
        {:error, :thumbnail_generation_failed}
    end
  rescue
    e ->
      Logger.error("PDF thumbnail generation error: #{inspect(e)}")
      {:error, :thumbnail_generation_failed}
  end

  defp generate_video_thumbnail(file_path) do
    output_path = temp_thumbnail_path("jpg")

    # Thumbnex supports video thumbnails via FFmpeg - maintain aspect ratio
    case Thumbnex.create_thumbnail(file_path, output_path,
           max_width: @thumbnail_width,
           max_height: @thumbnail_height,
           time: 1
         ) do
      :ok ->
        {:ok, output_path}

      {:error, reason} ->
        Logger.error("Video thumbnail generation failed: #{inspect(reason)}")
        {:error, :thumbnail_generation_failed}
    end
  rescue
    e ->
      Logger.error("Video thumbnail generation error: #{inspect(e)}")
      {:error, :thumbnail_generation_failed}
  end

  defp generate_audio_thumbnail(file_path) do
    output_path = temp_thumbnail_path("jpg")

    # Try to extract embedded album art using Thumbnex - maintain aspect ratio
    case Thumbnex.create_thumbnail(file_path, output_path,
           max_width: @thumbnail_width,
           max_height: @thumbnail_height
         ) do
      :ok ->
        {:ok, output_path}

      {:error, _reason} ->
        # No embedded artwork, skip thumbnail for audio
        Logger.info("No album art found for audio file, skipping thumbnail")
        {:error, :no_album_art}
    end
  rescue
    e ->
      Logger.error("Audio thumbnail generation error: #{inspect(e)}")
      {:error, :thumbnail_generation_failed}
  end

  defp temp_thumbnail_path(extension) do
    random_name = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    Path.join(System.tmp_dir!(), "thumb_#{random_name}.#{extension}")
  end

  @doc """
  Checks if Thumbnex and its dependencies are properly configured.
  """
  def check_dependencies do
    # Thumbnex will handle dependency checking internally
    # We just verify the module is available
    %{
      thumbnex: Code.ensure_loaded?(Thumbnex)
    }
  end
end
