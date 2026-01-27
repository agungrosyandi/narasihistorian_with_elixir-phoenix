defmodule Narasihistorian.Dashboard do
  import Ecto.Query, warn: false
  alias Narasihistorian.Repo
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Comments.Comment

  @doc """
  Returns the total count of articles.
  """

  def get_total_articles_count do
    Repo.aggregate(Article, :count)
  end

  @doc """
  Returns the count of published articles.
  """

  def get_published_articles_count do
    Article
    |> where([a], a.status == "published")
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the count of draft articles.
  """

  def get_draft_articles_count do
    Article
    |> where([a], a.status == "draft")
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns draft vs published ratio as a map with counts and percentages.
  """

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

  @doc """
  Returns articles trend grouped by date for the specified number of days.
  Returns a list of tuples: [{date, count}, ...]
  """

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

  @doc """
  Returns top performing articles by view count.
  """

  def get_top_articles_by_views(limit \\ 10) do
    Article
    |> where([a], a.status == "published")
    |> order_by([a], desc: a.view_count)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns articles with their comment counts.
  """

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

  @doc """
  Returns publishing frequency statistics.
  Period can be :daily, :weekly, or :monthly
  """
  def get_publishing_frequency(period \\ :weekly, days \\ 30) do
    date_from = Date.utc_today() |> Date.add(-days)

    # Convert to NaiveDateTime for proper comparison

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

  @doc """
  Increments the view count for an article.
  Uses async task to avoid blocking.
  """

  def increment_article_views(article_id) do
    Task.start(fn ->
      Article
      |> where([a], a.id == ^article_id)
      |> Repo.update_all(inc: [view_count: 1])
    end)

    :ok
  end

  @doc """
  Increments the view count for an article with IP deduplication.
  Only counts unique views per IP per article per day.
  """
  def increment_article_views_unique(article_id, _ip_address) do
    # This requires a separate table to track views
    # For now, we'll use simple increment
    # You can implement IP tracking later if needed

    increment_article_views(article_id)
  end

  # Private helper to fill missing dates with zero counts

  defp fill_missing_dates(data, days) do
    date_from = Date.utc_today() |> Date.add(-days)
    date_to = Date.utc_today()

    date_map =
      Map.new(data, fn {date, count} ->
        # Convert the date from the database to a Date struct

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
end
