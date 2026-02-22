defmodule Narasihistorian.Articles do
  alias Narasihistorian.Comments.Comment
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Repo
  alias Narasihistorian.Tags

  import Ecto.Query

  @articles_per_page 6

  # ============================================================================
  # filter articles (all, search + category)
  # ============================================================================

  def filter_articles(filter, cursor_param \\ nil) do
    decoded = decode_cursor(cursor_param)
    limit = @articles_per_page

    base =
      Article
      |> search_by(filter["q"])
      |> filter_by_category(filter["category"])
      |> order_by([a], desc: a.inserted_at, desc: a.id)
      |> limit(^(limit + 1))
      |> preload([:category, :user])

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

    build_page(query, limit)
  end

  # ============================================================================
  # RECENT ARTICLES — for homepage swiper (latest 8 by inserted_at)
  # ============================================================================

  def list_recent_articles(limit \\ 8) do
    Article
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> preload([:category, :user])
    |> Repo.all()
  end

  # ============================================================================
  # POPULAR ARTICLES — for homepage swiper (top by view_count)
  # ============================================================================

  def list_popular_articles(limit \\ 6) do
    Article
    |> where([a], not is_nil(a.image))
    |> order_by([a], desc: a.view_count, desc: a.inserted_at)
    |> limit(^limit)
    |> preload([:category, :user])
    |> Repo.all()
  end

  # ============================================================================
  # get single article
  # ============================================================================

  def get_articles!(id) do
    Article
    |> where([a], a.id == ^id)
    |> preload([
      :category,
      :user,
      :tags,
      comments:
        ^from(c in Comment,
          order_by: [desc: c.inserted_at],
          preload: [:user]
        )
    ])
    |> Repo.one!()
  end

  # ============================================================================
  # RELATED ARTICLE
  # ============================================================================

  def featured_article(article) do
    related_by_tags = Tags.get_related_articles_by_tags(article.id, 3)

    case length(related_by_tags) do
      0 ->
        Article
        |> where([a], a.id != ^article.id and a.category_id == ^article.category_id)
        |> order_by(desc: :inserted_at)
        |> limit(3)
        |> preload([:category, :user, :tags])
        |> Repo.all()

      count when count < 3 ->
        needed = 3 - count

        fallback =
          Article
          |> where([a], a.id != ^article.id)
          |> where([a], a.id not in ^Enum.map(related_by_tags, & &1.id))
          |> order_by(desc: :inserted_at)
          |> limit(^needed)
          |> preload([:category, :user, :tags])
          |> Repo.all()

        related_by_tags ++ fallback

      _ ->
        related_by_tags
    end
  end

  # ============================================================================
  # articles by tag (cursor-based)
  # ============================================================================

  def get_articles_by_tag(tag_id, cursor_param \\ nil) do
    decoded = decode_cursor(cursor_param)
    limit = @articles_per_page

    base =
      from a in Article,
        join: at in "articles_tags",
        on: at.article_id == a.id,
        where: at.tag_id == ^tag_id,
        order_by: [desc: a.inserted_at, desc: a.id],
        limit: ^(limit + 1),
        preload: [:category, :user, :tags]

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

    build_page(query, limit)
  end

  # ============================================================================
  # tags
  # ============================================================================

  def get_article_with_tags(id) do
    Article
    |> Repo.get(id)
    |> Repo.preload(:tags)
  end

  # ============================================================================
  # Cursor helpers
  # ============================================================================

  defp encode_cursor(%{inserted_at: inserted_at, id: id}) do
    "#{DateTime.to_iso8601(inserted_at)}__#{id}"
    |> Base.url_encode64(padding: false)
  end

  defp decode_cursor(nil), do: nil

  defp decode_cursor(cursor) do
    with {:ok, decoded} <- Base.url_decode64(cursor, padding: false),
         [iso_time, id_str] <- String.split(decoded, "__"),
         {:ok, inserted_at, _} <- DateTime.from_iso8601(iso_time),
         {id, ""} <- Integer.parse(id_str) do
      {inserted_at, id}
    else
      _ -> nil
    end
  end

  defp build_page(query, limit) do
    articles = Repo.all(query)

    {has_next, articles} =
      if length(articles) > limit do
        {true, Enum.take(articles, limit)}
      else
        {false, articles}
      end

    next_cursor =
      if has_next do
        articles |> List.last() |> encode_cursor()
      end

    %{articles: articles, next_cursor: next_cursor}
  end

  # ============================================================================
  # PRIVATE HELPER SEARCH QUERY
  # ============================================================================

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    search_term = "%#{q}%"

    where(
      query,
      [a],
      ilike(a.article_name, ^search_term) or
        ilike(a.search_content, ^search_term)
    )
  end

  # ============================================================================
  # PRIVATE HELPER FILTER BY CATEGORY
  # ============================================================================

  defp filter_by_category(query, category_slug) when category_slug in ["", nil], do: query

  defp filter_by_category(query, category_slug) do
    query
    |> join(:inner, [a], c in assoc(a, :category))
    |> where([a, c], c.slug == ^category_slug)
  end
end
