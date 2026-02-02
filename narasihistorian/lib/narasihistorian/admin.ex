defmodule Narasihistorian.Admin do
  alias Narasihistorian.Dashboard
  alias Narasihistorian.Articles.Article
  alias Narasihistorian.Articles.Policy
  alias Narasihistorian.Repo
  alias Narasihistorian.Uploader

  import Ecto.Query

  # ============================================================================
  # GET & FILTER
  # ============================================================================

  def list_article do
    Article
    |> preload(:user)
    |> Repo.all()
  end

  def filter_articles(filter, opts \\ [], current_user) do
    page = String.to_integer(filter["page"] || "1")
    per_page = opts[:per_page] || 10

    Article
    |> filter_by_user_permission(current_user)
    |> search_by(filter["q"])
    |> sort(filter["sort_by"])
    |> preload(:user)
    |> paginate(page, per_page)
  end

  def change_article(%Article{} = article, attrs \\ %{}), do: Article.changeset(article, attrs)

  def get_article!(id) when is_binary(id), do: get_article!(String.to_integer(id))

  def get_article!(id) when is_integer(id) do
    Article
    |> preload(:user)
    |> Repo.get!(id)
  end

  # ============================================================================
  # CRUD
  # ============================================================================

  # CREATE ARTICLE -- real time features WEBSOCKET

  def create_article(attrs \\ %{}, user) do
    %Article{}
    |> Article.creation_changeset(attrs, user)
    |> Repo.insert()
    |> case do
      {:ok, _article} = result ->
        Dashboard.notify_article_created()
        result

      error ->
        error
    end
  end

  # UPDATE ARTICLE -- real time features WEBSOCKET

  def update_article(%Article{} = article, attrs, current_user) do
    if Policy.can_edit?(current_user, article) do
      article
      |> Article.changeset(attrs)
      |> Repo.update()
      |> case do
        {:ok, _updated_article} = result ->
          if Map.has_key?(attrs, "status") || Map.has_key?(attrs, :status) do
            Dashboard.notify_article_status_changed()
          end

          result

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  # DELETE ARTICLE -- real time features to dashboard + (with cloud storage cleanup)

  def delete_article(%Article{} = article, current_user) do
    if Policy.can_delete?(current_user, article) do
      if article.image, do: delete_image_from_r2(article.image)

      Repo.delete(article)
      |> case do
        {:ok, _deleted_article} = result ->
          Dashboard.notify_article_deleted()
          result

        error ->
          error
      end
    else
      {:error, :unauthorized}
    end
  end

  # REMOVE IMAGE FROM ARTICLE (keep article, just remove image)

  def remove_article_image(%Article{} = article) do
    if article.image, do: delete_image_from_r2(article.image)

    article
    |> Ecto.Changeset.change(%{image: nil})
    |> Repo.update()
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp filter_by_user_permission(query, user) do
    if Policy.can_list_all?(user) do
      query
    else
      where(query, [a], a.user_id == ^user.id)
    end
  end

  # Delete image from R2

  defp delete_image_from_r2(image_url) when is_binary(image_url) do
    case Uploader.extract_key(image_url) do
      nil ->
        :ok

      key ->
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

  # search by query

  defp search_by(query, q) when q in ["", nil], do: query

  defp search_by(query, q) do
    :timer.sleep(1000)

    search_term = "%#{q}%"

    from a in query,
      where:
        ilike(a.article_name, ^search_term) or
          ilike(a.content, ^search_term)
  end

  # filter by sort

  defp sort(query, "author_asc") do
    query
    |> join(:left, [a], u in assoc(a, :user))
    |> order_by([a, u], asc: u.username)
  end

  defp sort(query, "author_desc") do
    query
    |> join(:left, [a], u in assoc(a, :user))
    |> order_by([a, u], desc: u.username)
  end

  defp sort(query, "inserted_at_asc"), do: order_by(query, desc: :inserted_at)

  defp sort(query, "inserted_at_desc"), do: order_by(query, asc: :inserted_at)

  defp sort(query, "article_name_desc"), do: order_by(query, desc: :article_name)

  defp sort(query, "article_name_asc"), do: order_by(query, asc: :article_name)

  defp sort(query, _), do: order_by(query, :id)

  # pagination helper

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
end
