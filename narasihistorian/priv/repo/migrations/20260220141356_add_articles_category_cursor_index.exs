defmodule Narasihistorian.Repo.Migrations.AddArticlesCategoryCursorIndex do
  use Ecto.Migration

  def up do
    create index(:articles, [:category_id, :inserted_at, :id],
             name: :articles_category_cursor_idx
           )
  end

  def down do
    drop index(:articles, [:category_id, :inserted_at, :id], name: :articles_category_cursor_idx)
  end
end
