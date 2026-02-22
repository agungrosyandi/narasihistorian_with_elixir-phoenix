defmodule NarasihistorianWeb.ArticleController do
  use NarasihistorianWeb, :controller

  alias Narasihistorian.Articles
  alias Narasihistorian.Categories
  alias Narasihistorian.Dashboard
  alias Narasihistorian.Comments
  alias Narasihistorian.Comments.Comment
  alias Narasihistorian.Tags

  alias Narasihistorian.SidebarCache

  @take_articles 6
  @take_comments 1
  @comments_per_page 5

  # ============================================================================
  # INDEX — first page
  # ============================================================================

  def index(conn, params) do
    %{articles: articles, next_cursor: next_cursor} =
      Articles.filter_articles(params, nil)

    filter_by_categories = Categories.category_name_and_slugs()

    recent_articles = SidebarCache.get_recent_articles(@take_articles)
    popular_articles = SidebarCache.get_popular_articles(@take_articles)

    conn
    |> assign(:articles, articles)
    |> assign(:search_query, params["q"] || "")
    |> assign(:selected_category, params["category"] || "")
    |> assign(:category_options, filter_by_categories)
    |> assign(:next_cursor, next_cursor)
    |> assign(:recent_articles, recent_articles)
    |> assign(:popular_articles, popular_articles)
    |> render(:index)
  end

  # ============================================================================
  # MORE — HTML fragment appended by JS
  # ============================================================================

  def more(conn, params) do
    cursor = params["cursor"]

    %{articles: articles, next_cursor: next_cursor} =
      Articles.filter_articles(params, cursor)

    conn
    |> assign(:articles, articles)
    |> assign(:next_cursor, next_cursor)
    |> assign(:search_query, params["q"] || "")
    |> assign(:selected_category, params["category"] || "")
    |> render(:more)
  end

  # ============================================================================
  # SHOW
  # ============================================================================

  def show(conn, %{"id" => id}) do
    # ========================================
    # ARTICLES
    # ========================================

    article = Articles.get_articles!(id)
    page_title = article.article_name

    # ========================================
    # COMMENTS
    # ========================================

    changeset = Comments.change_comment(%Comment{})
    form_comment = Phoenix.Component.to_form(changeset, as: :comment)

    # ========================================
    # FEATURED ARTICLES
    # ========================================

    featured_articles = Articles.featured_article(article)

    # ========================================
    # cursor based pagination for comment
    # ========================================

    %{comments: comments, total_count: total_count, has_more: has_more} =
      Comments.list_comments_paginated(article.id,
        page: @take_comments,
        per_page: @comments_per_page
      )

    # ===================
    # IP VIEWS
    # ===================

    ip_address = get_client_ip(conn)
    user_agent = get_user_agent(conn)
    Dashboard.track_article_view(article.id, ip_address, user_agent)

    # ========================================
    # RENDER
    # ========================================

    conn
    |> assign(:article, article)
    |> assign(:page_title, page_title)
    |> assign(:featured_articles, featured_articles)
    |> assign(:comments, comments)
    |> assign(:comments_total, total_count)
    |> assign(:comments_has_more, has_more)
    |> assign(:comments_next_page, 2)
    |> assign(:form, form_comment)
    |> render(:show)
  end

  # ========================================
  # COMMENT
  # ========================================

  def comments_more(conn, %{"id" => id} = params) do
    page = params["page"] |> String.to_integer()
    article = Articles.get_articles!(id)

    %{comments: comments, has_more: has_more} =
      Comments.list_comments_paginated(id, page: page, per_page: @comments_per_page)

    conn
    |> assign(:comments, comments)
    |> assign(:article, article)
    |> assign(:has_more, has_more)
    |> assign(:next_page, page + 1)
    |> render(:comments_more)
  end

  # ============================================================================
  # TAG
  # ============================================================================

  def by_tag(conn, %{"tag_slug" => tag_slug} = _params) do
    case Tags.get_tag_by_slug(tag_slug) do
      nil ->
        conn
        |> put_flash(:error, "Tag tidak ditemukan")
        |> redirect(to: ~p"/articles")

      tag ->
        %{articles: articles, next_cursor: next_cursor} =
          Articles.get_articles_by_tag(tag.id, nil)

        conn
        |> assign(:articles, articles)
        |> assign(:tag, tag)
        |> assign(:next_cursor, next_cursor)
        |> render(:by_tag)
    end
  end

  def by_tag_more(conn, %{"tag_slug" => tag_slug} = params) do
    case Tags.get_tag_by_slug(tag_slug) do
      nil ->
        conn
        |> put_resp_content_type("text/html")
        |> send_resp(404, "")

      tag ->
        cursor = params["cursor"]

        %{articles: articles, next_cursor: next_cursor} =
          Articles.get_articles_by_tag(tag.id, cursor)

        conn
        |> assign(:articles, articles)
        |> assign(:tag, tag)
        |> assign(:next_cursor, next_cursor)
        |> render(:by_tag_more)
    end
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp get_client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip |> String.split(",") |> List.first() |> String.trim()
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      [] -> nil
    end
  end
end
