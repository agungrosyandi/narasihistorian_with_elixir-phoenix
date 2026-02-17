# defmodule Narasihistorian.CategoriesTest do
#   use Narasihistorian.DataCase

#   alias Narasihistorian.Categories

#   import Narasihistorian.CategoriesFixtures
#   import Narasihistorian.AccountsFixtures
#   import Narasihistorian.ArticlesFixtures

#   # ============================================================================
#   # SIMPLE — list_categories/1
#   # ============================================================================

#   describe "list_categories/0" do
#     test "returns empty list when no categories exist" do
#       assert Categories.list_categories() == []
#     end

#     test "returns all categories" do
#       user = user_fixture()
#       category = category_fixture(%{}, user)

#       result = Categories.list_categories()
#       assert length(result) == 1
#       assert hd(result).id == category.id
#     end

#     test "respects pagination - per_page option" do
#       user = user_fixture()
#       # create 3 categories
#       Enum.each(1..3, fn _ -> category_fixture(%{}, user) end)

#       result = Categories.list_categories(per_page: 2)
#       assert length(result) == 2
#     end

#     test "respects pagination - page option" do
#       user = user_fixture()
#       Enum.each(1..3, fn _ -> category_fixture(%{}, user) end)

#       page1 = Categories.list_categories(page: 1, per_page: 2)
#       page2 = Categories.list_categories(page: 2, per_page: 2)

#       assert length(page1) == 2
#       assert length(page2) == 1
#       # pages should have different records
#       refute hd(page1).id == hd(page2).id
#     end

#     test "returns categories ordered by name" do
#       user = user_fixture()
#       category_fixture(%{category_name: "Zebra"}, user)
#       category_fixture(%{category_name: "Alpha"}, user)
#       category_fixture(%{category_name: "Middle"}, user)

#       result = Categories.list_categories()
#       names = Enum.map(result, & &1.category_name)

#       assert names == Enum.sort(names)
#     end
#   end

#   # ============================================================================
#   # SIMPLE — get_category!/1
#   # ============================================================================

#   describe "get_category!/1" do
#     test "returns category with valid id" do
#       category = category_fixture()

#       result = Categories.get_category!(category.id)
#       assert result.id == category.id
#       assert result.category_name == category.category_name
#     end

#     test "raises when id does not exist" do
#       assert_raise Ecto.NoResultsError, fn ->
#         Categories.get_category!(999_999)
#       end
#     end
#   end

#   # ============================================================================
#   # SIMPLE — create_category/2
#   # ============================================================================

#   describe "create_category/2" do
#     test "with valid data creates a category" do
#       user = user_fixture()
#       attrs = %{category_name: "History", slug: "history"}

#       assert {:ok, category} = Categories.create_category(attrs, user)
#       assert category.category_name == "History"
#       assert category.slug == "history"
#     end

#     test "with missing category_name returns error" do
#       user = user_fixture()

#       assert {:error, changeset} = Categories.create_category(%{slug: "history"}, user)
#       assert "can't be blank" in errors_on(changeset).category_name
#     end

#     test "with missing slug returns error" do
#       user = user_fixture()

#       assert {:error, changeset} = Categories.create_category(%{category_name: "History"}, user)
#       assert "can't be blank" in errors_on(changeset).slug
#     end

#     test "with duplicate category_name returns error" do
#       user = user_fixture()
#       category_fixture(%{category_name: "History", slug: "history"}, user)

#       assert {:error, changeset} =
#                Categories.create_category(%{category_name: "History", slug: "history-2"}, user)

#       assert "has already been taken" in errors_on(changeset).category_name
#     end
#   end

#   # ============================================================================
#   # MEDIUM — update_category/3 with Policy
#   # ============================================================================

#   describe "update_category/3" do
#     test "admin can update any category" do
#       admin = user_fixture(%{role: :admin})
#       category = category_fixture(%{}, admin)

#       assert {:ok, updated} =
#                Categories.update_category(category, %{category_name: "Updated"}, admin)

#       assert updated.category_name == "Updated"
#     end

#     test "owner can update their own category" do
#       user = user_fixture()
#       category = category_fixture(%{}, user)

#       assert {:ok, updated} =
#                Categories.update_category(category, %{category_name: "Updated"}, user)

#       assert updated.category_name == "Updated"
#     end

#     test "other user cannot update someone else's category" do
#       owner = user_fixture()
#       other_user = user_fixture()
#       category = category_fixture(%{}, owner)

#       assert {:error, :unauthorized} =
#                Categories.update_category(category, %{category_name: "Hacked"}, other_user)
#     end

#     test "with invalid data returns error changeset" do
#       admin = user_fixture(%{role: :admin})
#       category = category_fixture(%{}, admin)

#       assert {:error, changeset} =
#                Categories.update_category(category, %{category_name: nil}, admin)

#       assert "can't be blank" in errors_on(changeset).category_name
#     end
#   end

#   # ============================================================================
#   # COMPLEX — delete_category/1 with articles check
#   # ============================================================================

#   describe "delete_category/1" do
#     test "deletes category that has no articles" do
#       category = category_fixture()

#       assert {:ok, deleted} = Categories.delete_category(category)
#       assert deleted.id == category.id

#       assert_raise Ecto.NoResultsError, fn ->
#         Categories.get_category!(category.id)
#       end
#     end

#     test "returns error when category has articles" do
#       user = user_fixture()
#       category = category_fixture(%{}, user)
#       # create an article under this category
#       _article = article_fixture(%{category_id: category.id}, user)

#       assert {:error, :has_articles} = Categories.delete_category(category)
#       # category should still exist
#       assert Categories.get_category!(category.id)
#     end
#   end
# end
