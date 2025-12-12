defmodule Sahajyog.Repo.Migrations.UpdateRoleDefaultToUser do
  use Ecto.Migration

  @doc """
  Updates the database default for the role column from "regular" to "user"
  to match the simplified role model.
  """

  def up do
    alter table(:users) do
      modify :role, :string, default: "user", null: false
    end
  end

  def down do
    alter table(:users) do
      modify :role, :string, default: "regular", null: false
    end
  end
end
