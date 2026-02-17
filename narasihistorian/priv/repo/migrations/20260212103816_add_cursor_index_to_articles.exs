defmodule Narasihistorian.Repo.Migrations.AddCursorIndexToArticles do
  use Ecto.Migration

  # ← allows CONCURRENTLY
  @disable_ddl_transaction true
  # ← required alongside the above
  @disable_migration_lock true

  def up do
    execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS articles_cursor_idx ON articles (inserted_at DESC, id DESC)"
  end

  def down do
    execute "DROP INDEX CONCURRENTLY IF EXISTS articles_cursor_idx"
  end
end
