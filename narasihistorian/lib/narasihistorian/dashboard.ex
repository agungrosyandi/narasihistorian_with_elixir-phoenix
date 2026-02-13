defmodule Narasihistorian.Dashboard do
  alias Narasihistorian.Articles.ArticleView
  alias Narasihistorian.Repo
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Comments.Comment

  import Ecto.Query, warn: false

  # Cache TTL in milliseconds
  @cache_ttl :timer.seconds(10)

  # ============================================================================
  # PUBLIC API
  # ============================================================================

  def get_total_articles_count, do: Repo.aggregate(Article, :count)

  def get_published_articles_count do
    Article
    |> where([a], a.status == "published")
    |> Repo.aggregate(:count)
  end

  def get_draft_articles_count do
    Article
    |> where([a], a.status == "draft")
    |> Repo.aggregate(:count)
  end

  # Returns draft vs published ratio as a map with counts and percentages.

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_draft_vs_published_ratio do
    total = get_total_articles_count()
    published = get_published_articles_count()
    draft = get_draft_articles_count()

    published_percentage = if total > 0, do: Float.round(published / total * 100, 1), else: 0
    draft_percentage = if total > 0, do: Float.round(draft / total * 100, 1), else: 0

    %{
      total: total,
      published: published,
      draft: draft,
      published_percentage: published_percentage,
      draft_percentage: draft_percentage
    }
  end

  # get_draft_vs_published_ratio -- Cached version

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_draft_vs_published_ratio_cached do
    cache_get_or_compute("ratio", fn ->
      get_draft_vs_published_ratio()
    end)
  end

  # Returns articles trend grouped by date for the specified number of days.

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_articles_trend(days \\ 30) do
    date_from = Date.utc_today() |> Date.add(-days)

    datetime_from =
      date_from
      |> NaiveDateTime.new!(~T[00:00:00])

    Article
    |> where([a], a.inserted_at >= ^datetime_from)
    |> where([a], a.status == "published")
    |> group_by([a], fragment("DATE(?)", a.inserted_at))
    |> select([a], {fragment("DATE(?)", a.inserted_at), count(a.id)})
    |> order_by([a], asc: fragment("DATE(?)", a.inserted_at))
    |> Repo.all()
    |> fill_missing_dates(days)
  end

  # get_articles_trend Cached version

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_articles_trend_cached(days \\ 30) do
    cache_get_or_compute("trend:#{days}", fn ->
      get_articles_trend(days)
    end)
  end

  # Returns top performing articles by view count.

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_top_articles_by_views(limit \\ 10) do
    Article
    |> where([a], a.status == "published")
    |> order_by([a], desc: a.view_count)
    |> limit(^limit)
    |> Repo.all()
  end

  # get_top_articles_by_views Cached version

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_top_articles_by_views_cached(limit \\ 10) do
    cache_get_or_compute("top_articles:#{limit}", fn ->
      get_top_articles_by_views(limit)
    end)
  end

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  # Returns articles with their comment counts.

  def get_articles_with_comment_count(limit \\ 10) do
    Article
    |> where([a], a.status == "published")
    |> join(:left, [a], c in Comment, on: c.article_id == a.id)
    |> group_by([a], a.id)
    |> select([a, c], %{
      article: a,
      comment_count: count(c.id)
    })
    |> order_by([a, c], desc: count(c.id))
    |> limit(^limit)
    |> Repo.all()
  end

  # Cached version

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_articles_with_comment_count_cached(limit \\ 10) do
    cache_get_or_compute("comments:#{limit}", fn ->
      get_articles_with_comment_count(limit)
    end)
  end

  # Returns publishing frequency statistics.

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_publishing_frequency(period \\ :weekly, days \\ 30) do
    date_from = Date.utc_today() |> Date.add(-days)

    datetime_from = NaiveDateTime.new!(date_from, ~T[00:00:00])

    case period do
      :daily ->
        get_daily_frequency(datetime_from)

      :weekly ->
        get_weekly_frequency(datetime_from)

      :monthly ->
        get_monthly_frequency(datetime_from)
    end
  end

  # get_publishing_frequency Cached version

  # ============================================================================
  # CREATE CATEGORY
  # ============================================================================

  def get_publishing_frequency_cached(period \\ :daily, days \\ 30) do
    cache_get_or_compute("frequency:#{period}:#{days}", fn ->
      get_publishing_frequency(period, days)
    end)
  end

  @doc """
  Cleans up old article view records older than the specified number of days.
  """

  def cleanup_old_views(days_to_keep \\ 90) do
    cutoff_date = DateTime.utc_now() |> DateTime.add(-days_to_keep, :day)

    {count, _} =
      ArticleView
      |> where([v], v.viewed_at < ^cutoff_date)
      |> Repo.delete_all()

    require Logger

    Logger.info(
      "🧹 Cleaned up #{count} old article view records (older than #{days_to_keep} days)"
    )

    {:ok, count}
  end

  # ============================================================================
  # VIEW TRACKING & ANALYTICS - NEW FUNCTIONS
  # ============================================================================

  @doc """
  Tracks a unique view for an article by IP address.
  Only counts one view per IP per article per day.
  Runs asynchronously to not block the request.
  """

  def track_article_view(article_id, ip_address, user_agent) do
    Task.start(fn ->
      now = DateTime.utc_now()

      try do
        result =
          %ArticleView{}
          |> ArticleView.changeset(%{
            article_id: article_id,
            ip_address: ip_address,
            user_agent: user_agent,
            viewed_at: now
          })
          |> Repo.insert()

        # Sync view_count when a NEW unique view is recorded

        case result do
          {:ok, _view} ->
            Article
            |> where([a], a.id == ^article_id)
            |> Repo.update_all(inc: [view_count: 1])

          {:error, _} ->
            :ok
        end

        Cachex.del(:dashboard_cache, "top_articles:10")
        Cachex.del(:dashboard_cache, "article_views:#{article_id}")
      rescue
        _error -> :ok
      end
    end)
  end

  @doc """
  Get total unique views for an article (all time).
  """

  def get_article_total_views(article_id) do
    cache_get_or_compute("article_views:#{article_id}", fn ->
      from(v in ArticleView,
        where: v.article_id == ^article_id,
        select: count(v.id)
      )
      |> Repo.one()
    end)
  end

  @doc """
  Get unique views for an article today.
  """

  def get_article_today_views(article_id) do
    today = Date.utc_today()

    from(v in ArticleView,
      where: v.article_id == ^article_id,
      where: fragment("DATE(?)", v.viewed_at) == ^today,
      select: count(v.id)
    )
    |> Repo.one()
  end

  @doc """
  Get unique views for an article in the last 7 days.
  """

  def get_article_week_views(article_id) do
    seven_days_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    from(v in ArticleView,
      where: v.article_id == ^article_id,
      where: v.viewed_at >= ^seven_days_ago,
      select: count(v.id)
    )
    |> Repo.one()
  end

  @doc """
  Get unique daily views for an article over the specified number of days.
  Returns a list of {date, count} tuples.
  """

  def get_article_daily_views(article_id, days \\ 30) do
    start_date = Date.utc_today() |> Date.add(-days)

    from(v in ArticleView,
      where: v.article_id == ^article_id,
      where: fragment("DATE(?)", v.viewed_at) >= ^start_date,
      group_by: fragment("DATE(?)", v.viewed_at),
      select: {fragment("DATE(?)", v.viewed_at), count(v.id)},
      order_by: [desc: fragment("DATE(?)", v.viewed_at)]
    )
    |> Repo.all()
  end

  @doc """
  Get top articles by unique views (from ArticleView table).
  """

  def get_top_articles_by_unique_views(limit \\ 10) do
    from(a in Article,
      left_join: v in ArticleView,
      on: v.article_id == a.id,
      where: a.status == "published",
      group_by: a.id,
      select: %{
        article: a,
        view_count: count(v.id)
      },
      order_by: [desc: count(v.id)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Get views trend for all articles over time.
  """

  def get_views_trend(days \\ 30) do
    date_from = Date.utc_today() |> Date.add(-days)

    from(v in ArticleView,
      where: fragment("DATE(?)", v.viewed_at) >= ^date_from,
      group_by: fragment("DATE(?)", v.viewed_at),
      select: {fragment("DATE(?)", v.viewed_at), count(v.id)},
      order_by: [asc: fragment("DATE(?)", v.viewed_at)]
    )
    |> Repo.all()
    |> fill_missing_dates(days)
  end

  # ============================================================================
  # VIEW TRACKING & NOTIFICATIONS (LEGACY - kept for backward compatibility)
  # ============================================================================

  @doc """
  DEPRECATED: Use track_article_view/3 instead.
  This increments the view_count column directly (old method).
  """

  def increment_article_views(article_id) do
    Task.start(fn ->
      Article
      |> where([a], a.id == ^article_id)
      |> Repo.update_all(inc: [view_count: 1])

      Cachex.del(:dashboard_cache, "top_articles:10")

      broadcast_dashboard_update(:article_viewed)
    end)

    :ok
  end

  @doc """
  DEPRECATED: Use track_article_view/3 instead.
  """

  def increment_article_views_unique(article_id, ip_address) do
    track_article_view(article_id, ip_address, nil)
  end

  # Clears all cache and broadcasts update.
  # ARTICLE

  def notify_article_created do
    clear_dashboard_cache()
    broadcast_dashboard_update(:article_created)
  end

  def notify_article_status_changed do
    clear_dashboard_cache()
    broadcast_dashboard_update(:article_status_changed)
  end

  def notify_article_deleted do
    clear_dashboard_cache()
    broadcast_dashboard_update(:article_deleted)
  end

  # COMMENT

  def notify_comment_created do
    Cachex.del(:dashboard_cache, "comments:10")
    broadcast_dashboard_update(:comment_created)
  end

  # ============================================================================
  # PRIVATE HELPERS
  # ============================================================================

  # Private helper to fill missing dates with zero counts

  defp get_daily_frequency(datetime_from) do
    Article
    |> where([a], a.inserted_at >= ^datetime_from)
    |> where([a], a.status == "published")
    |> group_by([a], fragment("DATE(?)", a.inserted_at))
    |> select([a], %{
      period: fragment("DATE(?)", a.inserted_at),
      count: count(a.id)
    })
    |> order_by([a], asc: fragment("DATE(?)", a.inserted_at))
    |> Repo.all()
  end

  defp get_weekly_frequency(datetime_from) do
    Article
    |> where([a], a.inserted_at >= ^datetime_from)
    |> where([a], a.status == "published")
    |> group_by([a], fragment("DATE_TRUNC('week', ?)", a.inserted_at))
    |> select([a], %{
      period: fragment("DATE_TRUNC('week', ?)", a.inserted_at),
      count: count(a.id)
    })
    |> order_by([a], asc: fragment("DATE_TRUNC('week', ?)", a.inserted_at))
    |> Repo.all()
  end

  defp get_monthly_frequency(datetime_from) do
    Article
    |> where([a], a.inserted_at >= ^datetime_from)
    |> where([a], a.status == "published")
    |> group_by([a], fragment("DATE_TRUNC('month', ?)", a.inserted_at))
    |> select([a], %{
      period: fragment("DATE_TRUNC('month', ?)", a.inserted_at),
      count: count(a.id)
    })
    |> order_by([a], asc: fragment("DATE_TRUNC('month', ?)", a.inserted_at))
    |> Repo.all()
  end

  defp fill_missing_dates(data, days) do
    date_from = Date.utc_today() |> Date.add(-days)
    date_to = Date.utc_today()

    date_map =
      Map.new(data, fn {date, count} ->
        parsed_date =
          case date do
            %Date{} = d -> d
            datetime when is_struct(datetime, DateTime) -> DateTime.to_date(datetime)
            naive when is_struct(naive, NaiveDateTime) -> NaiveDateTime.to_date(naive)
            string when is_binary(string) -> Date.from_iso8601!(string)
          end

        {parsed_date, count}
      end)

    date_from
    |> Date.range(date_to)
    |> Enum.map(fn date ->
      count = Map.get(date_map, date, 0)
      {date, count}
    end)
  end

  # Cache helper using Cachex

  defp cache_get_or_compute(key, fun) do
    case Cachex.get(:dashboard_cache, key) do
      {:ok, nil} ->
        # Cache miss
        value = fun.()
        Cachex.put(:dashboard_cache, key, value, ttl: @cache_ttl)
        value

      {:ok, value} ->
        # Cache hit
        value

      {:error, _reason} ->
        # Cache error
        fun.()
    end
  end

  # Clear all dashboard cache entries

  defp clear_dashboard_cache, do: Cachex.clear(:dashboard_cache)

  # Broadcast dashboard update via PubSub

  defp broadcast_dashboard_update(event) do
    Phoenix.PubSub.broadcast(
      Narasihistorian.PubSub,
      "dashboard:updates",
      {:metrics_updated, event}
    )
  end
end
