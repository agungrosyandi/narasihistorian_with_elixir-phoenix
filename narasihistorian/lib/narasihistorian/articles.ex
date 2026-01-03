defmodule Narasihistorian.Articles do
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Repo

  import Ecto.Query

  @articles_per_page 6

  # list artikel

  def list_articles(page \\ 1) do
    Article
    |> order_by([a], desc: a.inserted_at)
    |> limit(^@articles_per_page)
    |> offset(^((page - 1) * @articles_per_page))
    |> Repo.all()
  end

  # filter

  def filter_articles(filter, page \\ 1) do
    Article
    |> search_by(filter["q"])
    |> filter_by_category(filter["category"])
    |> order_by([a], desc: a.inserted_at)
    |> paginate(page)
    |> preload(:category)
    |> Repo.all()
  end

  def count_articles(filter \\ %{}) do
    Article
    |> search_by(filter["q"])
    |> filter_by_category(filter["category"])
    |> Repo.aggregate(:count)
  end

  # search query

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    search_term = "%#{q}%"

    where(
      query,
      [a],
      ilike(a.article_name, ^search_term) or
        ilike(a.content, ^search_term)
    )
  end

  # filter by category

  defp filter_by_category(query, category_slug) when category_slug in ["", nil], do: query

  defp filter_by_category(query, category_slug) do
    query
    |> join(:inner, [a], c in assoc(a, :category))
    |> where([a, c], c.slug == ^category_slug)
  end

  # pagination

  defp paginate(query, page) do
    query
    |> limit(^@articles_per_page)
    |> offset(^((page - 1) * @articles_per_page))
  end

  # For better performance with 1000+ articles, add this migration:
  # CREATE INDEX articles_name_trgm_idx ON articles USING gin(article_name gin_trgm_ops);
  # CREATE INDEX articles_description_trgm_idx ON articles USING gin(article_description gin_trgm_ops);
  # (Requires PostgreSQL pg_trgm extension)

  # ---------------------------------------------------------

  def get_articles!(id) do
    Process.sleep(500)

    Repo.get!(Article, id)
    |> Repo.preload(:category)
  end

  def featured_article(articles) do
    Article
    |> where([r], r.id != ^articles.id)
    |> limit(3)
    |> Repo.all()
  end

  # DATABASE ON MEMORY + DEFSTRUCT ---------------------------------

  # def list_articles do
  #   [
  #     %Narasihistorian.Article{
  #       id: 1,
  #       article_name: "Ancient Rome",
  #       article_description:
  #         "Periode Roma yang paling dikenal dan sering dikutip oleh ahli sejarah Roma era Republik, karena menjadi dasar bagi pilar peradaban dunia barat",
  #       image: "/images/ancient-rome.jpg"
  #     },
  #     %Narasihistorian.Article{
  #       id: 2,
  #       article_name: "Middle Ages",
  #       article_description:
  #         "Periode Eropa setelah keruntuhan Romawi barat, yang dimana peran Gereja Katolik Roma menjadi sangat dominan secara ekonomi maupun politik",
  #       image: "/images/medieval-age.jpg"
  #     },
  #     %Narasihistorian.Article{
  #       id: 3,
  #       article_name: "Age of Discovery",
  #       article_description:
  #         "Era dimulainya penjelajahan samudera yang diinisiasi oleh Spanyol untuk mencari dunia baru dengan semangat Gospel, Glory, dan Gold",
  #       image: "/images/age-of-discovery.jpg"
  #     },
  #     %Narasihistorian.Article{
  #       id: 4,
  #       article_name: "Napoleonic War",
  #       article_description:
  #         "Peperangan besar yang melanda benua Eropa setelah revolusi Perancis, ketika naiknya Napoleon Bonaparte menjadi kaisar Perancis berambisi menguasai seluruh daratan Eropa",
  #       image: "/images/napoleonic-war.jpg"
  #     },
  #     %Narasihistorian.Article{
  #       id: 5,
  #       article_name: "World War 1/2",
  #       article_description:
  #         "Awal abad ke 20 ditandai dengan situasi peperangan besar yang dampaknya melanda seluruh dunia terutama di Eropa, akibat munculnya persaingan militer antar blok negara-negara besar Eropa",
  #       image: "/images/world-war-2.jpg"
  #     },
  #     %Narasihistorian.Article{
  #       id: 6,
  #       article_name: "Cold War",
  #       article_description:
  #         "Berakhirnya perang dunia ke 2 tidak membuat persaingan antar blok belum berakhir, karena melahirkan 2 kubu pemenang perang, yaitu blok barat pimpinan Amerika Serikat dan blok timur pimpinan Uni Soviet",
  #       image: "/images/cold-war.jpg"
  #     }
  #   ]
  # end
end

# defmodule Narasihistorian.Article do
#   defstruct [:id, :article_name, :article_description, :image]
# end
