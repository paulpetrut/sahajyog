defmodule Sahajyog.Repo.Migrations.AddEventInvitationMaterials do
  use Ecto.Migration

  def change do
    create table(:event_invitation_materials) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :filename, :string, null: false
      add :original_filename, :string, null: false
      add :file_type, :string, null: false
      add :file_size, :bigint, null: false
      add :r2_key, :string, null: false
      add :uploaded_at, :utc_datetime, null: false

      timestamps()
    end

    create index(:event_invitation_materials, [:event_id])
    create unique_index(:event_invitation_materials, [:r2_key])
  end
end
