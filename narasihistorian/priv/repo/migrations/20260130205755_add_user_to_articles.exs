defmodule Narasihistorian.Repo.Migrations.AddUserToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:articles, [:user_id])
  end
end
