defmodule Narasihistorian.Repo.Migrations.RemoveArticleDescriptionFromArticles do
  use Ecto.Migration

  def change do
    alter table(:articles) do
      remove :article_description
    end
  end
end
