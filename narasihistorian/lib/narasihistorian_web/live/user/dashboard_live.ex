defmodule NarasihistorianWeb.User.DashboardLive do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    user_articles = Admin.filter_articles(%{}, [per_page: 1000], current_user)
    recent_articles = Enum.take(user_articles.entries, 5)

    socket =
      socket
      |> assign(:page_title, "My Dashboard")
      |> assign(:total_articles, user_articles.total_count)
      |> assign(:published_count, count_published(user_articles.entries))
      |> assign(:draft_count, count_drafts(user_articles.entries))
      |> assign(:total_views, sum_views(user_articles.entries))
      |> assign(:recent_articles, recent_articles)

    {:ok, socket}
  end

  defp count_published(articles), do: Enum.count(articles, &(&1.status == "published"))
  defp count_drafts(articles), do: Enum.count(articles, &(&1.status == "draft"))
  defp sum_views(articles), do: Enum.reduce(articles, 0, &(&1.view_count + &2))

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto py-8">
        <div class="mb-8">
          <h1 class="text-3xl font-bold">
            <.icon name="hero-sparkles" class="w-6 h-6 text-[#fedf16e0]" /> Welcome Back,
            <span class="text-[#fedf16e0]">{@current_user.username}</span>
          </h1>
          <p class="text-gray-300 mt-5 text-sm">Here's an overview of your content</p>
        </div>

        <%!-- Stats Grid --%>

        <div class="grid grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div class="card bg-base-200">
            <div class="card-body">
              <h2 class="card-title text-sm text-gray-300">Total Articles</h2>
              <p class="text-4xl font-bold">{@total_articles}</p>
              <div class="text-sm text-gray-400 mt-2">
                All your published and draft articles
              </div>
            </div>
          </div>

          <div class="card bg-success bg-opacity-10">
            <div class="card-body">
              <h2 class="card-title text-sm text-gray-800">Published</h2>
              <p class="text-4xl font-bold text-gray-800">{@published_count}</p>
              <div class="text-sm text-gray-800 mt-2">
                Live and visible to readers
              </div>
            </div>
          </div>

          <div class="card bg-warning bg-opacity-10">
            <div class="card-body">
              <h2 class="card-title text-sm text-gray-800">Drafts</h2>
              <p class="text-4xl font-bold text-gray-800">{@draft_count}</p>
              <div class="text-sm text-gray-800 mt-2">
                Work in progress
              </div>
            </div>
          </div>

          <div class="card bg-info bg-opacity-10">
            <div class="card-body">
              <h2 class="card-title text-sm text-gray-800">Total Views</h2>
              <p class="text-4xl font-bold text-gray-800">{@total_views}</p>
              <div class="text-sm text-gray-800 mt-2">
                Across all your articles
              </div>
            </div>
          </div>
        </div>

        <%!-- Quick Actions --%>

        <div class="mb-8">
          <div class="flex flex-wrap gap-4">
            <.link navigate={~p"/user/articles/new"}>
              <.span_custom variant="main">
                <.icon name="hero-plus" class="w-5 h-5 mb-1 mr-2 text-gray-100" /> Buat Artikel
              </.span_custom>
            </.link>

            <.link navigate={~p"/user/articles"}>
              <.span_custom variant="main">
                <.icon name="hero-clipboard-document-check" class="w-5 h-5 mb-1 mr-2 text-gray-100" />
                Manage Artikel
              </.span_custom>
            </.link>

            <.link navigate={~p"/articles"}>
              <.span_custom variant="main">
                <.icon name="hero-home" class="w-5 h-5 mb-1 mr-2 text-gray-100" /> Browse All Articles
              </.span_custom>
            </.link>
          </div>
        </div>

        <%!-- Recent Articles --%>

        <div>
          <div class="flex justify-between items-center mb-4">
            <h2 class="text-2xl font-bold">Recent Articles</h2>
            <.link navigate={~p"/user/articles"} class="text-[#fedf16e0] hover:underline">
              View all →
            </.link>
          </div>

          <%= if @recent_articles == [] do %>
            <div class="card bg-base-200">
              <div class="card-body text-center py-12">
                <.icon name="hero-clipboard" class="w-16 h-16 mx-auto text-gray-400 mb-4" />
                <h3 class="text-xl font-semibold mb-2">Tidak ada Artikel yang dipublish</h3>
                <p class="text-gray-300 mb-4">Start creating your first article!</p>

                <div class="flex justify-center">
                  <.link navigate={~p"/user/articles/new"} class="btn btn-primary">
                    Buat Artikel
                  </.link>
                </div>
              </div>
            </div>
          <% else %>
            <div class="space-y-4">
              <%= for article <- @recent_articles do %>
                <div class="card bg-base-200 hover:shadow-lg transition-shadow">
                  <div class="card-body">
                    <div class="flex justify-between items-start">
                      <div class="flex-1">
                        <h3 class="card-title">
                          <.link
                            navigate={~p"/articles/#{article.id}"}
                            class="hover:text-primary transition-colors"
                          >
                            {article.article_name}
                          </.link>
                        </h3>
                        <p class="text-sm text-gray-400 mt-2">
                          {article.content |> strip_html() |> String.slice(0, 150)}...
                        </p>
                      </div>
                      <div class="text-[#1DCD9F] font-bold">
                        {String.upcase(article.status)}
                      </div>
                    </div>

                    <div class="card-actions justify-between items-center mt-4">
                      <div class="flex gap-4 text-sm text-gray-600">
                        <span class="flex items-center gap-1 text-gray-300">
                          <.icon name="hero-eye" class="w-4 h-4 mr-1 text-gray-400" />
                          {article.view_count} views
                        </span>
                        <span class="flex items-center gap-1 text-gray-300">
                          <.icon name="hero-calendar" class="w-4 h-4 mr-1 text-gray-400" />
                          {Calendar.strftime(article.updated_at, "%b %d, %Y")}
                        </span>
                      </div>

                      <.link navigate={~p"/articles/#{article.id}"} class="btn btn-sm btn-primary">
                        Lihat Artikel
                      </.link>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp strip_html(html) do
    html
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
