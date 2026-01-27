defmodule Narasihistorian.Admin do
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Repo
  alias Narasihistorian.Uploader

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

  # UPDATE ARTICLE

  def update_article(%Article{} = article, attrs) do
    article
    |> Article.changeset(attrs)
    |> Repo.update()
  end

  # DELETE ARTICLE (with cloud storage cleanup)

  @doc """
  Deletes an article and its associated image from R2 cloud storage.

  This function will:
  1. Delete the image from Cloudflare R2 (if exists)
  2. Delete the article from database

  The R2 deletion happens asynchronously to avoid blocking the request.
  """
  def delete_article(%Article{} = article) do
    # Delete image from R2 first (if exists)

    if article.image do
      delete_image_from_r2(article.image)
    end

    # Then delete from database

    Repo.delete(article)
  end

  # REMOVE IMAGE FROM ARTICLE (keep article, just remove image)

  @doc """
  Removes image from article (sets to nil) and deletes from R2.

  This is useful when you want to remove the image but keep the article.
  The article's other fields remain unchanged.
  """
  def remove_article_image(%Article{} = article) do
    # Delete from R2

    if article.image do
      delete_image_from_r2(article.image)
    end

    # Update database to remove image

    article
    |> Ecto.Changeset.change(%{image: nil})
    |> Repo.update()
  end

  # PRIVATE HELPER: Delete image from R2

  defp delete_image_from_r2(image_url) when is_binary(image_url) do
    case Uploader.extract_key(image_url) do
      nil ->
        :ok

      key ->
        # Run deletion in background to not block the request

        Task.start(fn ->
          case Uploader.delete_file(key) do
            {:ok, :deleted} ->
              require Logger
              Logger.info("Successfully deleted image from R2: #{key}")

            {:error, reason} ->
              require Logger
              Logger.warning("Failed to delete image from R2: #{key}, reason: #{inspect(reason)}")
          end
        end)

        :ok
    end
  end

  defp delete_image_from_r2(_), do: :ok
end

# -------------------------------------------------------------------
