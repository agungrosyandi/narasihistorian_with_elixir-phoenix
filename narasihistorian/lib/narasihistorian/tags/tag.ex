defmodule Narasihistorian.Tags.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  alias Narasihistorian.Articles.Article

  # ============================================================================
  # SCHEMA
  # ============================================================================

  schema "tags" do
    field :name, :string
    field :slug, :string

    many_to_many :articles, Article,
      join_through: "articles_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  # ============================================================================
  # ATTRIBUTE & VALIDATE
  # ============================================================================

  def changeset(tag, attrs) do
    required_fields = [:name]
    optional_fields = [:slug]

    tag
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> generate_slug()
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil -> changeset
      name -> put_change(changeset, :slug, Slug.slugify(name))
    end
  end
end
