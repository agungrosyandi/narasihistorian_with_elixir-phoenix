defmodule NarasihistorianWeb.Admin.DashboardLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Dashboard

  import NarasihistorianWeb.CustomComponents, only: [admin_user_nav: 1]

  # ============================================================================
  # MOUNT
  # ============================================================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      # Subscribe to real-time updates

      if connected?(socket) do
        Phoenix.PubSub.subscribe(Narasihistorian.PubSub, "dashboard:updates")
        :timer.send_interval(:timer.minutes(5), self(), :periodic_refresh)
      end

      {:ok,
       socket
       |> assign(:page_title, "Dashboard")
       |> assign(:current_nav, :dashboard)
       |> assign(:current_page, :dashboard)
       |> assign(:period, 30)
       |> assign(:last_update, 0)
       |> load_metrics()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Akses Dashboard Hanya Berlaku Untuk Admin")
       |> redirect(to: ~p"/admin/articles")}
    end
  end

  # ============================================================================
  # RENDER
  # ============================================================================0

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <div class="container mx-auto mb-14">
        <%!-------------------------%>
        <%!-- ADMIN NAV --%>
        <%!-------------------------%>

        <.admin_user_nav current_page={@current_page} current_user={@current_user} />

        <div>
          <%!-------------------------%>
          <%!-- CONTROL --%>
          <%!-------------------------%>

          <div class="mb-6 flex items-center justify-between">
            <select
              id="period"
              phx-change="change_period"
              name="period"
              class="block rounded-md border bg-black border-gray-500 shadow-sm py-2 px-3 focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
            >
              <option value="7" selected={@period == 7}>Last 7 days</option>
              <option value="30" selected={@period == 30}>Last 30 days</option>
              <option value="90" selected={@period == 90}>Last 90 days</option>
            </select>

            <.span_custom phx-click="refresh" variant="transparant" class="cursor-pointer">
              <.icon name="hero-arrow-path" class="w-4 h-4 mb-1 mr-2" /> Refresh
            </.span_custom>
          </div>

          <%!-------------------------%>
          <%!-- STATS CARDS --%>
          <%!-------------------------%>

          <div class="grid grid-cols-2 gap-5 lg:grid-cols-4 mb-8">
            <%!-------------------------%>
            <%!-- TOTAL ARTICLE --%>
            <%!-------------------------%>

            <div class="border border-gray-500 overflow-hidden shadow rounded-lg">
              <div class="flex items-center p-5">
                <.icon name="hero-document-text" class="w-5 h-5" />

                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-base text-gray-300 truncate">Total Articles</dt>
                    <dd class="text-3xl font-semibold">{@total_articles}</dd>
                  </dl>
                </div>
              </div>
            </div>

            <%!-------------------------%>
            <%!-- PUBLISHED --%>
            <%!-------------------------%>

            <div class="border border-gray-500 overflow-hidden shadow rounded-lg">
              <div class="flex items-center p-5">
                <.icon name="hero-check-circle" class="w-6 h-6 text-green-400" />

                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-base text-gray-300 truncate">Published</dt>
                    <dd class="flex items-baseline">
                      <div class="text-3xl font-semibold">{@published_count}</div>
                      <div class="ml-2 text-sm text-green-600">{@published_percentage}%</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>

            <%!-------------------------%>
            <%!-- DRAFT --%>
            <%!-------------------------%>

            <div class="border border-gray-500 overflow-hidden shadow rounded-lg">
              <div class="flex items-center p-5">
                <.icon name="hero-pencil-square" class="w-6 h-6 text-yellow-400" />

                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-base text-gray-300 truncate">Drafts</dt>
                    <dd class="flex items-baseline">
                      <div class="text-3xl font-semibold">{@draft_count}</div>
                      <div class="ml-2 text-sm text-yellow-600">{@draft_percentage}%</div>
                    </dd>
                  </dl>
                </div>
              </div>
            </div>

            <%!-------------------------%>
            <%!-- TOTAL VIEWS --%>
            <%!-------------------------%>

            <div class="border border-gray-500 overflow-hidden shadow rounded-lg">
              <div class="flex items-center p-5">
                <.icon name="hero-eye" class="w-6 h-6 text-blue-400" />

                <div class="ml-5 w-0 flex-1">
                  <dl>
                    <dt class="text-base text-gray-300 truncate">Total Views</dt>
                    <dd class="text-3xl font-semibold">
                      {@top_articles |> Enum.map(& &1.view_count) |> Enum.sum()}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>

          <%!-------------------------%>
          <%!-- CHARTS SECTIONS --%>
          <%!-------------------------%>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
            <div class="border border-gray-500 shadow rounded-lg p-6">
              <h2 class="text-base text-gray-300 mb-4">Publishing Trend</h2>
              <div
                id="trend-chart"
                phx-hook="TrendChart"
                data-trend={Jason.encode!(@articles_trend)}
              >
                <canvas id="trend-canvas" width="400" height="200"></canvas>
              </div>
            </div>

            <%!-------------------------%>
            <%!-- DRAFT VS PUBLISHED CHART --%>
            <%!-------------------------%>

            <div class="border border-gray-500 shadow rounded-lg p-6">
              <h2 class="text-base text-gray-300 mb-4">Draft vs Published</h2>
              <div
                id="ratio-chart"
                phx-hook="RatioChart"
                data-published={@published_count}
                data-draft={@draft_count}
              >
                <canvas id="ratio-canvas" width="400" height="200"></canvas>
              </div>
            </div>
          </div>

          <%!-------------------------%>
          <%!-- TABLES SECTION --%>
          <%!-------------------------%>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <%!-------------------------%>
            <%!-- TOP ARTICLES BY VIEWS --%>
            <%!-------------------------%>

            <div class="border border-gray-500 rounded-lg overflow-hidden">
              <div class="px-6 py-4 border-b border-gray-500">
                <h2 class="text-base text-gray-300">Top Performing Articles</h2>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-500">
                  <thead class="text-[#fedf16e0] text-sm uppercase tracking-wider text-left ">
                    <tr>
                      <th class="px-6 py-3">
                        Title
                      </th>
                      <th class="px-6 py-3">
                        Views
                      </th>
                    </tr>
                  </thead>
                  <tbody class=" divide-y divide-gray-500">
                    <%= for article <- @top_articles do %>
                      <tr>
                        <td class="px-6 py-4 text-sm">
                          {truncate(article.article_name, 50)}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <span class="inline-flex items-center px-2.5 py-0.5 text-sm font-bold text-white">
                            {Dashboard.get_article_total_views(article.id)}
                          </span>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>

            <%!-------------------------%>
            <%!-- ARTICLES BY COMMENTS --%>
            <%!-------------------------%>

            <div class="border border-gray-500 shadow rounded-lg overflow-hidden">
              <div class="px-6 py-4 border-b border-gray-500">
                <h2 class="text-base text-gray-300">Most Commented Articles</h2>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-500">
                  <thead class="text-[#fedf16e0] text-sm uppercase tracking-wider text-left">
                    <tr>
                      <th class="px-6 py-3">
                        Title
                      </th>
                      <th class="px-6 py-3">
                        Comments
                      </th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-500">
                    <%= for item <- @articles_with_comments do %>
                      <tr>
                        <td class="px-6 py-4 text-sm">
                          {truncate(item.article.article_name, 50)}
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <span class="inline-flex items-center px-2.5 py-0.5 text-sm font-bold text-white">
                            {item.comment_count}
                          </span>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <%!-------------------------%>
          <%!-- PUBLISHING FREQUENCY --%>
          <%!-------------------------%>

          <div class="mt-8 border border-gray-500  shadow rounded-lg p-6">
            <h2 class="text-base text-gray-300 mb-4">Publishing Frequency (Daily)</h2>
            <div
              id="frequency-chart"
              phx-hook="FrequencyChart"
              data-frequency={Jason.encode!(@publishing_frequency)}
            >
              <canvas id="frequency-canvas" width="800" height="200"></canvas>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # ============================================================================
  # HANDLE EVENT
  # ============================================================================

  @impl true
  def handle_event("change_period", %{"period" => period}, socket) do
    period = String.to_integer(period)

    socket =
      socket
      |> assign(:period, period)
      |> load_metrics()

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket), do: {:noreply, load_metrics(socket)}

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:metrics_updated, event}, socket) do
    # Debounce: Only update if last update was more than 2 seconds ago

    last_update = socket.assigns.last_update
    current_time = System.system_time(:second)

    if current_time - last_update > 2 do
      {:noreply,
       socket
       |> assign(:last_update, current_time)
       |> load_metrics()
       |> maybe_show_flash(event)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(:periodic_refresh, socket) do
    {:noreply, load_metrics(socket)}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    {:noreply, load_metrics(socket)}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  defp load_metrics(socket) do
    period = socket.assigns[:period] || 30

    # Load all metrics with CACHED

    ratio = Dashboard.get_draft_vs_published_ratio_cached()
    trend = Dashboard.get_articles_trend_cached(period)
    top_articles = Dashboard.get_top_articles_by_views_cached(10)
    articles_with_comments = Dashboard.get_articles_with_comment_count_cached(10)
    publishing_freq = Dashboard.get_publishing_frequency_cached(:daily, period)

    # Convert trend data to JSON-friendly format

    trend_json =
      Enum.map(trend, fn {date, count} ->
        [Date.to_iso8601(date), count]
      end)

    # Convert frequency data to JSON-friendly format

    freq_json =
      Enum.map(publishing_freq, fn %{period: period, count: count} ->
        period_str =
          case period do
            %Date{} = d -> Date.to_iso8601(d)
            %DateTime{} = dt -> DateTime.to_iso8601(dt)
            %NaiveDateTime{} = ndt -> NaiveDateTime.to_iso8601(ndt)
            _ -> to_string(period)
          end

        %{"period" => period_str, "count" => count}
      end)

    socket
    |> assign(:total_articles, ratio.total)
    |> assign(:published_count, ratio.published)
    |> assign(:draft_count, ratio.draft)
    |> assign(:published_percentage, ratio.published_percentage)
    |> assign(:draft_percentage, ratio.draft_percentage)
    |> assign(:articles_trend, trend_json)
    |> assign(:top_articles, top_articles)
    |> assign(:articles_with_comments, articles_with_comments)
    |> assign(:publishing_frequency, freq_json)
  end

  # truncate

  defp truncate(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) <> "..."
    else
      text
    end
  end

  defp truncate(nil, _length), do: ""

  # Optional: Show subtle flash message on real-time updates

  defp maybe_show_flash(socket, event) do
    case event do
      :article_created ->
        put_flash(socket, :info, "Artikel Baru telah dipublis")

      :article_deleted ->
        put_flash(socket, :info, "Beberapa Artikel telah dihapus")

      :comment_created ->
        put_flash(socket, :info, "Seseorang telah memberikan komentar")

      _ ->
        socket
    end
  end
end
