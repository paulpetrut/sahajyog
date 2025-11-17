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

import Ecto.Query

alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Content.Video

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

# Note: Sample videos are now imported via production_seeds.exs
# This seeds file only creates default users for development/testing

IO.puts("✓ Basic seeds completed. Run production seeds for video data.")
