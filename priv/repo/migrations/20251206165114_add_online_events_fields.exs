defmodule Sahajyog.Repo.Migrations.AddOnlineEventsFields do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :online_url, :string
    end

    alter table(:event_proposals) do
      add :online_url, :string
      add :start_time, :time
    end
  end
end
