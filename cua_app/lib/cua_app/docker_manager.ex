defmodule CuaApp.DockerManager do
  @moduledoc """
  Manages local Docker-based browser sessions for computer use.
  Expects containers to be started via docker-compose.
  Only validates that the browser container is running and accessible.
  """

  require Logger

  @expected_container_name "cua_browser"
  @container_name_prefix "cua_browser_"
  @image_name "cua_computer_use"
  @cdp_port 9222
  @vnc_port 5900
  @max_wait_time 60_000
  @check_interval 2_000

  @doc """
  Connects to an existing Docker container started by docker-compose.
  Expects the container 'cua_browser_main' to already be running.

  ## Options
  - container_name: Container name to check (default: "cua_browser_main")
  - cdp_port: Expected CDP port (default: 9222)
  - vnc_port: Expected VNC port (default: 5900)

  ## Returns
  {:ok, session_info} or {:error, reason}

  Session info includes:
  - container_id: The Docker container ID
  - container_name: The container name
  - cdp_url: The remote debugging port URL (ws://localhost:9222)
  - vnc_url: The VNC URL for visual debugging (vnc://localhost:5900)

  ## Usage
  Before calling this function, ensure docker-compose is running:
  ```bash
  docker-compose up -d
  ```

  Then in your Elixir code:
  ```elixir
  case CuaApp.DockerManager.create_session() do
    {:ok, session_info} -> # Use session_info
    {:error, reason} -> # Container not running - start docker-compose
  end
  ```
  """
  def create_session(opts \\ []) do
    container_name = Keyword.get(opts, :container_name, @expected_container_name)
    cdp_port = Keyword.get(opts, :cdp_port, @cdp_port)
    vnc_port = Keyword.get(opts, :vnc_port, @vnc_port)

    Logger.info("Checking for existing container: #{container_name}")

    # Use Mac Screen sharing app, won't work on non Macs
    System.cmd("open", ["vnc://localhost:5900"])

    with {:ok, container_id} <- check_container_exists(container_name),
         {:ok, is_running} <- check_container_running(container_id),
         :ok <- validate_container_running(is_running, container_name),
         :ok <- wait_for_browser_ready(container_id) do
      session_info = %{
        container_id: container_id,
        container_name: container_name,
        cdp_url: "ws://localhost:#{cdp_port}",
        vnc_url: "vnc://localhost:#{vnc_port}",
        cdp_port: cdp_port,
        vnc_port: vnc_port
      }

      Logger.info("Container ready: #{container_id} (#{container_name})")
      {:ok, session_info}
    else
      {:error, :container_not_found} ->
        {:error,
         """
         Container '#{container_name}' not found.
         Please start it with docker-compose:
           docker-compose up -d
         """}

      {:error, :container_not_running} ->
        {:error,
         """
         Container '#{container_name}' exists but is not running.
         Start it with:
           docker-compose up -d
         Or check its status:
           docker-compose ps
         """}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Stops and removes a Docker container.

  ## Parameters
  - container_id: The container ID or name to stop

  ## Returns
  :ok or {:error, reason}
  """
  def stop_container(container_id) do
    Logger.info("Stopping container: #{container_id}")

    case System.cmd("docker", ["stop", container_id], stderr_to_stdout: true) do
      {_, 0} ->
        Logger.info("Container stopped: #{container_id}")
        :ok

      {output, _} ->
        Logger.warning("Failed to stop container: #{output}")
        {:error, output}
    end
  end

  @doc """
  Gets information about a running container.

  ## Parameters
  - container_id: The container ID or name

  ## Returns
  {:ok, info} or {:error, reason}
  """
  def get_container_info(container_id) do
    case System.cmd("docker", ["inspect", container_id], stderr_to_stdout: true) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, [info | _]} -> {:ok, info}
          {:error, reason} -> {:error, "Failed to parse container info: #{inspect(reason)}"}
        end

      {output, _} ->
        {:error, "Container not found: #{output}"}
    end
  end

  @doc """
  Lists all running CUA browser containers.

  ## Returns
  {:ok, containers} or {:error, reason}
  """
  def list_containers do
    case System.cmd(
           "docker",
           [
             "ps",
             "--filter",
             "name=#{@container_name_prefix}",
             "--format",
             "{{.ID}}\t{{.Names}}\t{{.Status}}"
           ],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        containers =
          output
          |> String.split("\n", trim: true)
          |> Enum.map(fn line ->
            [id, name, status] = String.split(line, "\t")
            %{id: id, name: name, status: status}
          end)

        {:ok, containers}

      {output, _} ->
        {:error, "Failed to list containers: #{output}"}
    end
  end

  @doc """
  Removes all stopped CUA browser containers.

  ## Returns
  :ok or {:error, reason}
  """
  def cleanup_stopped_containers do
    Logger.info("Cleaning up stopped containers...")

    case System.cmd(
           "docker",
           [
             "ps",
             "-a",
             "--filter",
             "name=#{@container_name_prefix}",
             "--filter",
             "status=exited",
             "-q"
           ],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        container_ids =
          output
          |> String.split("\n", trim: true)

        if Enum.empty?(container_ids) do
          Logger.info("No stopped containers to clean up")
          :ok
        else
          Logger.info("Removing #{length(container_ids)} stopped containers")
          System.cmd("docker", ["rm" | container_ids], stderr_to_stdout: true)
          :ok
        end

      {output, _} ->
        {:error, "Failed to list stopped containers: #{output}"}
    end
  end

  ## Private Functions

  defp check_container_exists(container_name) do
    Logger.debug("Checking if container exists: #{container_name}")

    case System.cmd("docker", ["inspect", "-f", "{{.Id}}", container_name],
           stderr_to_stdout: true
         ) do
      {container_id, 0} ->
        {:ok, String.trim(container_id)}

      {_output, _} ->
        Logger.warning("Container '#{container_name}' not found")
        {:error, :container_not_found}
    end
  end

  defp check_container_running(container_id) do
    case System.cmd("docker", ["inspect", "-f", "{{.State.Running}}", container_id],
           stderr_to_stdout: true
         ) do
      {"true\n", 0} ->
        {:ok, true}

      {"false\n", 0} ->
        {:ok, false}

      {output, _} ->
        {:error, "Failed to check container status: #{output}"}
    end
  end

  defp validate_container_running(true, _container_name), do: :ok

  defp validate_container_running(false, container_name) do
    Logger.warning("Container '#{container_name}' exists but is not running")
    {:error, :container_not_running}
  end

  defp wait_for_browser_ready(container_id) do
    Logger.info("Waiting for browser to be ready (max wait: #{@max_wait_time / 1000}s)...")
    wait_for_browser_ready(container_id, @max_wait_time, 0)
  end

  defp wait_for_browser_ready(container_id, max_wait, elapsed) when elapsed >= max_wait do
    Logger.error("Timeout after #{elapsed / 1000}s waiting for browser")

    # Get container logs for debugging
    case System.cmd("docker", ["logs", "--tail", "50", container_id], stderr_to_stdout: true) do
      {logs, _} -> Logger.error("Container logs:\n#{logs}")
      _ -> :ok
    end

    {:error, "Timeout waiting for browser to be ready"}
  end

  defp wait_for_browser_ready(container_id, max_wait, elapsed) do
    # Log progress every 10 seconds
    if rem(elapsed, 10_000) == 0 and elapsed > 0 do
      Logger.info("Still waiting... (#{elapsed / 1000}s elapsed)")
    end

    # Check if browser process is running
    case System.cmd(
           "docker",
           [
             "exec",
             container_id,
             "sh",
             "-c",
             "ps aux | grep -E '(firefox|chromium|chrome)' | grep -v grep"
           ],
           stderr_to_stdout: true
         ) do
      {output, 0} when byte_size(output) > 0 ->
        # Browser process is running
        Logger.info("Browser is ready! (took #{elapsed / 1000}s)")
        Logger.debug("Browser process: #{String.slice(output, 0, 100)}")
        :ok

      _ ->
        # Browser not started yet
        Logger.debug("Browser not ready yet, waiting...")
        Process.sleep(@check_interval)
        wait_for_browser_ready(container_id, max_wait, elapsed + @check_interval)
    end
  end
end
