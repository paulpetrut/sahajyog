defmodule Sahajyog.Repo.Migrations.SetDefaultEventLevel do
  use Ecto.Migration

  def up do
    execute "UPDATE events SET level = 'Level1' WHERE level IS NULL"
  end

  def down do
    # No rollback needed - Level1 is the correct default
    :ok
  end
end
