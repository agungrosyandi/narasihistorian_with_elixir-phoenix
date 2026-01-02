defmodule Narasihistorian.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :category_name, :string
    field :slug, :string

    has_many :articles, Narasihistorian.Articles.Article

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:category_name, :slug])
    |> validate_required([:category_name, :slug])
    |> unique_constraint(:slug)
    |> unique_constraint(:category_name)
  end
end
