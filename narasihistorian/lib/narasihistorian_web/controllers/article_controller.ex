defmodule NarasihistorianWeb.ArticleController do
  use NarasihistorianWeb, :controller

  alias Narasihistorian.Articles
  alias Narasihistorian.Categories

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

  def show(conn, %{"id" => id}) do
    article = Articles.get_articles!(id)

    conn
    |> assign(:article, article)
    |> assign(:page_title, article.article_name)
    |> assign(:featured_articles, Articles.featured_article(article))
    |> render(:show)
  end
end
