defmodule Narasihistorian.Articles.ArticleView do
  use Ecto.Schema
  import Ecto.Changeset

  schema "article_views" do
    field :ip_address, :string
    field :user_agent, :string
    field :viewed_at, :utc_datetime

    belongs_to :article, Narasihistorian.Articles.Article

    timestamps(updated_at: false)
  end

  def changeset(article_view, attrs) do
    article_view
    |> cast(attrs, [:article_id, :ip_address, :user_agent, :viewed_at])
    |> validate_required([:article_id, :ip_address, :viewed_at])
    |> foreign_key_constraint(:article_id)
  end
end
