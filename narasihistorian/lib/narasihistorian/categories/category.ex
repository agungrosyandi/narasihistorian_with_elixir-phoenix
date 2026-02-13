defmodule Narasihistorian.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias Narasihistorian.Accounts.User
  alias Narasihistorian.Articles.Article

  # ============================================================================
  # SCHEMA
  # ============================================================================

  schema "categories" do
    field :category_name, :string
    field :slug, :string
    field :description, :string
    field :image_category, :string, default: "/images/ancient-rome.jpg"

    belongs_to :user, User
    has_many :articles, Article

    timestamps(type: :utc_datetime)
  end

  # ============================================================================
  # ATTRIBUTE & VALIDATOR
  # ============================================================================

  @doc false
  def changeset(category, attrs) do
    required_fields = [:category_name]
    optional_fields = [:slug, :user_id, :description, :image_category]

    category
    |> cast(attrs, required_fields ++ optional_fields)
    |> validate_required(required_fields)
    |> generate_slug()
    |> unique_constraint(:slug)
    |> unique_constraint(:category_name)
    |> assoc_constraint(:user)
  end

  def creation_changeset(category, attrs, user) do
    category
    |> changeset(attrs)
    |> put_assoc(:user, user)
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp generate_slug(changeset) do
    case get_change(changeset, :category_name) do
      nil -> changeset
      name -> put_change(changeset, :slug, Slug.slugify(name))
    end
  end
end
