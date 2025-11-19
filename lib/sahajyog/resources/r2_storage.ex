defmodule Sahajyog.Resources.R2Storage do
  @moduledoc """
  Handles file uploads and downloads with Cloudflare R2.
  """

  @doc """
  Uploads a file to R2 and returns the key.
  """
  def upload(file_path, key, opts \\ []) do
    bucket = get_bucket()
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    file_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket, key, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _response} -> {:ok, key}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates a presigned URL for downloading a file from R2.
  Valid for 1 hour by default.
  """
  def generate_download_url(key, opts \\ []) do
    bucket = get_bucket()
    expires_in = Keyword.get(opts, :expires_in, 3600)

    config = ExAws.Config.new(:s3)

    {:ok, url} =
      ExAws.S3.presigned_url(config, :get, bucket, key, expires_in: expires_in)

    url
  end

  @doc """
  Deletes a file from R2.
  """
  def delete(key) do
    bucket = get_bucket()

    bucket
    |> ExAws.S3.delete_object(key)
    |> ExAws.request()
    |> case do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Lists all objects in the bucket with optional prefix.
  """
  def list_objects(prefix \\ "") do
    bucket = get_bucket()

    bucket
    |> ExAws.S3.list_objects(prefix: prefix)
    |> ExAws.request()
    |> case do
      {:ok, %{body: %{contents: contents}}} -> {:ok, contents}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generates a key for storing a file in R2 matching your existing structure.
  Format: Level1/Photos/filename or Level2/Books/filename
  """
  def generate_key(filename, level, resource_type) do
    sanitized_filename = sanitize_filename(filename)
    "#{level}/#{resource_type}/#{sanitized_filename}"
  end

  @doc """
  Generates a unique key with UUID to avoid filename conflicts.
  Format: Level1/Photos/uuid-filename
  """
  def generate_unique_key(filename, level, resource_type) do
    uuid = Ecto.UUID.generate() |> String.slice(0, 8)
    sanitized_filename = sanitize_filename(filename)
    "#{level}/#{resource_type}/#{uuid}-#{sanitized_filename}"
  end

  defp sanitize_filename(filename) do
    filename
    |> String.replace(~r/[^a-zA-Z0-9._-]/, "_")
    |> String.slice(0, 200)
  end

  defp get_bucket do
    Application.get_env(:sahajyog, :r2)[:bucket] ||
      raise "R2_BUCKET_NAME not configured"
  end
end
