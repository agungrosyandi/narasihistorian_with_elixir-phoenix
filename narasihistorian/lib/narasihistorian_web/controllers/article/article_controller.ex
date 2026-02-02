defmodule NarasihistorianWeb.ArticleController do
  use NarasihistorianWeb, :controller

  alias Narasihistorian.Articles
  alias Narasihistorian.Categories
  alias Narasihistorian.Dashboard

  alias Narasihistorian.Comments
  alias Narasihistorian.Comments.Comment

  # ============================================================================
  # INDEX
  # ============================================================================

  def index(conn, params) do
    page = String.to_integer(params["page"] || "1")
    articles = Articles.filter_articles(params, page)
    total_articles = Articles.count_articles(params)
    total_pages = ceil(total_articles / 6)
    filter_by_categories = Categories.category_name_and_slugs()

    conn
    |> assign(:articles, articles)
    |> assign(:search_query, params["q"] || "")
    |> assign(:current_page, page)
    |> assign(:total_pages, total_pages)
    |> assign(:category_options, filter_by_categories)
    |> assign(:selected_category, params["category"] || "")
    |> render(:index)
  end

  # ============================================================================
  # SHOW
  # ============================================================================

  def show(conn, %{"id" => id}) do
    article = Articles.get_articles!(id)
    featured_articles = Articles.featured_article(article)
    changeset = Comments.change_comment(%Comment{})
    form_comment = Phoenix.Component.to_form(changeset, as: :comment)

    # Track unique view

    ip_address = get_client_ip(conn)
    user_agent = get_user_agent(conn)
    Dashboard.track_article_view(article.id, ip_address, user_agent)

    conn
    |> assign(:article, article)
    |> assign(:page_title, article.article_name)
    |> assign(:featured_articles, featured_articles)
    |> assign(:comments, article.comments)
    |> assign(:form, form_comment)
    |> render(:show)
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp get_client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip |> String.split(",") |> List.first() |> String.trim()

      [] ->
        conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [user_agent | _] -> user_agent
      [] -> nil
    end
  end
end
