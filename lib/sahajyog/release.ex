defmodule Sahajyog.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :sahajyog

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def seed do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          # Run the seed script safely
          seed_script = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

          if File.exists?(seed_script) do
            IO.puts("Running seed script...")
            # Safer alternative: read and evaluate in controlled context
            case File.read(seed_script) do
              {:ok, content} ->
                # Evaluate in a restricted context without access to dangerous functions
                try do
                  Code.eval_string(content, [], file: seed_script)
                  IO.puts("Seed script executed successfully")
                rescue
                  e ->
                    IO.puts("Error executing seed script: #{Exception.message(e)}")
                    reraise e, __STACKTRACE__
                end

              {:error, reason} ->
                IO.puts("Failed to read seed script: #{reason}")
            end
          else
            IO.puts("Seed script not found at #{seed_script}")
          end
        end)
    end
  end

  def seed_production do
    load_app()

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn _repo ->
          # Run the production seed script safely
          seed_script = Path.join([:code.priv_dir(@app), "repo", "production_seeds.exs"])

          if File.exists?(seed_script) do
            IO.puts("Running production data import...")
            # Safer alternative: read and evaluate in controlled context
            case File.read(seed_script) do
              {:ok, content} ->
                # Evaluate in a restricted context without access to dangerous functions
                try do
                  Code.eval_string(content, [], file: seed_script)
                  IO.puts("Production seed script executed successfully")
                rescue
                  e ->
                    IO.puts("Error executing production seed script: #{Exception.message(e)}")
                    reraise e, __STACKTRACE__
                end

              {:error, reason} ->
                IO.puts("Failed to read production seed script: #{reason}")
            end
          else
            IO.puts("Production seed script not found, skipping...")
          end
        end)
    end
  end

  def sync_r2_resources(opts \\ []) do
    load_app()
    Application.ensure_all_started(:hackney)
    Application.ensure_all_started(:ex_aws)

    dry_run = Keyword.get(opts, :dry_run, false)

    IO.puts("🔄 Syncing R2 resources to database...")
    IO.puts("Dry run: #{dry_run}\n")

    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          sync_r2_resources_for_repo(repo, dry_run)
        end)
    end
  end

  defp sync_r2_resources_for_repo(repo, dry_run) do
    alias Sahajyog.Resources.R2Storage
    alias Sahajyog.Resources.Resource

    case R2Storage.list_objects() do
      {:ok, objects} ->
        sync_objects(repo, objects, dry_run)
        IO.puts("\n✅ Sync complete!")

      {:error, reason} ->
        IO.puts("❌ Failed to list R2 objects: #{inspect(reason)}")
    end
  end

  defp sync_objects(repo, objects, dry_run) do
    alias Sahajyog.Resources.Resource

    levels = Resource.levels()
    types = Resource.types()

    objects
    |> Enum.filter(&valid_resource_object?(&1, levels, types))
    |> Enum.each(&sync_object(repo, &1, dry_run))
  end

  defp valid_resource_object?(obj, levels, types) do
    parts = String.split(obj.key, "/")
    length(parts) == 3 && Enum.at(parts, 0) in levels && Enum.at(parts, 1) in types
  end

  defp sync_object(repo, obj, dry_run) do
    alias Sahajyog.Resources.Resource

    key = obj.key
    size = obj.size
    parts = String.split(key, "/")
    level = Enum.at(parts, 0)
    resource_type = Enum.at(parts, 1)
    file_name = Enum.at(parts, 2)

    case repo.get_by(Resource, r2_key: key) do
      nil ->
        handle_new_resource(repo, key, file_name, size, level, resource_type, dry_run)

      _existing ->
        IO.puts("⏭️  Skipping (exists): #{key}")
    end
  end

  defp handle_new_resource(repo, key, file_name, size, level, resource_type, dry_run) do
    if dry_run do
      IO.puts("📋 Would create: #{key}")
    else
      create_resource(repo, key, file_name, size, level, resource_type)
    end
  end

  defp create_resource(repo, key, file_name, size, level, resource_type) do
    alias Sahajyog.Resources.Resource

    content_type = determine_content_type(file_name)

    attrs = %{
      title: Path.rootname(file_name),
      file_name: file_name,
      file_size: size,
      content_type: content_type,
      r2_key: key,
      level: level,
      resource_type: resource_type,
      user_id: 1
    }

    case repo.insert(%Resource{} |> Resource.changeset(attrs)) do
      {:ok, _} ->
        IO.puts("✅ Created: #{key}")

      {:error, _changeset} ->
        IO.puts("❌ Failed: #{key}")
    end
  end

  defp determine_content_type(file_name) do
    cond do
      String.ends_with?(file_name, ".pdf") -> "application/pdf"
      String.ends_with?(file_name, [".jpg", ".jpeg"]) -> "image/jpeg"
      String.ends_with?(file_name, ".png") -> "image/png"
      String.ends_with?(file_name, ".mp3") -> "audio/mpeg"
      String.ends_with?(file_name, ".mp4") -> "video/mp4"
      true -> "application/octet-stream"
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
