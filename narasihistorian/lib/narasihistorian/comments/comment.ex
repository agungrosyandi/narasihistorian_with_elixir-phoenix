defmodule Narasihistorian.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :comment, :string

    belongs_to :article, Narasihistorian.Articles.Article
    belongs_to :user, Narasihistorian.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:comment, :article_id, :user_id])
    |> validate_required([:comment, :article_id, :user_id])
    |> validate_length(:comment, max: 100)
    |> assoc_constraint(:article)
    |> assoc_constraint(:user)
  end
end
