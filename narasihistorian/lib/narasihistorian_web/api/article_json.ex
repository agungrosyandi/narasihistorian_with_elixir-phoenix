defmodule NarasihistorianWeb.Api.ArticleJSON do
  # ==================================
  # get all
  # ==================================

  def index(%{articles: articles}) do
    %{articles: for(article <- articles, do: data(article))}
  end

  # ==================================
  # get by id
  # ==================================

  def show(%{article: article}) do
    %{article: data(article)}
  end

  # ==================================
  # private helper
  # ==================================

  defp data(article) do
    %{
      id: article.id,
      article_name: article.article_name,
      content: HtmlSanitizeEx.basic_html(article.content),
      image: article.image,
      category_id: article.category_id
    }
  end
end
