alias Sahajyog.Resources.R2Storage

IO.puts("\n🧹 Cleaning up empty folder markers...\n")

case R2Storage.list_objects() do
  {:ok, objects} ->
    # R2 doesn't actually have folders, but some tools create 0-byte "folder" objects
    empty_folders =
      Enum.filter(objects, fn obj ->
        size = if is_binary(obj.size), do: String.to_integer(obj.size), else: obj.size
        size == 0 && String.ends_with?(obj.key, "/")
      end)

    if length(empty_folders) > 0 do
      IO.puts("Found #{length(empty_folders)} empty folder markers:")
      Enum.each(empty_folders, fn obj -> IO.puts("  - #{obj.key}") end)

      IO.puts("\nDeleting...")

      Enum.each(empty_folders, fn obj ->
        case R2Storage.delete(obj.key) do
          :ok -> IO.puts("  ✓ Deleted: #{obj.key}")
          {:error, reason} -> IO.puts("  ✗ Failed: #{obj.key} - #{inspect(reason)}")
        end
      end)

      IO.puts("\n✅ Done!")
    else
      IO.puts("No empty folder markers found.")
    end

  {:error, reason} ->
    IO.puts("❌ Error: #{inspect(reason)}")
end
