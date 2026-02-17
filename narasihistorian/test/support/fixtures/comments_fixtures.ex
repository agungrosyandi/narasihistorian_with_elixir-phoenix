defmodule Narasihistorian.CommentsFixtures do
  import Narasihistorian.AccountsFixtures
  import Narasihistorian.ArticlesFixtures

  def comment_fixture(attrs \\ %{}) do
    user = attrs[:user] || user_fixture()
    article = attrs[:article] || article_fixture(%{}, user)

    {:ok, comment} =
      attrs
      |> Enum.into(%{
        comment: "some comment",
        article_id: article.id,
        user_id: user.id
      })
      |> Narasihistorian.Comments.create_comment()

    comment
  end
end
