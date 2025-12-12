defmodule Sahajyog.Repo.Migrations.ConvertRolesToSimplifiedModel do
  use Ecto.Migration

  @doc """
  Migration to convert the role system from three roles (admin, manager, regular)
  to two roles (admin, user).

  - "regular" users are converted to "user"
  - "manager" users are converted to "user"
  - "admin" users remain unchanged
  """

  def up do
    execute("UPDATE users SET role = 'user' WHERE role = 'regular'")
    execute("UPDATE users SET role = 'user' WHERE role = 'manager'")
  end

  def down do
    # Note: We cannot perfectly reverse this migration since we don't know
    # which "user" roles were originally "regular" vs "manager".
    # Default to converting all "user" roles back to "regular".
    execute("UPDATE users SET role = 'regular' WHERE role = 'user'")
  end
end
