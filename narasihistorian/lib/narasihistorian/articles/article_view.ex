defmodule Narasihistorian.Articles.ArticleView do
  use Ecto.Schema
  import Ecto.Changeset

  alias Narasihistorian.Articles.Article

  # ============================================================================
  # SCHEMA
  # ============================================================================

  schema "article_views" do
    field :ip_address, :string
    field :user_agent, :string
    field :viewed_at, :utc_datetime

    belongs_to :article, Article

    timestamps(updated_at: false)
  end

  # ============================================================================
  # ATTRIBUTE & VALIDATE
  # ============================================================================

  def changeset(article_view, attrs) do
    required_fields = [:article_id, :ip_address, :viewed_at]
    optional_fields = [:article_id, :ip_address, :user_agent, :viewed_at]

    article_view
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> foreign_key_constraint(:article_id)
  end
end
