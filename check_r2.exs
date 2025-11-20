alias Sahajyog.Resources.R2Storage

IO.puts("\n🔍 Checking R2 bucket...\n")

case R2Storage.list_objects() do
  {:ok, objects} ->
    IO.puts("✅ Found #{length(objects)} objects\n")

    if length(objects) == 0 do
      IO.puts("Bucket is empty!")
    else
      IO.puts("📄 Raw object data:")
      IO.inspect(objects, limit: :infinity, pretty: true)

      IO.puts("\n📊 Calculating total size...")

      total_size =
        Enum.reduce(objects, 0, fn obj, acc ->
          size =
            cond do
              is_binary(obj.size) -> String.to_integer(obj.size)
              is_integer(obj.size) -> obj.size
              true -> 0
            end

          acc + size
        end)

      IO.puts("\nTotal size: #{Float.round(total_size / (1024 * 1024), 2)} MB")

      IO.puts("\n📁 Files:")

      Enum.each(objects, fn obj ->
        size =
          cond do
            is_binary(obj.size) -> String.to_integer(obj.size)
            is_integer(obj.size) -> obj.size
            true -> 0
          end

        size_mb = Float.round(size / (1024 * 1024), 2)
        IO.puts("  #{obj.key} - #{size_mb} MB")
      end)
    end

  {:error, reason} ->
    IO.puts("❌ Error: #{inspect(reason)}")
end
