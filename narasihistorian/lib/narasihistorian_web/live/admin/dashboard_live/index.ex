defmodule NarasihistorianWeb.Admin.DashboardLive.Index do
  use NarasihistorianWeb, :live_view

  alias Narasihistorian.Dashboard

  import NarasihistorianWeb.Admin.Components, only: [admin_nav: 1]

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
