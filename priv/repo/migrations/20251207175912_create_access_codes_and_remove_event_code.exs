defmodule Sahajyog.Repo.Migrations.CreateAccessCodesAndRemoveEventCode do
  use Ecto.Migration

  def change do
    create table(:access_codes) do
      add :code, :string, null: false
      add :usage_count, :integer, default: 0
      add :max_uses, :integer
      add :event_id, references(:events, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:access_codes, [:code])
    create index(:access_codes, [:event_id])

    alter table(:events) do
      remove :upgrade_code
    end
  end
end
