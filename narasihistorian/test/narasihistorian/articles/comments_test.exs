defmodule Narasihistorian.Articles.CommentsTest do
  use Narasihistorian.DataCase, async: false

  alias Narasihistorian.Comments
  alias Narasihistorian.Comments.Comment

  import Narasihistorian.CommentsFixtures
  import Narasihistorian.AccountsFixtures
  import Narasihistorian.ArticlesFixtures

  # ============================================================================
  # list_comments/0
  # ============================================================================

  describe "list_comments/0" do
    test "returns empty list when no comments exist" do
      assert Comments.list_comments() == []
    end

    test "returns all comments" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      comment_fixture(%{article: article, user: user})
      comment_fixture(%{article: article, user: user})

      assert length(Comments.list_comments()) == 2
    end
  end

  # ============================================================================
  # list_comments_paginated/2
  # ============================================================================

  describe "list_comments_paginated/2" do
    test "returns comments for a specific article only" do
      user = user_fixture()
      article1 = article_fixture(%{}, user)
      article2 = article_fixture(%{}, user)

      comment_fixture(%{article: article1, user: user})
      comment_fixture(%{article: article2, user: user})

      result = Comments.list_comments_paginated(article1.id)
      assert length(result.comments) == 1
      assert hd(result.comments).article_id == article1.id
    end

    test "returns correct total_count" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      for _ <- 1..3, do: comment_fixture(%{article: article, user: user})

      result = Comments.list_comments_paginated(article.id)
      assert result.total_count == 3
    end

    test "has_more is true when more pages exist" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      for _ <- 1..6, do: comment_fixture(%{article: article, user: user})

      result = Comments.list_comments_paginated(article.id, per_page: 5)
      assert result.has_more == true
    end

    test "has_more is false on last page" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      for _ <- 1..3, do: comment_fixture(%{article: article, user: user})

      result = Comments.list_comments_paginated(article.id, per_page: 5)
      assert result.has_more == false
    end

    test "page 2 returns next set of comments" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      for _ <- 1..6, do: comment_fixture(%{article: article, user: user})

      page1 = Comments.list_comments_paginated(article.id, page: 1, per_page: 5)
      page2 = Comments.list_comments_paginated(article.id, page: 2, per_page: 5)

      page1_ids = MapSet.new(page1.comments, & &1.id)
      page2_ids = MapSet.new(page2.comments, & &1.id)

      assert MapSet.disjoint?(page1_ids, page2_ids)
    end

    test "comments have user preloaded" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment_fixture(%{article: article, user: user})

      result = Comments.list_comments_paginated(article.id)
      assert %Narasihistorian.Accounts.User{} = hd(result.comments).user
    end
  end

  # ============================================================================
  # get_comment!/1
  # ============================================================================

  describe "get_comment!/1" do
    test "returns comment by id" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      result = Comments.get_comment!(comment.id)
      assert result.id == comment.id
      assert result.comment == "some comment"
    end

    test "raises when comment not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Comments.get_comment!(999_999)
      end
    end
  end

  # ============================================================================
  # create_comment/1
  # ============================================================================

  describe "create_comment/1" do
    test "creates comment with valid attrs" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      attrs = %{
        comment: "great article!",
        article_id: article.id,
        user_id: user.id
      }

      assert {:ok, %Comment{} = comment} = Comments.create_comment(attrs)
      assert comment.comment == "great article!"
      assert comment.article_id == article.id
    end

    test "returns error when comment text is missing" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      attrs = %{article_id: article.id, user_id: user.id}
      assert {:error, changeset} = Comments.create_comment(attrs)
      assert %{comment: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error when comment exceeds 100 characters" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      attrs = %{
        comment: String.duplicate("a", 101),
        article_id: article.id,
        user_id: user.id
      }

      assert {:error, changeset} = Comments.create_comment(attrs)
      assert %{comment: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "returns error when article_id is missing" do
      user = user_fixture()

      attrs = %{comment: "great!", user_id: user.id}
      assert {:error, changeset} = Comments.create_comment(attrs)
      assert %{article_id: ["can't be blank"]} = errors_on(changeset)
    end
  end

  # ============================================================================
  # update_comment/2
  # ============================================================================

  describe "update_comment/2" do
    test "updates comment with valid attrs" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert {:ok, updated} = Comments.update_comment(comment, %{comment: "updated text"})
      assert updated.comment == "updated text"
    end

    test "returns error with invalid attrs" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert {:error, changeset} =
               Comments.update_comment(comment, %{comment: String.duplicate("a", 101)})

      assert %{comment: _} = errors_on(changeset)
    end
  end

  # ============================================================================
  # delete_comment/2
  # ============================================================================

  describe "delete_comment/2" do
    test "owner can delete their own comment" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert {:ok, _} = Comments.delete_comment(comment, user)
      assert_raise Ecto.NoResultsError, fn -> Comments.get_comment!(comment.id) end
    end

    test "admin can delete any comment" do
      user = user_fixture()
      admin = admin_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert {:ok, _} = Comments.delete_comment(comment, admin)
    end

    test "non-owner regular user cannot delete comment" do
      user = user_fixture()
      other_user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert {:error, :unauthorized} = Comments.delete_comment(comment, other_user)
    end
  end

  # ============================================================================
  # can_delete?/2
  # ============================================================================

  describe "can_delete?/2" do
    test "returns true when user is the comment owner" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert Comments.can_delete?(comment, user) == true
    end

    test "returns true when user is admin" do
      user = user_fixture()
      admin = admin_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert Comments.can_delete?(comment, admin) == true
    end

    test "returns false for non-owner regular user" do
      user = user_fixture()
      other = user_fixture()
      article = article_fixture(%{}, user)
      comment = comment_fixture(%{article: article, user: user})

      assert Comments.can_delete?(comment, other) == false
    end
  end
end
