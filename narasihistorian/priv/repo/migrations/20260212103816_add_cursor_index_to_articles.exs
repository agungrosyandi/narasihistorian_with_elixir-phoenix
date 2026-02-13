defmodule Narasihistorian.Repo.Migrations.AddCursorIndexToArticles do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS articles_cursor_idx ON articles (inserted_at DESC, id DESC)"
  end

  def down do
    execute "DROP INDEX CONCURRENTLY IF EXISTS articles_cursor_idx"
  end
end
