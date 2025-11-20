#!/usr/bin/env elixir

# Script to clean up all objects in R2 bucket
# Usage: mix run clean_r2_bucket.exs
# Add --confirm flag to actually delete: mix run clean_r2_bucket.exs --confirm

alias Sahajyog.Resources.R2Storage

defmodule R2Helper do
  def format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  def format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 2)} KB"

  def format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 2)} MB"

  def format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
end

confirm? = "--confirm" in System.argv()

IO.puts("\n🧹 R2 Bucket Cleanup Script\n")

unless confirm? do
  IO.puts("⚠️  DRY RUN MODE - No files will be deleted")
  IO.puts("    Run with --confirm flag to actually delete files\n")
end

case R2Storage.list_objects() do
  {:ok, objects} ->
    total_size = Enum.reduce(objects, 0, fn obj, acc -> acc + obj.size end)
    count = length(objects)

    IO.puts("📊 Found #{count} objects totaling #{R2Helper.format_bytes(total_size)}\n")

    if count == 0 do
      IO.puts("✅ Bucket is already empty!")
    else
      IO.puts("🗑️  Objects to delete:\n")

      Enum.each(objects, fn obj ->
        IO.puts("  - #{obj.key} (#{R2Helper.format_bytes(obj.size)})")
      end)

      if confirm? do
        IO.puts("\n⏳ Deleting objects...")

        results =
          Enum.map(objects, fn obj ->
            case R2Storage.delete(obj.key) do
              :ok ->
                IO.puts("  ✓ Deleted: #{obj.key}")
                {:ok, obj}

              {:error, reason} ->
                IO.puts("  ✗ Failed: #{obj.key} - #{inspect(reason)}")
                {:error, obj}
            end
          end)

        success_count = Enum.count(results, fn {status, _} -> status == :ok end)
        failed_count = Enum.count(results, fn {status, _} -> status == :error end)

        IO.puts("\n✅ Cleanup complete!")
        IO.puts("  Deleted: #{success_count}")
        IO.puts("  Failed: #{failed_count}")

        if failed_count > 0 do
          IO.puts("\n⚠️  Some files failed to delete. Check the errors above.")
        end
      else
        IO.puts("\n💡 Run with --confirm to actually delete these files:")
        IO.puts("   mix run clean_r2_bucket.exs --confirm")
      end
    end

  {:error, reason} ->
    IO.puts("❌ Error listing objects: #{inspect(reason)}")
    IO.puts("\nMake sure your R2 credentials are configured correctly.")
end
