defmodule Narasihistorian.Scheduler do
  use GenServer
  require Logger

  # Starts the scheduler GenServer.

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # Manually trigger cleanup (for testing/admin).

  def trigger_cleanup, do: GenServer.cast(__MODULE__, :cleanup)

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Scheduler started - scheduling cleanup tasks")

    # Schedule first cleanup

    schedule_cleanup()

    {:ok, %{last_cleanup: nil}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Logger.info("Starting scheduled cleanup of old article views")

    # Run cleanup

    case Narasihistorian.Dashboard.cleanup_old_views(90) do
      {:ok, count} ->
        Logger.info("✅ Successfully cleaned up #{count} old view records")

      {:error, reason} ->
        Logger.error("❌ Cleanup failed: #{inspect(reason)}")
    end

    # Schedule next cleanup

    schedule_cleanup()

    {:noreply, %{state | last_cleanup: DateTime.utc_now()}}
  end

  @impl true
  def handle_cast(:cleanup, state) do
    # Manual trigger

    send(self(), :cleanup)
    {:noreply, state}
  end

  # Private Functions

  defp schedule_cleanup do
    # Schedule cleanup in 1 week (7 days)
    # For testing: Use :timer.minutes(1)
    # For production: Use :timer.hours(24 * 7)

    Process.send_after(self(), :cleanup, :timer.hours(24 * 7))
  end
end
