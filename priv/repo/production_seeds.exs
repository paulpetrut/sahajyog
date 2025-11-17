# Production data export
# Generated on 2025-11-17 16:39:35.563023Z
# Run with: mix run priv/repo/production_seeds.exs

import Ecto.Query
alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Content.Video
alias Sahajyog.Progress.WatchedVideo

IO.puts("Starting data import...")

# Import Users
IO.puts("Importing users...")
users_data = [
  %{
    id: 2,
    role: "admin",
    email: "paulpetrut@yahoo.com",
    hashed_password: "$2b$12$mPhlbUxf9OCaPGcZ45oHAu7xy/.l3MeRoC4QE3y38Lel/8ZBQRxpq",
    confirmed_at: ~U[2025-11-15 12:57:53Z],
    inserted_at: ~U[2025-11-15 12:57:53Z],
    updated_at: ~U[2025-11-15 12:57:53Z]
  },
  %{
    id: 4,
    role: "regular",
    email: "user@test.com",
    hashed_password: "$2b$12$Gdqp/4FL679PKN8IPube1eUM79O5tu7jmzZV/Wc.zH.WX96cReVt2",
    confirmed_at: ~U[2025-11-15 16:38:58Z],
    inserted_at: ~U[2025-11-15 16:38:58Z],
    updated_at: ~U[2025-11-15 16:38:58Z]
  },
  %{
    id: 5,
    role: "admin",
    email: "admin@test.com",
    hashed_password: "$2b$12$g6hH9VwOGKw3qrTTELRy8ewlGw/te/hJ3J7Yp7POTejuDxiHmuI9K",
    confirmed_at: ~U[2025-11-15 16:41:48Z],
    inserted_at: ~U[2025-11-15 16:41:48Z],
    updated_at: ~U[2025-11-15 16:41:48Z]
  },
  %{
    id: 3,
    role: "manager",
    email: "manager@test.com",
    hashed_password: "$2b$12$4wdN2b.JKffgxbLyXHcSS.5QrBLrTO0ptJJUQy9nY0c5UnBtEKgu.",
    confirmed_at: ~U[2025-11-15 16:38:58Z],
    inserted_at: ~U[2025-11-15 16:38:58Z],
    updated_at: ~U[2025-11-15 18:15:53Z]
  },
  %{
    id: 6,
    role: "regular",
    email: "mipanet@yahoo.com",
    hashed_password: nil,
    confirmed_at: ~U[2025-11-15 18:50:11Z],
    inserted_at: ~U[2025-11-15 18:49:50Z],
    updated_at: ~U[2025-11-15 18:50:11Z]
  }
]

user_id_map = Enum.reduce(users_data, %{}, fn user_data, acc ->
  old_id = user_data.id
  user_data = Map.delete(user_data, :id)

  case Repo.get_by(User, email: user_data.email) do
    nil ->
      user = Repo.insert!(struct(User, user_data))
      IO.puts("  ✓ Created user: #{user.email}")
      Map.put(acc, old_id, user.id)

    existing_user ->
      IO.puts("  ✓ User already exists: #{existing_user.email}")
      Map.put(acc, old_id, existing_user.id)
  end
end)

# Import Videos
IO.puts("Importing videos...")
videos_data = [
  %{
    id: 9,
    description: nil,
    title: "Introduction to Sahaj Yoga",
    category: "Getting Started",
    url: "https://www.youtube.com/watch?v=D20SgK7dev0",
    inserted_at: ~U[2025-11-16 08:40:17Z],
    updated_at: ~U[2025-11-16 08:40:17Z],
    step_number: 1,
    thumbnail_url: "https://img.youtube.com/vi/D20SgK7dev0/maxresdefault.jpg",
    duration: "10:30"
  },
  %{
    id: 5,
    description: "Understanding the process of Kundalini awakening and its significance.",
    title: "Kundalini Awakening",
    category: "Advanced Topics",
    url: "https://www.youtube.com/watch?v=example2",
    inserted_at: ~U[2025-11-15 16:51:12Z],
    updated_at: ~U[2025-11-15 16:51:12Z],
    step_number: 1,
    thumbnail_url: nil,
    duration: "18:30"
  },
  %{
    id: 15,
    description: nil,
    title: "Inner Peace and Balance",
    category: "Excerpts",
    url: "https://www.youtube.com/watch?v=8jPQjjsBbIc",
    inserted_at: ~U[2025-11-16 08:40:17Z],
    updated_at: ~U[2025-11-16 08:40:17Z],
    step_number: 1,
    thumbnail_url: "https://img.youtube.com/vi/8jPQjjsBbIc/maxresdefault.jpg",
    duration: "7:30"
  },
  %{
    id: 20,
    description: nil,
    title: "Mozart All Day (10 Hours) 🎶 Complete Symphonies, Concertos & Masterpieces for Study & Relax",
    category: "Welcome",
    url: "https://www.youtube.com/watch?v=vKsYWRqLPqc",
    inserted_at: ~U[2025-11-17 09:30:52Z],
    updated_at: ~U[2025-11-17 09:30:52Z],
    step_number: 1,
    thumbnail_url: "https://i.ytimg.com/vi/vKsYWRqLPqc/hqdefault.jpg",
    duration: nil
  },
  %{
    id: 8,
    description: nil,
    title: "Microsoft keeps losing",
    category: "Excerpts",
    url: "https://www.youtube.com/watch?v=AyuMdNoL1Vs",
    inserted_at: ~U[2025-11-15 17:01:20Z],
    updated_at: ~U[2025-11-15 17:01:20Z],
    step_number: 2,
    thumbnail_url: "https://i.ytimg.com/vi/AyuMdNoL1Vs/hqdefault.jpg",
    duration: nil
  },
  %{
    id: 10,
    description: nil,
    title: "Meditation Basics",
    category: "Getting Started",
    url: "https://www.youtube.com/watch?v=QW9-6mKcJUk",
    inserted_at: ~U[2025-11-16 08:40:17Z],
    updated_at: ~U[2025-11-16 08:40:17Z],
    step_number: 2,
    thumbnail_url: "https://img.youtube.com/vi/QW9-6mKcJUk/maxresdefault.jpg",
    duration: "15:45"
  },
  %{
    id: 4,
    description: "Deep dive into the subtle system and the seven chakras.",
    title: "Understanding the Chakras",
    category: "Advanced Topics",
    url: "https://www.youtube.com/watch?v=example1",
    inserted_at: ~U[2025-11-15 16:51:12Z],
    updated_at: ~U[2025-11-15 16:51:12Z],
    step_number: 2,
    thumbnail_url: nil,
    duration: "25:00"
  },
  %{
    id: 12,
    description: nil,
    title: "Daily Practice Guide",
    category: "Advanced Topics",
    url: "https://www.youtube.com/watch?v=D_qMJiE7RpQ",
    inserted_at: ~U[2025-11-16 08:40:17Z],
    updated_at: ~U[2025-11-16 08:40:17Z],
    step_number: 3,
    thumbnail_url: "https://img.youtube.com/vi/D_qMJiE7RpQ/maxresdefault.jpg",
    duration: "12:20"
  },
  %{
    id: 13,
    description: nil,
    title: "Benefits of Meditation",
    category: "Excerpts",
    url: "https://www.youtube.com/watch?v=Jyy0ra2WcQQ",
    inserted_at: ~U[2025-11-16 08:40:17Z],
    updated_at: ~U[2025-11-16 08:40:17Z],
    step_number: 3,
    thumbnail_url: "https://img.youtube.com/vi/Jyy0ra2WcQQ/maxresdefault.jpg",
    duration: "8:45"
  },
  %{
    id: 2,
    description: "Experience the awakening of your inner energy through guided meditation.",
    title: "Self Realization Experience",
    category: "Getting Started",
    url: "https://www.youtube.com/watch?v=QW9-6mKcJUk",
    inserted_at: ~U[2025-11-15 16:51:12Z],
    updated_at: ~U[2025-11-15 16:51:12Z],
    step_number: 3,
    thumbnail_url: "https://img.youtube.com/vi/QW9-6mKcJUk/maxresdefault.jpg",
    duration: "20:15"
  },
  %{
    id: 19,
    description: nil,
    title: "50 Best of Bach | What Happens When You Listen to Bach Music Every Morning?",
    category: "Excerpts",
    url: "https://www.youtube.com/watch?v=d6V4j0pd7SA",
    inserted_at: ~U[2025-11-16 12:27:46Z],
    updated_at: ~U[2025-11-16 12:27:46Z],
    step_number: 4,
    thumbnail_url: "https://i.ytimg.com/vi/d6V4j0pd7SA/hqdefault.jpg",
    duration: nil
  }
]

video_id_map = Enum.reduce(videos_data, %{}, fn video_data, acc ->
  old_id = video_data.id
  video_data = Map.delete(video_data, :id)

  case Repo.get_by(Video, title: video_data.title, url: video_data.url) do
    nil ->
      video = Repo.insert!(struct(Video, video_data))
      IO.puts("  ✓ Created video: #{video.title}")
      Map.put(acc, old_id, video.id)

    existing_video ->
      IO.puts("  ✓ Video already exists: #{existing_video.title}")
      Map.put(acc, old_id, existing_video.id)
  end
end)

# Import Watched Videos
IO.puts("Importing watched videos...")
watched_videos_data = [
  %{
    user_id: 3,
    inserted_at: ~U[2025-11-15 18:25:44Z],
    updated_at: ~U[2025-11-15 18:25:44Z],
    video_id: 8,
    watched_at: ~U[2025-11-15 18:25:44Z]
  },
  %{
    user_id: 3,
    inserted_at: ~U[2025-11-15 18:27:16Z],
    updated_at: ~U[2025-11-15 18:27:16Z],
    video_id: 3,
    watched_at: ~U[2025-11-15 18:27:16Z]
  },
  %{
    user_id: 4,
    inserted_at: ~U[2025-11-15 18:30:25Z],
    updated_at: ~U[2025-11-15 18:30:25Z],
    video_id: 6,
    watched_at: ~U[2025-11-15 18:30:25Z]
  },
  %{
    user_id: 4,
    inserted_at: ~U[2025-11-15 18:31:08Z],
    updated_at: ~U[2025-11-15 18:31:08Z],
    video_id: 2,
    watched_at: ~U[2025-11-15 18:31:08Z]
  },
  %{
    user_id: 6,
    inserted_at: ~U[2025-11-15 18:52:02Z],
    updated_at: ~U[2025-11-15 18:52:02Z],
    video_id: 4,
    watched_at: ~U[2025-11-15 18:52:02Z]
  },
  %{
    user_id: 6,
    inserted_at: ~U[2025-11-15 18:52:07Z],
    updated_at: ~U[2025-11-15 18:52:07Z],
    video_id: 5,
    watched_at: ~U[2025-11-15 18:52:07Z]
  },
  %{
    user_id: 4,
    inserted_at: ~U[2025-11-16 08:45:36Z],
    updated_at: ~U[2025-11-16 08:45:36Z],
    video_id: 9,
    watched_at: ~U[2025-11-16 08:45:36Z]
  }
]

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
