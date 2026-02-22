defmodule Narasihistorian.Repo.Migrations.AddSearchContentToArticles do
  use Ecto.Migration

  def up do
    alter table(:articles) do
      add :search_content, :text
    end

    # populate existing articles by stripping HTML
    execute """
    UPDATE articles
    SET search_content = regexp_replace(content, '<[^>]*>', ' ', 'g')
    """

    execute """
    CREATE INDEX articles_search_content_trgm_idx
    ON articles USING gin(search_content gin_trgm_ops)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS articles_search_content_trgm_idx"

    alter table(:articles) do
      remove :search_content
    end
  end
end
