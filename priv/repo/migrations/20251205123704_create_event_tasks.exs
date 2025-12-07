defmodule Sahajyog.Repo.Migrations.CreateEventTasks do
  use Ecto.Migration

  def change do
    create table(:event_tasks) do
      add :title, :string, null: false
      add :description, :text
      add :status, :string, null: false, default: "pending"
      add :due_date, :date
      add :estimated_expense, :decimal, precision: 10, scale: 2
      add :actual_expense, :decimal, precision: 10, scale: 2
      add :expense_notes, :text
      add :expense_receipt_url, :string
      add :position, :integer, default: 0
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :assigned_user_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:event_tasks, [:event_id])
    create index(:event_tasks, [:assigned_user_id])
    create index(:event_tasks, [:status])
    create index(:event_tasks, [:due_date])
  end
end
