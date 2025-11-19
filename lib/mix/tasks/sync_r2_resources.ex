defmodule Mix.Tasks.SyncR2Resources do
  @moduledoc """
  Syncs existing R2 files to the database.

  This task scans your R2 bucket and creates database records for files
  that match the Level/Type structure (Level1/Photos, Level2/Books, etc).

  Usage:
      mix sync_r2_resources

  Options:
      --dry-run    Show what would be synced without making changes
  """

  use Mix.Task
  import Ecto.Query
  alias Sahajyog.Repo
  alias Sahajyog.Resources
  alias Sahajyog.Resources.Resource
  alias Sahajyog.Resources.R2Storage

  @shortdoc "Syncs existing R2 files to database"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    dry_run = "--dry-run" in args

    if dry_run do
      Mix.shell().info("🔍 DRY RUN MODE - No changes will be made\n")
    end

    Mix.shell().info("📦 Scanning R2 bucket for resources...")

    case R2Storage.list_objects() do
      {:ok, objects} ->
        sync_objects(objects, dry_run)

      {:error, reason} ->
        Mix.shell().error("❌ Failed to list R2 objects: #{inspect(reason)}")
    end
  end

  defp sync_objects(objects, dry_run) do
    levels = Resource.levels()
    types = Resource.types()

    objects
    |> Enum.filter(fn obj ->
      # Filter for files in Level/Type structure
      key = obj.key

      Enum.any?(levels, fn level ->
        Enum.any?(types, fn type ->
          String.starts_with?(key, "#{level}/#{type}/")
        end)
      end)
    end)
    |> Enum.each(fn obj ->
      sync_object(obj, dry_run)
    end)

    Mix.shell().info("\n✅ Sync complete!")
  end

  defp sync_object(obj, dry_run) do
    key = obj.key
    size = obj.size

    # Parse key: Level1/Photos/filename.jpg
    case String.split(key, "/", parts: 3) do
      [level, resource_type, filename] ->
        # Check if already exists
        existing =
          Repo.one(from r in Resource, where: r.r2_key == ^key, select: r.id)

        if existing do
          Mix.shell().info("⏭️  Skipping (exists): #{key}")
        else
          if dry_run do
            Mix.shell().info("➕ Would add: #{key}")
          else
            create_resource(key, level, resource_type, filename, size)
          end
        end

      _ ->
        Mix.shell().info("⚠️  Skipping (invalid path): #{key}")
    end
  end

  defp create_resource(key, level, resource_type, filename, size) do
    # Clean filename for title
    title =
      filename
      |> String.replace(~r/^\w{8}-/, "")
      |> Path.rootname()
      |> String.replace(~r/[_-]/, " ")
      |> String.trim()

    content_type = MIME.from_path(filename)

    attrs = %{
      title: title,
      file_name: filename,
      file_size: size,
      content_type: content_type,
      r2_key: key,
      level: level,
      resource_type: resource_type
    }

    case Resources.create_resource(attrs) do
      {:ok, _resource} ->
        Mix.shell().info("✅ Added: #{key}")

      {:error, changeset} ->
        Mix.shell().error("❌ Failed to add #{key}: #{inspect(changeset.errors)}")
    end
  end
end
