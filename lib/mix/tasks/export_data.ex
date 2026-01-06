defmodule Mix.Tasks.ExportData do
  @moduledoc """
  Export database data to a seeds file.

  Usage:
    mix export_data
  """
  use Mix.Task

  import Ecto.Query
  alias Sahajyog.Accounts.User
  alias Sahajyog.Content.Video
  alias Sahajyog.Progress.WatchedVideo
  alias Sahajyog.Repo

  @shortdoc "Export database data to priv/repo/production_seeds.exs"

  def run(_args) do
    Mix.Task.run("app.start")

    output_file = "priv/repo/production_seeds.exs"

    IO.puts("Exporting data from database...")

    content = """
    # Production data export
    # Generated on #{DateTime.utc_now()}
    # Run with: mix run priv/repo/production_seeds.exs

    import Ecto.Query
    alias Sahajyog.Repo
    alias Sahajyog.Accounts.User
    alias Sahajyog.Content.Video
    alias Sahajyog.Progress.WatchedVideo

    IO.puts("Starting data import...")

    # Import Users
    IO.puts("Importing users...")
    users_data = #{inspect(export_users(), pretty: true, limit: :infinity)}

    user_id_map = Enum.reduce(users_data, %{}, fn user_data, acc ->
      old_id = user_data.id
      user_data = Map.delete(user_data, :id)

      case Repo.get_by(User, email: user_data.email) do
        nil ->
          user = Repo.insert!(struct(User, user_data))
          IO.puts("  ✓ Created user: \#{user.email}")
          Map.put(acc, old_id, user.id)

        existing_user ->
          IO.puts("  ✓ User already exists: \#{existing_user.email}")
          Map.put(acc, old_id, existing_user.id)
      end
    end)

    # Import Videos
    IO.puts("Importing videos...")
    videos_data = #{inspect(export_videos(), pretty: true, limit: :infinity)}

    video_id_map = Enum.reduce(videos_data, %{}, fn video_data, acc ->
      old_id = video_data.id
      video_data = Map.delete(video_data, :id)

      case Repo.get_by(Video, title: video_data.title, url: video_data.url) do
        nil ->
          video = Repo.insert!(struct(Video, video_data))
          IO.puts("  ✓ Created video: \#{video.title}")
          Map.put(acc, old_id, video.id)

        existing_video ->
          IO.puts("  ✓ Video already exists: \#{existing_video.title}")
          Map.put(acc, old_id, existing_video.id)
      end
    end)

    # Import Watched Videos
    IO.puts("Importing watched videos...")
    watched_videos_data = #{inspect(export_watched_videos(), pretty: true, limit: :infinity)}

    Enum.each(watched_videos_data, fn watched_data ->
      new_user_id = user_id_map[watched_data.user_id]
      new_video_id = video_id_map[watched_data.video_id]

      if new_user_id && new_video_id do
        case Repo.get_by(WatchedVideo, user_id: new_user_id, video_id: new_video_id) do
          nil ->
            Repo.insert!(%WatchedVideo{
              user_id: new_user_id,
              video_id: new_video_id,
              watched_at: watched_data.watched_at,
              inserted_at: watched_data.inserted_at,
              updated_at: watched_data.updated_at
            })
            IO.puts("  ✓ Created watched video record")

          _existing ->
            IO.puts("  ✓ Watched video record already exists")
        end
      end
    end)

    IO.puts("Data import completed!")
    """

    File.write!(output_file, content)
    IO.puts("\n✓ Data exported to #{output_file}")
    IO.puts("\nTo import this data to production:")
    IO.puts("1. Commit and push this file to your repository")
    IO.puts("2. SSH into your Render instance or use Render shell")
    IO.puts("3. Run: /app/bin/sahajyog eval 'Code.eval_file(\"priv/repo/production_seeds.exs\")'")
  end

  defp export_users do
    User
    |> Repo.all()
    |> Enum.map(fn user ->
      %{
        id: user.id,
        email: user.email,
        hashed_password: user.hashed_password,
        confirmed_at: user.confirmed_at,
        role: user.role,
        inserted_at: user.inserted_at,
        updated_at: user.updated_at
      }
    end)
  end

  defp export_videos do
    Video
    |> order_by([v], v.step_number)
    |> Repo.all()
    |> Enum.map(fn video ->
      %{
        id: video.id,
        title: video.title,
        url: video.url,
        category: video.category,
        description: video.description,
        thumbnail_url: video.thumbnail_url,
        duration: video.duration,
        step_number: video.step_number,
        inserted_at: video.inserted_at,
        updated_at: video.updated_at
      }
    end)
  end

  defp export_watched_videos do
    WatchedVideo
    |> Repo.all()
    |> Enum.map(fn watched ->
      %{
        user_id: watched.user_id,
        video_id: watched.video_id,
        watched_at: watched.watched_at,
        inserted_at: watched.inserted_at,
        updated_at: watched.updated_at
      }
    end)
  end
end
