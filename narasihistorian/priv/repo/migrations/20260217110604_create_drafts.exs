defmodule Narasihistorian.Repo.Migrations.CreateDrafts do
  use Ecto.Migration

  def change do
    create table(:drafts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :draft_type, :string, null: false
      add :action, :string, null: false
      add :ref_id, :integer, null: true
      add :data, :map, null: false
      add :status, :string, default: "pending", null: false

      timestamps()
    end

    create index(:drafts, [:user_id])
    create index(:drafts, [:draft_type])
    create index(:drafts, [:status])

    create unique_index(:drafts, [:user_id, :draft_type, :action, :ref_id],
             name: :drafts_user_type_action_ref_unique_index
           )
  end
end
