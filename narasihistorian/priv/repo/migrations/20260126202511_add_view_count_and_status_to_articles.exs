defmodule Narasihistorian.Repo.Migrations.AddViewCountAndStatusToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :view_count, :integer, default: 0, null: false
      add :status, :string, default: "published", null: false
    end

    create index(:articles, [:status])
    create index(:articles, [:view_count])
  end
end
