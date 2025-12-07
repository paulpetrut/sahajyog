defmodule Sahajyog.Repo.Migrations.AddIsOnlineFlag do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :is_online, :boolean, default: false, null: false
    end

    alter table(:event_proposals) do
      add :is_online, :boolean, default: false, null: false
    end
  end
end
