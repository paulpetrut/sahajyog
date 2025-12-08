# Script to abort incomplete multipart uploads in R2
# Usage: source .env && mix run abort_multipart_upload.exs

IO.puts("\n🔍 Checking for incomplete multipart uploads in R2...\n")

# Get R2 config
bucket = Application.get_env(:sahajyog, :r2)[:bucket]
account_id = System.get_env("R2_ACCOUNT_ID")

# Build the proper R2 config
r2_config = [
  access_key_id: System.get_env("R2_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("R2_SECRET_ACCESS_KEY"),
  region: "auto",
  host: "#{account_id}.r2.cloudflarestorage.com",
  scheme: "https://"
]

IO.puts("Bucket: #{bucket}")
IO.puts("Host: #{account_id}.r2.cloudflarestorage.com\n")

case ExAws.S3.list_multipart_uploads(bucket) |> ExAws.request(r2_config) do
  {:ok, %{body: %{uploads: uploads}}} when is_list(uploads) and uploads != [] ->
    IO.puts("Found #{length(uploads)} incomplete multipart upload(s):\n")

    for upload <- uploads do
      IO.puts("  Key: #{upload.key}")
      IO.puts("  Upload ID: #{upload.upload_id}")
      IO.puts("")

      IO.puts("  Aborting upload...")

      case ExAws.S3.abort_multipart_upload(bucket, upload.key, upload.upload_id)
           |> ExAws.request(r2_config) do
        {:ok, _} ->
          IO.puts("  ✅ Successfully aborted!\n")

        {:error, reason} ->
          IO.puts("  ❌ Failed to abort: #{inspect(reason)}\n")
      end
    end

  {:ok, %{body: body}} ->
    IO.puts("No incomplete multipart uploads found.")
    IO.puts("Raw response: #{inspect(body)}")

  {:error, reason} ->
    IO.puts("❌ Error listing uploads: #{inspect(reason)}")
end

IO.puts("\n✅ Done!")
