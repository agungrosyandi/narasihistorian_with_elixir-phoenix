defmodule Narasihistorian.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias Narasihistorian.Categories.Policy
  alias Narasihistorian.Repo

  alias Narasihistorian.Categories.Category
  alias Narasihistorian.Uploader

  alias Narasihistorian.Articles.Article

  # ============================================================================
  # LIST CATEGORY
  # ============================================================================

  def list_categories(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 10)
    offset = (page - 1) * per_page

    Category
    |> order_by([c], c.category_name)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  # ============================================================================
  # LIST ARTICLES BY CATEGORY (cursor-based pagination)
  # ============================================================================

  @articles_per_page 9

  def list_articles_by_category(category_id, cursor_param \\ nil) do
    decoded = decode_article_cursor(cursor_param)
    limit = @articles_per_page

    base =
      from a in Article,
        where: a.category_id == ^category_id,
        order_by: [desc: a.inserted_at, desc: a.id],
        limit: ^(limit + 1),
        preload: [:category, :user]

    query =
      if decoded do
        {cursor_time, cursor_id} = decoded

        from a in base,
          where:
            a.inserted_at < ^cursor_time or
              (a.inserted_at == ^cursor_time and a.id < ^cursor_id)
      else
        base
      end

    build_article_page(query, limit)
  end

  # ============================================================================
  # COUNT ARTICLES BY CATEGORY
  # ============================================================================

  def count_articles_by_category(category_id) do
    from(a in Article,
      where: a.category_id == ^category_id,
      select: count(a.id)
    )
    |> Repo.one()
  end

  # ============================================================================
  # GET CATEGORY
  # ============================================================================

  def get_category!(id), do: Repo.get!(Category, id)

  # ============================================================================
  # CATEGORY BY NAME AND ID
  # ============================================================================

  def category_name_and_ids do
    query =
      from c in Category,
        order_by: :category_name,
        select: {c.category_name, c.id}

    Repo.all(query)
  end

  def category_name_and_slugs do
    query =
      from c in Category,
        order_by: :category_name,
        select: {c.category_name, c.slug}

    Repo.all(query)
  end

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def create_category(attrs, user) do
    %Category{}
    |> Category.creation_changeset(attrs, user)
    |> Repo.insert()
  end

  # ============================================================================
  # UPDATE CATEGORY
  # ============================================================================

  def update_category(%Category{} = category, attrs, current_user) do
    if Policy.can_edit?(current_user, category) do
      category
      |> Category.changeset(attrs)
      |> Repo.update()
    else
      {:error, :unauthorized}
    end
  end

  # ============================================================================
  # DELETE CATEGORY
  # ============================================================================

  def delete_category(%Category{} = category) do
    category = Repo.preload(category, :articles)

    case category.articles do
      [] ->
        case Repo.delete(category) do
          {:ok, deleted_category} ->
            if deleted_category.image_category do
              delete_category_image(deleted_category.image_category)
            end

            {:ok, deleted_category}

          {:error, changeset} ->
            {:error, changeset}
        end

      _articles ->
        {:error, :has_articles}
    end
  end

  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # ============================================================================
  # Private helper to delete image from R2
  # ============================================================================

  defp delete_category_image(image_url) do
    case Uploader.extract_key(image_url) do
      nil ->
        :ok

      key ->
        # Use Task.start to avoid blocking

        Task.start(fn -> Uploader.delete_file(key) end)
        :ok
    end
  end

  # ============================================================================
  # PRIVATE — cursor helpers (mirrors articles.ex pattern)
  # ============================================================================

  defp encode_article_cursor(%{inserted_at: inserted_at, id: id}) do
    "#{DateTime.to_iso8601(inserted_at)}__#{id}"
    |> Base.url_encode64(padding: false)
  end

  defp decode_article_cursor(nil), do: nil

  defp decode_article_cursor(cursor) do
    with {:ok, decoded} <- Base.url_decode64(cursor, padding: false),
         [iso_time, id_str] <- String.split(decoded, "__"),
         {:ok, inserted_at, _} <- DateTime.from_iso8601(iso_time),
         {id, ""} <- Integer.parse(id_str) do
      {inserted_at, id}
    else
      _ -> nil
    end
  end

  defp build_article_page(query, limit) do
    articles = Repo.all(query)

    {has_next, articles} =
      if length(articles) > limit do
        {true, Enum.take(articles, limit)}
      else
        {false, articles}
      end

    next_cursor =
      if has_next do
        articles |> List.last() |> encode_article_cursor()
      end

    %{articles: articles, next_cursor: next_cursor}
  end
end
