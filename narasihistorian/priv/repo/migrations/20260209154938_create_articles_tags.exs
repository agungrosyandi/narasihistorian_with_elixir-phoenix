defmodule Narasihistorian.Repo.Migrations.CreateArticlesTags do
  use Ecto.Migration

  def change do
    create table(:articles_tags, primary_key: false) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
    end

    create index(:articles_tags, [:article_id])
    create index(:articles_tags, [:tag_id])
    create unique_index(:articles_tags, [:article_id, :tag_id])
  end
end
