alias Sahajyog.Resources.R2Storage

IO.puts("\n🔍 Checking for incomplete multipart uploads...\n")

bucket = Application.get_env(:sahajyog, :r2)[:bucket]

case ExAws.S3.list_multipart_uploads(bucket) |> ExAws.request() do
  {:ok, %{body: body}} ->
    IO.puts("Raw response:")
    IO.inspect(body, limit: :infinity, pretty: true)

  {:error, reason} ->
    IO.puts("❌ Error: #{inspect(reason)}")
end
