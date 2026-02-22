defmodule NarasihistorianWeb.Admin.DashboardLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Dashboard
  alias Narasihistorian.Drafts

  NarasihistorianWeb.Admin.DashboardLive.DraftHelpers

  import NarasihistorianWeb.CustomComponents,
    only: [admin_sidebar: 1, admin_user_nav: 1, mobile_topbar: 1, truncate: 2]

  # =============================================
  # MOUNT
  # =============================================

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Narasihistorian.PubSub, "dashboard:updates")
        :timer.send_interval(:timer.minutes(5), self(), :periodic_refresh)
      end

      page_title = "Dashboard"

      {:ok,
       socket
       |> assign(:page_title, page_title)
       |> assign(:current_nav, :dashboard)
       |> assign(:current_page, :dashboard)
       |> assign(:sidebar_open, false)
       |> assign(:period, 30)
       |> assign(:last_update, 0)
       |> assign(:active_tab, :dashboard)
       |> load_metrics()
       |> load_drafts()}
    else
      {:ok,
       socket
       |> put_flash(:error, "Akses Dashboard Hanya Berlaku Untuk Admin")
       |> redirect(to: ~p"/")}
    end
  end

  # =============================================
  # HANDLE PARAMS
  # =============================================

  @impl true
  def handle_params(%{"tab" => tab}, _url, socket) do
    active_tab = String.to_existing_atom(tab)

    {:noreply, assign(socket, :active_tab, active_tab)}
  rescue
    _ -> {:noreply, assign(socket, :active_tab, :dashboard)}
  end

  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # =============================================
  # RENDER
  # =============================================

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.admin_user_nav current_page={@current_page} current_user={@current_user} />

      <div class="flex mb-14">
        <%!-- ============================================ --%>
        <%!-- MOBILE OVERLAY --%>
        <%!-- ============================================ --%>

        <div
          :if={@sidebar_open}
          class="fixed inset-0 z-20 bg-black/60 backdrop-blur-sm lg:hidden"
          phx-click="toggle-sidebar"
        />

        <%!-- ============================================ --%>
        <%!-- LEFT SIDEBAR --%>
        <%!-- ============================================ --%>

        <.admin_sidebar
          active={:dashboard}
          current_user={@current_user}
          sidebar_open={@sidebar_open}
          draft_count={length(@all_drafts)}
        />

        <%!-- ============================================ --%>
        <%!-- MAIN CONTENT --%>
        <%!-- ============================================ --%>

        <div class="flex-1 flex flex-col min-w-0">
          <.mobile_topbar
            active_tab={@active_tab}
            on_toggle="toggle-sidebar"
          />

          <%!-- ======================================== --%>
          <%!-- TAB: DASHBOARD --%>
          <%!-- ======================================== --%>

          <div class="flex-1 overflow-y-auto p-6 border border-gray-600 shadow-xl rounded-xl">
            <div :if={@active_tab == :dashboard}>
              <div>
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
                <%!-- TOTAL ARTICLE --%>
                <%!-------------------------%>

                <div class="grid grid-cols-2 gap-5 lg:grid-cols-4 mb-8">
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
                            {@total_views}
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
  def handle_event("toggle-sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("set-tab", %{"tab" => tab}, socket) do
    active_tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, :active_tab, active_tab)}
  end

  def handle_event("change_period", %{"period" => period}, socket) do
    {:noreply, socket |> assign(:period, String.to_integer(period)) |> load_metrics()}
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, socket |> load_metrics() |> load_drafts()}
  end

  def handle_event("delete-draft", %{"id" => id}, socket) do
    Drafts.delete_draft_by_id(String.to_integer(id))
    {:noreply, load_drafts(socket)}
  end

  # ============================================================================
  # HANDLE INFO
  # ============================================================================

  @impl true
  def handle_info({:metrics_updated, event}, socket) do
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

  def handle_info(:periodic_refresh, socket) do
    {:noreply, socket |> load_metrics() |> load_drafts()}
  end

  def handle_info(:update_metrics, socket) do
    {:noreply, load_metrics(socket)}
  end

  # ============================================================================
  # PRIVATE HELPER
  # ============================================================================

  @take_number_top_article 10
  @take_number_article_with_comments 10

  defp load_metrics(socket) do
    period = socket.assigns[:period] || 30
    ratio = Dashboard.get_draft_vs_published_ratio_cached()
    trend = Dashboard.get_articles_trend_cached(period)

    top_articles =
      Dashboard.get_top_articles_by_views_cached(@take_number_top_article)

    articles_with_comments =
      Dashboard.get_articles_with_comment_count_cached(@take_number_article_with_comments)

    total_views =
      top_articles
      |> Enum.map(&Dashboard.get_article_total_views(&1.id))
      |> Enum.sum()

    publishing_freq = Dashboard.get_publishing_frequency_cached(:daily, period)

    trend_json = Enum.map(trend, fn {date, count} -> [Date.to_iso8601(date), count] end)

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

    user = socket.assigns.current_user
    form_draft_count = Drafts.count_all_drafts(user.id)

    total = ratio.total

    draft_percentage =
      if total + form_draft_count > 0 do
        Float.round(form_draft_count / (total + form_draft_count) * 100, 1)
      else
        0.0
      end

    socket
    |> assign(:total_articles, ratio.total)
    |> assign(:published_count, ratio.published)
    |> assign(:draft_count, form_draft_count)
    |> assign(:draft_percentage, draft_percentage)
    |> assign(:published_percentage, ratio.published_percentage)
    |> assign(:draft_percentage, ratio.draft_percentage)
    |> assign(:articles_trend, trend_json)
    |> assign(:top_articles, top_articles)
    |> assign(:articles_with_comments, articles_with_comments)
    |> assign(:publishing_frequency, freq_json)
    |> assign(:total_views, total_views)
  end

  defp load_drafts(socket) do
    user = socket.assigns.current_user
    all_drafts = Drafts.list_all_drafts_for_user(user.id)
    assign(socket, :all_drafts, all_drafts)
  end

  defp maybe_show_flash(socket, event) do
    case event do
      :article_created -> put_flash(socket, :info, "Artikel baru dipublikasi")
      :article_deleted -> put_flash(socket, :info, "Artikel dihapus")
      :comment_created -> put_flash(socket, :info, "Komentar baru masuk")
      _ -> socket
    end
  end
end
