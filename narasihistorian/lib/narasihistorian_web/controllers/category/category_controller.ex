defmodule NarasihistorianWeb.CategoryController do
  use NarasihistorianWeb, :controller

  alias Narasihistorian.Categories

  # ============================================================================
  # INDEX
  # ============================================================================

  def index(conn, _params) do
    categories = Categories.list_categories()

    conn
    |> assign(:page_title, "Kategori")
    |> assign(:categories, categories)
    |> render(:index)
  end

  # ============================================================================
  # INDEX
  # ============================================================================

  def show(conn, %{"id" => id}) do
    categories = Categories.get_category_with_articles!(id)
    page_title = categories.category_name

    # Track unique view

    # ip_address = get_client_ip(conn)
    # user_agent = get_user_agent(conn)
    # Dashboard.track_article_view(article.id, ip_address, user_agent)

    conn
    |> assign(:page_title, page_title)
    |> assign(:categories, categories)
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
