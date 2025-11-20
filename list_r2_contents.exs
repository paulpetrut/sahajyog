#!/usr/bin/env elixir

# Script to list all objects in R2 bucket and show total size
# Usage: mix run list_r2_contents.exs

alias Sahajyog.Resources.R2Storage

defmodule R2Helper do
  def format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  def format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 2)} KB"

  def format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / (1024 * 1024), 2)} MB"

  def format_bytes(bytes), do: "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
end

IO.puts("\n🔍 Scanning R2 bucket contents...\n")

case R2Storage.list_objects() do
  {:ok, objects} ->
    total_size = Enum.reduce(objects, 0, fn obj, acc -> acc + obj.size end)
    count = length(objects)

    IO.puts("📊 Summary:")
    IO.puts("  Total objects: #{count}")
    IO.puts("  Total size: #{R2Helper.format_bytes(total_size)}")
    IO.puts("\n📁 Objects by prefix:\n")

    # Group by prefix (Level1, Level2, Level3, or other)
    grouped =
      objects
      |> Enum.group_by(fn obj ->
        case String.split(obj.key, "/") do
          [prefix | _] -> prefix
          _ -> "root"
        end
      end)

    Enum.each(grouped, fn {prefix, items} ->
      prefix_size = Enum.reduce(items, 0, fn obj, acc -> acc + obj.size end)
      IO.puts("  #{prefix}/")
      IO.puts("    Count: #{length(items)}")
      IO.puts("    Size: #{R2Helper.format_bytes(prefix_size)}")
    end)

    IO.puts("\n📄 All objects:")

    Enum.each(objects, fn obj ->
      IO.puts("  #{obj.key} (#{R2Helper.format_bytes(obj.size)})")
    end)

    IO.puts("\n💡 To delete all objects, run: mix run clean_r2_bucket.exs")

  {:error, reason} ->
    IO.puts("❌ Error listing objects: #{inspect(reason)}")
    IO.puts("\nMake sure your R2 credentials are configured correctly.")
end
