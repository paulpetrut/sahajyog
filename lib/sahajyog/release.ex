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
          # Run the seed script
          seed_script = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

          if File.exists?(seed_script) do
            IO.puts("Running seed script...")
            Code.eval_file(seed_script)
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
          # Run the production seed script
          seed_script = Path.join([:code.priv_dir(@app), "repo", "production_seeds.exs"])

          if File.exists?(seed_script) do
            IO.puts("Running production data import...")
            Code.eval_file(seed_script)
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

    alias Sahajyog.Repo
    alias Sahajyog.Resources.Resource
    alias Sahajyog.Resources.R2Storage

    case R2Storage.list_objects() do
      {:ok, objects} ->
        levels = Resource.levels()
        types = Resource.types()

        objects
        |> Enum.filter(fn obj ->
          parts = String.split(obj.key, "/")
          length(parts) == 3 && Enum.at(parts, 0) in levels && Enum.at(parts, 1) in types
        end)
        |> Enum.each(fn obj ->
          key = obj.key
          size = obj.size
          parts = String.split(key, "/")
          level = Enum.at(parts, 0)
          resource_type = Enum.at(parts, 1)
          file_name = Enum.at(parts, 2)

          # Check if already exists
          existing = Repo.get_by(Resource, r2_key: key)

          if existing do
            IO.puts("⏭️  Skipping (exists): #{key}")
          else
            if dry_run do
              IO.puts("📋 Would create: #{key}")
            else
              # Determine content type
              content_type =
                cond do
                  String.ends_with?(file_name, ".pdf") -> "application/pdf"
                  String.ends_with?(file_name, [".jpg", ".jpeg"]) -> "image/jpeg"
                  String.ends_with?(file_name, ".png") -> "image/png"
                  String.ends_with?(file_name, ".mp3") -> "audio/mpeg"
                  String.ends_with?(file_name, ".mp4") -> "video/mp4"
                  true -> "application/octet-stream"
                end

              # Create resource
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

              case Repo.insert(%Resource{} |> Resource.changeset(attrs)) do
                {:ok, _} ->
                  IO.puts("✅ Created: #{key}")

                {:error, changeset} ->
                  IO.puts("❌ Failed: #{key}")
                  IO.inspect(changeset.errors)
              end
            end
          end
        end)

        IO.puts("\n✅ Sync complete!")

      {:error, reason} ->
        IO.puts("❌ Failed to list R2 objects: #{inspect(reason)}")
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
