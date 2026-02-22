defmodule Narasihistorian.Repo.Migrations.AddTrigramSearchIndexes do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    execute """
    CREATE INDEX articles_name_trgm_idx
    ON articles USING gin(article_name gin_trgm_ops)
    """

    execute """
    CREATE INDEX articles_content_trgm_idx
    ON articles USING gin(content gin_trgm_ops)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS articles_name_trgm_idx"
    execute "DROP INDEX IF EXISTS articles_content_trgm_idx"
  end
end
