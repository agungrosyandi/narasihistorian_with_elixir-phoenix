defmodule NarasihistorianWeb.Admin.DashboardLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Dashboard

  import NarasihistorianWeb.Admin.Components, only: [admin_nav: 1]

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role == :admin do
      {:ok,
       socket
       |> assign(:page_title, "Dashboard")
       |> assign(:current_nav, :dashboard)
       |> assign(:current_page, :dashboard)
       |> assign(:period, 30)
       |> load_metrics()}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be an admin to access dashboard")
       |> redirect(to: ~p"/admin/articles")}
    end
  end

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
  def handle_event("refresh", _params, socket) do
    {:noreply, load_metrics(socket)}
  end

  @impl true
  def handle_info(:update_metrics, socket) do
    {:noreply, load_metrics(socket)}
  end

  defp load_metrics(socket) do
    period = socket.assigns[:period] || 30

    # Load all metrics

    ratio = Dashboard.get_draft_vs_published_ratio()
    trend = Dashboard.get_articles_trend(period)
    top_articles = Dashboard.get_top_articles_by_views(5)
    articles_with_comments = Dashboard.get_articles_with_comment_count(5)
    publishing_freq = Dashboard.get_publishing_frequency(:daily, period)

    # Convert trend data to JSON-friendly format
    # From [{~D[2025-12-28], 0}, ...] to [["2025-12-28", 0], ...]

    trend_json =
      Enum.map(trend, fn {date, count} ->
        [Date.to_iso8601(date), count]
      end)

    # Convert frequency data to JSON-friendly format
    # From [%{period: ~D[2025-12-28], count: 0}, ...] to [%{"period" => "2025-12-28", "count" => 0}, ...]

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
end
