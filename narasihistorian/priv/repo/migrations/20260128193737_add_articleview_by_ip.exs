defmodule Narasihistorian.Repo.Migrations.AddArticleviewByIp do
  use Ecto.Migration

  def change do
    create table(:article_views) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :ip_address, :string, null: false
      add :user_agent, :text
      add :viewed_at, :utc_datetime, null: false

      timestamps(updated_at: false)
    end

    # Regular indexes
    create index(:article_views, [:article_id])
    create index(:article_views, [:ip_address])
    create index(:article_views, [:viewed_at])
    create index(:article_views, [:article_id, :ip_address, :viewed_at])

    # Unique index with DATE() function using raw SQL
    execute(
      """
      CREATE UNIQUE INDEX unique_daily_view_per_ip
      ON article_views (article_id, ip_address, DATE(viewed_at))
      """,
      "DROP INDEX IF EXISTS unique_daily_view_per_ip"
    )
  end
end
