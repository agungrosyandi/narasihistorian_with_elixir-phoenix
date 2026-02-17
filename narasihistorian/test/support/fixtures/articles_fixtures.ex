# test/support/fixtures/articles_fixtures.ex
defmodule Narasihistorian.ArticlesFixtures do
  import Narasihistorian.AccountsFixtures
  import Narasihistorian.CategoriesFixtures

  def article_fixture(attrs \\ %{}, user \\ nil) do
    user = user || user_fixture()
    category = category_fixture(%{}, user)

    attrs =
      attrs
      |> Enum.into(%{
        "article_name" => "article #{System.unique_integer([:positive])}",
        "content" => "some content for testing",
        "category_id" => attrs[:category_id] || attrs["category_id"] || category.id
      })

    {:ok, article} = Narasihistorian.Admin.create_article(attrs, user)
    article
  end
end
