#!/usr/bin/env elixir

# Sync local resources to production database
# Usage:
#   DATABASE_URL="prod_url" mix run sync_local_to_prod.exs

alias Sahajyog.Repo
alias Sahajyog.Resources.Resource

# Get all resources from local database
resources = Repo.all(Resource)

IO.puts("Found #{length(resources)} resources in local database")
IO.puts("\nResources to sync:")

Enum.each(resources, fn resource ->
  IO.puts("  - #{resource.title} (#{resource.resource_type})")
end)

IO.puts("\nThis will insert these resources into the production database.")
IO.puts("Files are already in R2, so they will be accessible.")
IO.write("Continue? (y/n): ")

case IO.gets("") |> String.trim() do
  "y" ->
    Enum.each(resources, fn resource ->
      # Create new resource in production with same attributes
      attrs = %{
        title: resource.title,
        description: resource.description,
        file_name: resource.file_name,
        file_size: resource.file_size,
        content_type: resource.content_type,
        r2_key: resource.r2_key,
        thumbnail_r2_key: resource.thumbnail_r2_key,
        level: resource.level,
        resource_type: resource.resource_type,
        language: resource.language,
        user_id: resource.user_id,
        downloads_count: 0
      }

      case Repo.insert(%Resource{} |> Resource.changeset(attrs)) do
        {:ok, _} ->
          IO.puts("✅ Synced: #{resource.title}")

        {:error, changeset} ->
          IO.puts("❌ Failed: #{resource.title}")
          IO.inspect(changeset.errors)
      end
    end)

    IO.puts("\n✅ Sync complete!")

  _ ->
    IO.puts("Cancelled.")
end
