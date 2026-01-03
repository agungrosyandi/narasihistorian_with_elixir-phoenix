defmodule Narasihistorian.Admin do
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Repo

  import Ecto.Query

  # LIST ALL ARTICLE

  def list_article do
    Article
    |> Repo.all()
  end

  # FILTER ADMIN ARTICLE WITH PAGINATION

  def filter_articles(filter, opts \\ []) do
    page = String.to_integer(filter["page"] || "1")
    per_page = opts[:per_page] || 10

    Article
    |> search_by(filter["q"])
    |> sort(filter["sort_by"])
    |> paginate(page, per_page)
  end

  # SEARCH BY QUERY

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    :timer.sleep(1000)

    search_term = "%#{q}%"

    from a in query,
      where:
        ilike(a.article_name, ^search_term) or
          ilike(a.content, ^search_term)
  end

  # FILTER BY SORT

  defp sort(query, "inserted_at_asc") do
    order_by(query, desc: :inserted_at)
  end

  defp sort(query, "inserted_at_desc") do
    order_by(query, asc: :inserted_at)
  end

  defp sort(query, "article_name_desc") do
    order_by(query, desc: :article_name)
  end

  defp sort(query, "article_name_asc") do
    order_by(query, asc: :article_name)
  end

  defp sort(query, _) do
    order_by(query, :id)
  end

  # PAGINATION HELPER

  defp paginate(query, page, per_page) do
    offset = (page - 1) * per_page

    results =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    total_count = Repo.aggregate(query, :count, :id)
    total_pages = ceil(total_count / per_page)

    %{
      entries: results,
      page: page,
      per_page: per_page,
      total_count: total_count,
      total_pages: total_pages
    }
  end

  # CREATE ARTICLE

  def create_article(attrs \\ %{}) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
  end

  # VALIDATE CHANGESET AND FORM

  def change_article(%Article{} = article, attrs \\ %{}) do
    Article.changeset(article, attrs)
  end

  # GET ARTICLE BY ID

  def get_article!(id) do
    Repo.get!(Article, id)
  end

  # UPDATE RAFFLE

  def update_article(%Article{} = article, attrs) do
    article
    |> Article.changeset(attrs)
    |> Repo.update()
  end

  # DELETE RAFFLE

  def delete_article(%Article{} = article) do
    Repo.delete(article)
  end

  # PAGINATION
end

# -------------------------------------------------------------------
