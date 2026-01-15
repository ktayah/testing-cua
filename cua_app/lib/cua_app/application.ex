defmodule CuaApp.Application do
  @moduledoc """
  Main application supervisor for CuaApp.
  Starts the agent and handles environment configuration.
  """

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting CuaApp...")

    children = [
      {CuaApp.Agent, []}
    ]

    opts = [strategy: :one_for_one, name: CuaApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
