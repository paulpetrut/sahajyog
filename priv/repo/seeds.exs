# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Sahajyog.Repo.insert!(%Sahajyog.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Sahajyog.Repo
alias Sahajyog.Accounts.User

# Create default admin user
admin_attrs = %{
  email: "paulpetrut@yahoo.com",
  password: "admin123admin",
  role: "admin"
}

case Repo.get_by(User, email: admin_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(admin_attrs, validate_unique: false)
    |> User.password_changeset(admin_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "admin")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created admin user: #{admin_attrs.email}")

  _user ->
    IO.puts("✓ Admin user already exists: #{admin_attrs.email}")
end

# Create test manager user
manager_attrs = %{
  email: "manager@test.com",
  password: "manager123456",
  role: "manager"
}

case Repo.get_by(User, email: manager_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(manager_attrs, validate_unique: false)
    |> User.password_changeset(manager_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "manager")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created manager user: #{manager_attrs.email}")

  _user ->
    IO.puts("✓ Manager user already exists: #{manager_attrs.email}")
end

# Create test regular user
user_attrs = %{
  email: "user@test.com",
  password: "user123456789",
  role: "regular"
}

case Repo.get_by(User, email: user_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(user_attrs, validate_unique: false)
    |> User.password_changeset(user_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "regular")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created regular user: #{user_attrs.email}")

  _user ->
    IO.puts("✓ Regular user already exists: #{user_attrs.email}")
end

# Create test admin user
test_admin_attrs = %{
  email: "admin@test.com",
  password: "admin123admin",
  role: "admin"
}

case Repo.get_by(User, email: test_admin_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(test_admin_attrs, validate_unique: false)
    |> User.password_changeset(test_admin_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "admin")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created test admin user: #{test_admin_attrs.email}")

  _user ->
    IO.puts("✓ Test admin user already exists: #{test_admin_attrs.email}")
end

# Create sample videos from /steps page
alias Sahajyog.Content.Video

sample_videos = [
  %{
    step_number: 1,
    title: "Introduction to Sahaj Yoga",
    url: "https://www.youtube.com/watch?v=D20SgK7dev0",
    category: "Getting Started",
    thumbnail_url: "https://img.youtube.com/vi/D20SgK7dev0/maxresdefault.jpg",
    duration: "10:30"
  },
  %{
    step_number: 2,
    title: "Meditation Basics",
    url: "https://www.youtube.com/watch?v=QW9-6mKcJUk",
    category: "Getting Started",
    thumbnail_url: "https://img.youtube.com/vi/QW9-6mKcJUk/maxresdefault.jpg",
    duration: "15:45"
  },
  %{
    step_number: 3,
    title: "Understanding Chakras",
    url: "https://www.youtube.com/watch?v=6nkx3yZ471A",
    category: "Advanced Topics",
    thumbnail_url: "https://img.youtube.com/vi/6nkx3yZ471A/maxresdefault.jpg",
    duration: "20:15"
  },
  %{
    step_number: 4,
    title: "Daily Practice Guide",
    url: "https://www.youtube.com/watch?v=D_qMJiE7RpQ",
    category: "Advanced Topics",
    thumbnail_url: "https://img.youtube.com/vi/D_qMJiE7RpQ/maxresdefault.jpg",
    duration: "12:20"
  },
  %{
    step_number: 5,
    title: "Kundalini Awakening",
    url: "https://www.youtube.com/watch?v=yPYZpwSpKmA",
    category: "Advanced Topics",
    thumbnail_url: "https://img.youtube.com/vi/yPYZpwSpKmA/maxresdefault.jpg",
    duration: "18:30"
  },
  %{
    step_number: 6,
    title: "Benefits of Meditation",
    url: "https://www.youtube.com/watch?v=Jyy0ra2WcQQ",
    category: "Excerpts",
    thumbnail_url: "https://img.youtube.com/vi/Jyy0ra2WcQQ/maxresdefault.jpg",
    duration: "8:45"
  },
  %{
    step_number: 7,
    title: "Achieving Balance",
    url: "https://www.youtube.com/watch?v=TYLZG9tv0Yw",
    category: "Excerpts",
    thumbnail_url: "https://img.youtube.com/vi/TYLZG9tv0Yw/maxresdefault.jpg",
    duration: "6:30"
  },
  %{
    step_number: 8,
    title: "Inner Peace and Balance",
    url: "https://www.youtube.com/watch?v=8jPQjjsBbIc",
    category: "Excerpts",
    thumbnail_url: "https://img.youtube.com/vi/8jPQjjsBbIc/maxresdefault.jpg",
    duration: "7:30"
  }
]

Enum.each(sample_videos, fn video_attrs ->
  case Repo.get_by(Video, title: video_attrs.title) do
    nil ->
      %Video{}
      |> Video.changeset(video_attrs)
      |> Repo.insert!()

      IO.puts("✓ Created video: #{video_attrs.title}")

    _video ->
      IO.puts("✓ Video already exists: #{video_attrs.title}")
  end
end)
