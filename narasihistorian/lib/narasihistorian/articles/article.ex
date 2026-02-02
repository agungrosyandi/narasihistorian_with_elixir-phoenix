defmodule Narasihistorian.Articles.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :article_name, :string
    field :content, :string
    field :image, :string, default: "/images/ancient-rome.jpg"
    field :view_count, :integer, default: 0
    field :status, :string, default: "published"

    belongs_to :category, Narasihistorian.Categories.Category
    belongs_to :user, Narasihistorian.Accounts.User
    has_many :comments, Narasihistorian.Comments.Comment
    has_many :views, Narasihistorian.Articles.ArticleView

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:article_name, :image, :category_id, :content, :view_count, :status])
    |> normalize_quill_content()
    |> validate_required([:image])
    |> validate_required([:article_name], message: "Judul artikel wajib diisi")
    |> validate_required([:content], message: "konten wajib diisi")
    |> validate_length(:content, min: 10, message: "Konten minimal 10 karakter")
    |> validate_required([:category_id], message: "Kategori wajib diisi")
    |> validate_inclusion(:status, ["draft", "published"])
    |> assoc_constraint(:category)
    |> assoc_constraint(:user)
  end

  def creation_changeset(article, attrs, user) do
    article
    |> changeset(attrs)
    |> put_assoc(:user, user)
  end

  defp normalize_quill_content(changeset) do
    update_change(changeset, :content, fn content ->
      content = content || ""

      text =
        content
        |> String.replace(~r/<[^>]*>/, "")
        |> String.trim()

      if text == "" do
        ""
      else
        content
      end
    end)
  end
end
