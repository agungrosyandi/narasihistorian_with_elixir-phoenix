# defmodule NarasihistorianWeb.Api.ArticleController do
#   use NarasihistorianWeb, :controller

#   alias Narasihistorian.Articles

#   def index(conn, _params) do
#     articles = Articles.list_articles()

#     render(conn, :index, articles: articles)
#   end

#   def show(conn, %{"id" => id}) do
#     article = Articles.get_articles!(id)

#     render(conn, :show, article: article)
#   end
# end
