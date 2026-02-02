defmodule Narasihistorian.Repo.Migrations.AddUserToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :user_id, references(:users, on_delete: :nilify_all)
    end

    create index(:categories, [:user_id])
  end
end
