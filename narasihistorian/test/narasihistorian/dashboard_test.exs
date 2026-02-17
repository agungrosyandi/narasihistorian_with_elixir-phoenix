# defmodule YourApp.DashboardTest do
#   use YourApp.DataCase

#   alias Narasihistorian.Dashboard
#   alias Narasihistorian.Articles

#   describe "get_total_articles_count/0" do
#     test "returns 0 when no articles exist" do
#       assert Dashboard.get_total_articles_count() == 0
#     end

#     test "returns correct count of articles" do
#       # Create some test articles

#       Blog.create_article(%{title: "Test 1", content: "Content", status: "published"})
#       Blog.create_article(%{title: "Test 2", content: "Content", status: "draft"})

#       assert Dashboard.get_total_articles_count() == 2
#     end
#   end

#   describe "get_draft_vs_published_ratio/0" do
#     test "returns correct ratio" do
#       Blog.create_article(%{title: "Published 1", content: "Content", status: "published"})
#       Blog.create_article(%{title: "Published 2", content: "Content", status: "published"})
#       Blog.create_article(%{title: "Draft 1", content: "Content", status: "draft"})

#       ratio = Dashboard.get_draft_vs_published_ratio()

#       assert ratio.total == 3
#       assert ratio.published == 2
#       assert ratio.draft == 1
#       assert ratio.published_percentage == 66.7
#       assert ratio.draft_percentage == 33.3
#     end
#   end

#   describe "get_articles_trend/1" do
#     test "returns trend data for specified period" do
#       # Create articles with different dates
#       {:ok, article} =
#         Blog.create_article(%{
#           title: "Old Article",
#           content: "Content",
#           status: "published"
#         })

#       # Update the inserted_at to be 5 days ago
#       Repo.update_all(
#         from(a in Blog.Article, where: a.id == ^article.id),
#         set: [inserted_at: DateTime.add(DateTime.utc_now(), -5, :day)]
#       )

#       Blog.create_article(%{title: "Recent", content: "Content", status: "published"})

#       trend = Dashboard.get_articles_trend(7)

#       # 7 days + today
#       assert length(trend) == 8
#       assert Enum.any?(trend, fn {_date, count} -> count > 0 end)
#     end
#   end

#   describe "get_top_articles_by_views/1" do
#     test "returns articles ordered by view count" do
#       {:ok, article1} =
#         Blog.create_article(%{
#           title: "Most Viewed",
#           content: "Content",
#           status: "published",
#           view_count: 100
#         })

#       {:ok, article2} =
#         Blog.create_article(%{
#           title: "Second",
#           content: "Content",
#           status: "published",
#           view_count: 50
#         })

#       top_articles = Dashboard.get_top_articles_by_views(10)

#       assert length(top_articles) == 2
#       assert hd(top_articles).id == article1.id
#       assert hd(top_articles).view_count == 100
#     end

#     test "limits results to specified number" do
#       for i <- 1..15 do
#         Blog.create_article(%{
#           title: "Article #{i}",
#           content: "Content",
#           status: "published",
#           view_count: i
#         })
#       end

#       top_articles = Dashboard.get_top_articles_by_views(5)

#       assert length(top_articles) == 5
#     end
#   end

#   describe "increment_article_views/1" do
#     test "increments view count" do
#       {:ok, article} =
#         Blog.create_article(%{
#           title: "Test",
#           content: "Content",
#           status: "published",
#           view_count: 0
#         })

#       Dashboard.increment_article_views(article.id)

#       # Wait a bit for async task
#       :timer.sleep(100)

#       updated_article = Blog.get_article!(article.id)
#       assert updated_article.view_count == 1
#     end
#   end
# end
