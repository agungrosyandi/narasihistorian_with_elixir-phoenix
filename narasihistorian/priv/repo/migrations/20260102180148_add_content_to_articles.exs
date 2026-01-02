defmodule Narasihistorian.Repo.Migrations.AddContentToArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      add :content, :text
    end
  end
end
