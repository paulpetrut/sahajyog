defmodule Sahajyog.Resources.R2Storage do
  @moduledoc """
  Handles file uploads and downloads with Cloudflare R2.
  """

  @doc """
  Uploads a file to R2 and returns the key.
  Uses direct put_object for reliability (no multipart upload issues).
  """
  def upload(file_path, key, opts \\ []) do
    bucket = get_bucket()
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    case File.read(file_path) do
      {:ok, content} ->
        ExAws.S3.put_object(bucket, key, content, content_type: content_type)
        |> ExAws.request(http_opts: [recv_timeout: 120_000, connect_timeout: 30_000])
        |> case do
          {:ok, _response} -> {:ok, key}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_read_error, reason}}
    end
  end

  @doc """
  Generates a presigned URL for downloading a file from R2.
  Valid for 1 hour by default.
  """
  def generate_download_url(key, opts \\ []) do
    bucket = get_bucket()
    expires_in = Keyword.get(opts, :expires_in, 3600)
    force_download = Keyword.get(opts, :force_download, false)

    config = ExAws.Config.new(:s3)

    query_params =
      if force_download do
        filename = extract_filename(key)
        [{"response-content-disposition", "attachment; filename=\"#{filename}\""}]
      else
        []
      end

    {:ok, url} =
      ExAws.S3.presigned_url(config, :get, bucket, key,
        expires_in: expires_in,
        query_params: query_params
      )

    url
  end

  defp extract_filename(key) do
    key
    |> String.split("/")
    |> List.last()
    |> String.replace(~r/^[a-f0-9]{8}-/, "")
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
    case Application.get_env(:sahajyog, :r2) do
      nil ->
        raise """
        R2_BUCKET_NAME not configured.

        For development, run: source load_env.sh && mix phx.server
        For production, ensure R2_BUCKET_NAME environment variable is set.
        """

      config ->
        config[:bucket] ||
          raise """
          R2_BUCKET_NAME not configured.

          For development, run: source load_env.sh && mix phx.server
          For production, ensure R2_BUCKET_NAME environment variable is set.
          """
    end
  end
end
