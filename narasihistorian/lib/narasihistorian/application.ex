defmodule Narasihistorian.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NarasihistorianWeb.Telemetry,
      Narasihistorian.Repo,
      {DNSCluster, query: Application.get_env(:narasihistorian, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Narasihistorian.PubSub},
      {Cachex, name: :dashboard_cache, limit: 100},

      # Start a worker by calling: Narasihistorian.Worker.start_link(arg)
      # {Narasihistorian.Worker, arg},
      # Start to serve requests, typically the last entry
      Narasihistorian.Scheduler,
      NarasihistorianWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Narasihistorian.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NarasihistorianWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
