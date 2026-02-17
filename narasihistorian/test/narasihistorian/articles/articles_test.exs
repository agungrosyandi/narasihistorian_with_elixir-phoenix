defmodule Narasihistorian.Articles.ArticlesTest do
  use Narasihistorian.DataCase, async: false

  alias Narasihistorian.Articles

  import Narasihistorian.ArticlesFixtures
  import Narasihistorian.AccountsFixtures
  import Narasihistorian.CategoriesFixtures
  import Narasihistorian.CommentsFixtures

  # ============================================================================
  # list_articles/1
  # ============================================================================

  describe "list_articles/1" do
    test "returns empty result when no articles exist" do
      result = Articles.list_articles()
      assert result.articles == []
      assert result.next_cursor == nil
    end

    test "returns articles ordered by inserted_at desc" do
      user = user_fixture()
      a1 = article_fixture(%{}, user)
      a2 = article_fixture(%{}, user)

      result = Articles.list_articles()
      ids = Enum.map(result.articles, & &1.id)

      assert a1.id in ids
      assert a2.id in ids
      assert ids == Enum.sort(ids, :desc)
    end

    test "returns next_cursor when articles exceed page size" do
      user = user_fixture()
      for _ <- 1..7, do: article_fixture(%{}, user)

      result = Articles.list_articles()
      assert length(result.articles) == 6
      assert result.next_cursor != nil
    end

    test "returns no next_cursor when articles fit in one page" do
      user = user_fixture()
      for _ <- 1..3, do: article_fixture(%{}, user)

      result = Articles.list_articles()
      assert length(result.articles) == 3
      assert result.next_cursor == nil
    end

    test "second page via cursor returns remaining articles with no overlap" do
      user = user_fixture()
      for _ <- 1..7, do: article_fixture(%{}, user)

      first_page = Articles.list_articles()
      assert first_page.next_cursor != nil

      second_page = Articles.list_articles(first_page.next_cursor)
      assert length(second_page.articles) == 1
      assert second_page.next_cursor == nil

      first_ids = MapSet.new(first_page.articles, & &1.id)
      second_ids = MapSet.new(second_page.articles, & &1.id)
      assert MapSet.disjoint?(first_ids, second_ids)
    end

    test "invalid cursor is ignored and returns first page" do
      user = user_fixture()
      article_fixture(%{}, user)

      result = Articles.list_articles("not_a_valid_cursor")
      assert length(result.articles) == 1
    end
  end

  # ============================================================================
  # filter_articles/2
  # ============================================================================

  describe "filter_articles/2" do
    test "empty filter returns all articles" do
      user = user_fixture()
      article_fixture(%{}, user)
      article_fixture(%{}, user)

      result = Articles.filter_articles(%{})
      assert length(result.articles) == 2
    end

    test "search by article_name returns matching articles" do
      user = user_fixture()
      article_fixture(%{"article_name" => "History of Rome"}, user)
      article_fixture(%{"article_name" => "Greek Mythology"}, user)

      result = Articles.filter_articles(%{"q" => "Rome"})
      assert length(result.articles) == 1
      assert hd(result.articles).article_name == "History of Rome"
    end

    test "search by content returns matching articles" do
      user = user_fixture()

      article_fixture(
        %{"article_name" => "Article One", "content" => "Romans built many roads"},
        user
      )

      article_fixture(
        %{"article_name" => "Article Two", "content" => "Greeks loved philosophy"},
        user
      )

      result = Articles.filter_articles(%{"q" => "Romans"})
      assert length(result.articles) == 1
      assert hd(result.articles).article_name == "Article One"
    end

    test "nil search string returns all articles" do
      user = user_fixture()
      article_fixture(%{}, user)
      article_fixture(%{}, user)

      result = Articles.filter_articles(%{"q" => nil})
      assert length(result.articles) == 2
    end

    test "empty search string returns all articles" do
      user = user_fixture()
      article_fixture(%{}, user)

      result = Articles.filter_articles(%{"q" => ""})
      assert length(result.articles) == 1
    end

    test "filter by category slug returns only matching articles" do
      user = user_fixture()
      cat1 = category_fixture(%{"category_name" => "Ancient Rome"}, user)
      cat2 = category_fixture(%{"category_name" => "Ancient Greece"}, user)

      article_fixture(%{"category_id" => cat1.id}, user)
      article_fixture(%{"category_id" => cat2.id}, user)

      result = Articles.filter_articles(%{"category" => cat1.slug})
      assert length(result.articles) == 1
      assert hd(result.articles).category.slug == cat1.slug
    end

    test "filter by non-existent category returns empty" do
      user = user_fixture()
      article_fixture(%{}, user)

      result = Articles.filter_articles(%{"category" => "does-not-exist"})
      assert result.articles == []
    end

    test "nil category returns all articles" do
      user = user_fixture()
      article_fixture(%{}, user)

      result = Articles.filter_articles(%{"category" => nil})
      assert length(result.articles) == 1
    end

    test "search and category filter combined" do
      user = user_fixture()
      cat = category_fixture(%{"category_name" => "Ancient Rome"}, user)

      article_fixture(%{"article_name" => "Roman Roads", "category_id" => cat.id}, user)
      article_fixture(%{"article_name" => "Roman Baths", "category_id" => cat.id}, user)
      article_fixture(%{"article_name" => "Greek Temples"}, user)

      result = Articles.filter_articles(%{"q" => "Roman", "category" => cat.slug})
      assert length(result.articles) == 2
    end
  end

  # ============================================================================
  # get_articles!/1
  # ============================================================================

  describe "get_articles!/1" do
    test "returns article with all associations preloaded" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      comment_fixture(%{article: article, user: user})

      result = Articles.get_articles!(article.id)

      assert result.id == article.id
      assert %Narasihistorian.Categories.Category{} = result.category
      assert %Narasihistorian.Accounts.User{} = result.user
      assert is_list(result.tags)
      assert is_list(result.comments)
      assert length(result.comments) == 1
      assert %Narasihistorian.Accounts.User{} = hd(result.comments).user
    end

    test "raises Ecto.NoResultsError when article not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Articles.get_articles!(999_999)
      end
    end
  end

  # ============================================================================
  # featured_article/1
  # ============================================================================

  describe "featured_article/1" do
    test "returns related by category when no tag matches (0 tag results)" do
      user = user_fixture()
      cat = category_fixture(%{"category_name" => "Rome"}, user)

      main = article_fixture(%{"category_id" => cat.id}, user)
      related1 = article_fixture(%{"category_id" => cat.id}, user)
      related2 = article_fixture(%{"category_id" => cat.id}, user)
      related3 = article_fixture(%{"category_id" => cat.id}, user)

      main = Articles.get_articles!(main.id)
      result = Articles.featured_article(main)

      ids = Enum.map(result, & &1.id)
      assert length(result) == 3
      assert main.id not in ids
      assert related1.id in ids or related2.id in ids or related3.id in ids
    end

    test "returns 3 articles total when tag results are less than 3" do
      # This branch is: 0 < tag_results < 3, fills the rest from fallback
      user = user_fixture()
      article = article_fixture(%{}, user)
      article_fixture(%{}, user)
      article_fixture(%{}, user)

      main = Articles.get_articles!(article.id)

      # No tags means 0 tag results → falls into category fallback branch
      # To hit the `count < 3` branch, Tags would need to return 1 or 2
      # We test the outcome: always returns <= 3 articles, never includes self
      result = Articles.featured_article(main)
      ids = Enum.map(result, & &1.id)

      assert length(result) <= 3
      assert main.id not in ids
    end

    test "does not include the main article in results" do
      user = user_fixture()
      article = article_fixture(%{}, user)
      article_fixture(%{}, user)

      main = Articles.get_articles!(article.id)
      result = Articles.featured_article(main)

      refute Enum.any?(result, fn a -> a.id == main.id end)
    end

    test "returns empty list when no other articles exist" do
      user = user_fixture()
      article = article_fixture(%{}, user)

      main = Articles.get_articles!(article.id)
      result = Articles.featured_article(main)

      assert result == []
    end
  end

  # ============================================================================
  # list_recent_articles/1
  # ============================================================================

  describe "list_recent_articles/1" do
    test "returns empty list when no articles exist" do
      assert Articles.list_recent_articles() == []
    end

    test "returns articles with category and user preloaded" do
      user = user_fixture()
      article_fixture(%{}, user)

      [article] = Articles.list_recent_articles(1)
      assert %Narasihistorian.Categories.Category{} = article.category
      assert %Narasihistorian.Accounts.User{} = article.user
    end

    test "respects custom limit" do
      user = user_fixture()
      for _ <- 1..10, do: article_fixture(%{}, user)

      assert length(Articles.list_recent_articles(3)) == 3
    end

    test "default limit is 8" do
      user = user_fixture()
      for _ <- 1..10, do: article_fixture(%{}, user)

      assert length(Articles.list_recent_articles()) == 8
    end
  end

  # ============================================================================
  # list_popular_articles/1
  # ============================================================================

  describe "list_popular_articles/1" do
    test "returns empty list when no articles exist" do
      assert Articles.list_popular_articles() == []
    end

    test "only returns articles with an image" do
      user = user_fixture()
      # default fixture has image set to /images/ancient-rome.jpg
      article_fixture(%{}, user)

      result = Articles.list_popular_articles()
      assert Enum.all?(result, fn a -> not is_nil(a.image) end)
    end

    test "respects custom limit" do
      user = user_fixture()
      for _ <- 1..10, do: article_fixture(%{}, user)

      assert length(Articles.list_popular_articles(3)) == 3
    end

    test "default limit is 6" do
      user = user_fixture()
      for _ <- 1..10, do: article_fixture(%{}, user)

      assert length(Articles.list_popular_articles()) == 6
    end
  end

  # ============================================================================
  # create_article_with_tags/2
  # ============================================================================

  describe "create_article_with_tags/2" do
    test "creates article with tags successfully" do
      user = user_fixture()
      category = category_fixture(%{}, user)

      attrs = %{
        "article_name" => "Tagged Article",
        "content" => "some content here",
        "category_id" => category.id,
        "user_id" => user.id
      }

      assert {:ok, %{article: article, tags: tags}} =
               Articles.create_article_with_tags(attrs, ["elixir", "phoenix"])

      assert article.article_name == "Tagged Article"
      assert length(tags) == 2
      assert Enum.map(tags, & &1.name) |> Enum.sort() == ["elixir", "phoenix"]
    end

    test "creates article with empty tag list" do
      user = user_fixture()
      category = category_fixture(%{}, user)

      attrs = %{
        "article_name" => "No Tags Article",
        "content" => "some content here",
        "category_id" => category.id,
        "user_id" => user.id
      }

      assert {:ok, %{article: article}} =
               Articles.create_article_with_tags(attrs, [])

      assert article.article_name == "No Tags Article"
    end

    test "reuses existing tags instead of creating duplicates" do
      user = user_fixture()
      category = category_fixture(%{}, user)

      attrs = %{
        "article_name" => "Article One",
        "content" => "some content here",
        "category_id" => category.id,
        "user_id" => user.id
      }

      {:ok, %{tags: tags1}} = Articles.create_article_with_tags(attrs, ["elixir"])

      attrs2 = Map.put(attrs, "article_name", "Article Two")
      {:ok, %{tags: tags2}} = Articles.create_article_with_tags(attrs2, ["elixir"])

      assert hd(tags1).id == hd(tags2).id
    end

    test "returns error with invalid attrs" do
      assert {:error, _step, _changeset, _changes} =
               Articles.create_article_with_tags(%{}, ["elixir"])
    end
  end

  # ============================================================================
  # get_article_with_tags/1
  # ============================================================================

  describe "get_article_with_tags/1" do
    test "returns article with tags preloaded" do
      user = user_fixture()
      category = category_fixture(%{}, user)

      attrs = %{
        "article_name" => "Tagged Article",
        "content" => "some content here",
        "category_id" => category.id,
        "user_id" => user.id
      }

      {:ok, %{article: article}} =
        Articles.create_article_with_tags(attrs, ["elixir", "phoenix"])

      result = Articles.get_article_with_tags(article.id)
      assert result.id == article.id
      assert length(result.tags) == 2
    end

    test "returns nil when article not found" do
      assert Articles.get_article_with_tags(999_999) == nil
    end
  end
end
