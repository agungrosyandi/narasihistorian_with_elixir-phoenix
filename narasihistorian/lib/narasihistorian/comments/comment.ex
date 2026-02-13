defmodule Narasihistorian.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Accounts.User

  # ============================================================================
  # SCHEMA
  # ============================================================================

  schema "comments" do
    field :comment, :string

    belongs_to :article, Article
    belongs_to :user, User

    timestamps(type: :utc_datetime)
  end

  # ============================================================================
  # ATTRIBUTE & VALIDATOR
  # ============================================================================

  @doc false
  def changeset(comment, attrs) do
    required_fields = [:comment, :article_id, :user_id]

    comment
    |> cast(attrs, required_fields)
    |> validate_required(required_fields)
    |> validate_length(:comment, max: 100)
    |> assoc_constraint(:article)
    |> assoc_constraint(:user)
  end
end
