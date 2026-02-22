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
  # SHOW
  # ============================================================================

  def show(conn, %{"id" => id}) do
    category = Categories.get_category!(id)
    page_title = category.category_name

    %{articles: articles, next_cursor: next_cursor} =
      Categories.list_articles_by_category(id, nil)

    total_articles = Categories.count_articles_by_category(id)

    conn
    |> assign(:page_title, page_title)
    |> assign(:category, category)
    |> assign(:articles, articles)
    |> assign(:next_cursor, next_cursor)
    |> assign(:total_articles, total_articles)
    |> render(:show)
  end

  # ============================================================================
  # MORE — HTML fragment appended by JS
  # ============================================================================

  def more(conn, %{"id" => id} = params) do
    cursor = params["cursor"]
    category = Categories.get_category!(id)

    %{articles: articles, next_cursor: next_cursor} =
      Categories.list_articles_by_category(id, cursor)

    conn
    |> assign(:category, category)
    |> assign(:articles, articles)
    |> assign(:next_cursor, next_cursor)
    |> render(:more)
  end
end
