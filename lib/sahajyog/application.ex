defmodule Sahajyog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SahajyogWeb.Telemetry,
      Sahajyog.Repo,
      {DNSCluster, query: Application.get_env(:sahajyog, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Sahajyog.PubSub},
      # Real-time Presence
      SahajyogWeb.Presence,
      # API cache for external API responses (countries, years, categories, etc.)
      Sahajyog.ApiCache,
      # Start to serve requests, typically the last entry
      SahajyogWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sahajyog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SahajyogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
