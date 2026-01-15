defmodule CuaApp do
  @moduledoc """
  CuaApp - Computer Use Anthropic Application with Browserbase

  Main interface for executing browser automation tasks using Claude's Computer Use API.
  """

  @doc """
  Executes a browser automation task using the agent.

  ## Parameters
  - task: String describing what the agent should do
  - opts: Optional keyword list
    - :max_iterations - Maximum agentic loop iterations (default: 50)
    - :browserbase_opts - Options for Browserbase session creation
      - :project_id - Browserbase project ID
      - :timeout - Session timeout in seconds
      - :keep_alive - Keep session alive after completion

  ## Examples

      # Simple task
      CuaApp.run("Go to example.com and fill out the contact form with name 'John Doe'")

      # With options
      CuaApp.run(
        "Navigate to dashboard and extract user metrics",
        max_iterations: 30,
        browserbase_opts: [project_id: "proj_123", timeout: 600]
      )

  ## Returns
  - {:ok, result} - Task completed successfully
  - {:error, reason} - Task failed
  """
  def run(task, opts \\ []) do
    CuaApp.Agent.execute_task(task, opts)
  end

  @doc """
  Gets the current status of the agent.

  ## Returns
  Map with current agent state including:
  - status: :idle | :running
  - session_id: Active Browserbase session ID (if any)
  - task: Current task being executed
  - iteration: Current loop iteration
  """
  def status do
    CuaApp.Agent.get_status()
  end

  @doc """
  Stops the agent and cleans up resources.
  """
  def stop do
    CuaApp.Agent.stop()
  end
end
