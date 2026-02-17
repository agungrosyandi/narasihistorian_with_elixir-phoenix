defmodule NarasihistorianWeb.User.DashboardLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Admin
  alias Narasihistorian.Dashboard

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    page_title = "Dashboard"

    user_articles = Admin.filter_articles(%{}, [per_page: 1000], current_user)
    user_articles_total_count = user_articles.total_count
    user_articles_entries = user_articles.entries

    recent_articles = Enum.take(user_articles_entries, 5)

    total_views = calculate_total_views(user_articles_entries)

    socket =
      socket
      |> assign(:page_title, page_title)
      |> assign(:total_articles, user_articles_total_count)
      |> assign(:published_count, count_published(user_articles_entries))
      |> assign(:draft_count, count_drafts(user_articles_entries))
      |> assign(:total_views, total_views)
      |> assign(:recent_articles, recent_articles)

    {:ok, socket}
  end

  # ============================================================================
  # RENDER
  # ============================================================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto mb-14">
        <%!-------------------------%>
        <%!-- HEADER --%>
        <%!-------------------------%>

        <div class="mb-8">
          <h1 class="text-3xl font-bold">
            <.icon name="hero-sparkles" class="w-6 h-6 text-[#fedf16e0]" /> Welcome Back,
            <span class="text-[#fedf16e0]">{@current_user.username}</span>
          </h1>
          <p class="text-gray-300 mt-5 text-sm">Here's an overview of your content</p>
        </div>

        <%!-------------------------%>
        <%!-- STATS GRID --%>
        <%!-------------------------%>

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
                Unique views across all articles
              </div>
            </div>
          </div>
        </div>

        <%!-------------------------%>
        <%!-- QUICJS ACTIONS --%>
        <%!-------------------------%>

        <div class="border-b border-gray-500 mb-5">
          <div class="flex flex-wrap justify-end gap-5 my-8">
            <.link navigate={~p"/user/articles/new"}>
              <.span_custom variant="main">
                <.icon name="hero-plus" class="w-5 h-5 mb-1 text-gray-100" />
              </.span_custom>
            </.link>

            <.link navigate={~p"/user/articles"}>
              <.span_custom variant="main">
                <.icon name="hero-clipboard-document-check" class="w-5 h-5 mb-1 text-gray-100" />
              </.span_custom>
            </.link>

            <.link navigate={~p"/articles"}>
              <.span_custom variant="main">
                <.icon name="hero-home" class="w-5 h-5 mb-1 text-gray-100" />
              </.span_custom>
            </.link>
          </div>
        </div>

        <%!-------------------------%>
        <%!-- RECENT ARTICLES --%>
        <%!-------------------------%>

        <div class="flex justify-between items-center mb-5">
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
                <.link navigate={~p"/user/articles/new"}>
                  <.span_custom variant="yellow">Buat Artikel</.span_custom>
                </.link>
              </div>
            </div>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for article <- @recent_articles do %>
              <div class="card bg-base-200 hover:shadow-lg transition-shadow">
                <div class="card-body">
                  <div class="text-[#1DCD9F] font-bold mb-5">
                    {String.upcase(article.status)}
                  </div>

                  <h3 class="card-title">
                    <.link
                      navigate={~p"/articles/#{article.id}"}
                      class="hover:text-primary transition-colors"
                    >
                      {truncate(article.article_name, 50)}
                    </.link>
                  </h3>

                  <div class="card-actions justify-between items-center mt-4">
                    <div class="flex flex-col gap-2 text-sm text-gray-600 md:flex-row md:gap-5">
                      <span class="text-gray-300">
                        <.icon name="hero-eye" class="w-4 h-4 mr-1 text-gray-400" />
                        {Dashboard.get_article_total_views(article.id)} views
                      </span>
                      <span class="text-gray-300">
                        <.icon name="hero-calendar" class="w-4 h-4 mr-1 text-gray-400" />
                        {Calendar.strftime(article.updated_at, "%b %d, %Y")}
                      </span>
                    </div>

                    <.link navigate={~p"/articles/#{article.id}"}>
                      <.span_custom variant="transparant">Lihat Artikel</.span_custom>
                    </.link>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  # =================================
  # PRIVATE HELPER TEXT TRUNCATE
  # =================================

  defp truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  defp truncate(nil, _length), do: ""

  # =================================
  # PRIVATE HELPER METRIC ARTICLES
  # =================================

  defp count_published(articles), do: Enum.count(articles, &(&1.status == "published"))
  defp count_drafts(articles), do: Enum.count(articles, &(&1.status == "draft"))

  defp calculate_total_views(articles) do
    articles
    |> Enum.map(& &1.id)
    |> Enum.reduce(0, fn article_id, acc ->
      acc + Dashboard.get_article_total_views(article_id)
    end)
  end
end
