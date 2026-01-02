defmodule Narasihistorian.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :article_name, :string
    field :article_description, :string
    field :image, :string, default: "/images/ancient-rome.jpg"

    belongs_to :category, Narasihistorian.Categories.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:article_name, :article_description, :image, :category_id])
    |> validate_required([:image])
    |> validate_required([:article_name], message: "Judul artikel wajib diisi")
    |> validate_required([:article_description], message: "Deskripsi wajib diisi")
    |> validate_length(:article_description,
      min: 10,
      message: "Deskripsi minimal %{count} karakter"
    )
    |> validate_required([:category_id], message: "Kategori wajib diisi")
    |> assoc_constraint(:category)
  end
end
