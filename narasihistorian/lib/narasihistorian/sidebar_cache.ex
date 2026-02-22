defmodule Narasihistorian.SidebarCache do
  @ttl :timer.minutes(10)

  def get_recent_articles(limit \\ 6) do
    case Cachex.get(:sidebar_cache, {:recent_articles, limit}) do
      {:ok, nil} ->
        value = Narasihistorian.Articles.list_recent_articles(limit)
        Cachex.put(:sidebar_cache, {:recent_articles, limit}, value, ttl: @ttl)
        value

      {:ok, value} ->
        value
    end
  end

  def get_popular_articles(limit \\ 6) do
    case Cachex.get(:sidebar_cache, {:popular_articles, limit}) do
      {:ok, nil} ->
        value = Narasihistorian.Articles.list_popular_articles(limit)
        Cachex.put(:sidebar_cache, {:popular_articles, limit}, value, ttl: @ttl)
        value

      {:ok, value} ->
        value
    end
  end

  def invalidate do
    Cachex.clear(:sidebar_cache)
  end
end
