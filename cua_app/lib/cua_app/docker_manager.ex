defmodule CuaApp.DockerManager do
  @moduledoc """
  Manages local Docker-based browser sessions for computer use.
  Alternative to Browserbase for local development and testing.
  """

  require Logger

  @container_name_prefix "cua_browser_"
  @image_name "cua_computer_use"
  @cdp_port 9222
  @vnc_port 5900
  @max_wait_time 60_000
  @check_interval 2_000

  @doc """
  Creates a new Docker container with Firefox ESR and remote debugging enabled.

  ## Options
  - container_name: Custom container name (optional, defaults to generated name)
  - cdp_port: CDP port to expose (default: 9222)
  - vnc_port: VNC port to expose (default: 5900)
  - remove_on_exit: Auto-remove container when stopped (default: true)

  ## Returns
  {:ok, session_info} or {:error, reason}

  Session info includes:
  - container_id: The Docker container ID
  - container_name: The container name
  - cdp_url: The remote debugging port URL (ws://localhost:9222)
  - vnc_url: The VNC URL for visual debugging (vnc://localhost:5900)
  """
  def create_session(opts \\ []) do
    container_name = Keyword.get(opts, :container_name, generate_container_name())
    cdp_port = Keyword.get(opts, :cdp_port, @cdp_port)
    vnc_port = Keyword.get(opts, :vnc_port, @vnc_port)
    remove_on_exit = Keyword.get(opts, :remove_on_exit, true)

    Logger.info("Creating Docker container: #{container_name}")

    # Ensure image is built
    with :ok <- ensure_image_built(),
         {:ok, container_id} <-
           start_container(container_name, cdp_port, vnc_port, remove_on_exit) do
      # Use Mac Screen sharing app, won't work on non Macs
      System.cmd("open", ["vnc://localhost:5900"])

      case wait_for_chrome(container_id) do
        :ok ->
          session_info = %{
            container_id: container_id,
            container_name: container_name,
            cdp_url: "ws://localhost:#{cdp_port}",
            vnc_url: "vnc://localhost:#{vnc_port}",
            cdp_port: cdp_port,
            vnc_port: vnc_port
          }

          Logger.info("Container ready: #{container_id}")
          {:ok, session_info}

        {:error, reason} ->
          stop_container(container_id)
          {:error, "Browser failed to start: #{reason}"}
      end
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

  defp ensure_image_built do
    Logger.info("Checking Docker image: #{@image_name}")

    case System.cmd("docker", ["images", "-q", @image_name], stderr_to_stdout: true) do
      {"", 0} ->
        Logger.info("Image not found, building...")
        build_image()

      {_output, 0} ->
        Logger.info("Image already exists: #{@image_name}")
        :ok

      {output, _} ->
        Logger.error("Failed to check image: #{output}")
        {:error, output}
    end
  end

  defp build_image do
    # Use current working directory (where mix.exs is)
    dockerfile_path = File.cwd!()

    Logger.info("Building Docker image from: #{dockerfile_path}")

    # Stream output to stdio for real-time feedback, don't try to capture it
    case System.cmd("docker", ["build", "-t", @image_name, dockerfile_path],
           stderr_to_stdout: true,
           into: IO.stream(:stdio, :line)
         ) do
      {_stream, 0} ->
        Logger.info("Image built successfully: #{@image_name}")
        :ok

      {_stream, exit_code} ->
        error_msg = "Docker build failed with exit code #{exit_code}"
        Logger.error(error_msg)
        {:error, error_msg}
    end
  end

  defp start_container(name, cdp_port, vnc_port, remove_on_exit) do
    args = [
      "run",
      "-d",
      "--name",
      name,
      "-p",
      "#{cdp_port}:9222",
      "-p",
      "#{vnc_port}:5900"
    ]

    args = if remove_on_exit, do: args ++ ["--rm"], else: args

    args = args ++ [@image_name]

    Logger.info("Starting container with args: #{inspect(args)}")

    case System.cmd("docker", args, stderr_to_stdout: true) do
      {container_id, 0} ->
        {:ok, String.trim(container_id)}

      {output, _} ->
        {:error, output}
    end
  end

  defp wait_for_chrome(container_id) do
    Logger.info("Waiting for browser to start (max wait: #{@max_wait_time / 1000}s)...")
    wait_for_chrome(container_id, @max_wait_time, 0)
  end

  defp wait_for_chrome(container_id, max_wait, elapsed) when elapsed >= max_wait do
    Logger.error("Timeout after #{elapsed / 1000}s waiting for browser")
    # Get container logs for debugging
    case System.cmd("docker", ["logs", "--tail", "50", container_id], stderr_to_stdout: true) do
      {logs, _} -> Logger.error("Container logs:\n#{logs}")
      _ -> :ok
    end

    {:error, "Timeout waiting for browser to start"}
  end

  defp wait_for_chrome(container_id, max_wait, elapsed) do
    # Log progress every 10 seconds
    if rem(elapsed, 10_000) == 0 and elapsed > 0 do
      Logger.info("Still waiting... (#{elapsed / 1000}s elapsed)")
    end

    # Check if container is still running
    case System.cmd("docker", ["inspect", "-f", "{{.State.Running}}", container_id], stderr_to_stdout: true) do
      {"true\n", 0} ->
        # Container is running, check CDP endpoint
        check_cdp_endpoint(container_id, max_wait, elapsed)

      _ ->
        Logger.error("Container stopped unexpectedly")
        # Try to get logs before container is removed
        case System.cmd("docker", ["logs", "--tail", "100", container_id], stderr_to_stdout: true) do
          {logs, 0} -> Logger.error("Container logs:\n#{logs}")
          {logs, _} -> Logger.error("Container logs (may be incomplete):\n#{logs}")
        end

        {:error, "Container is not running"}
    end
  end

  defp check_cdp_endpoint(container_id, max_wait, elapsed) do
    # Check if Firefox/browser process is running (Firefox doesn't use Chrome's CDP endpoints)
    case System.cmd(
           "docker",
           [
             "exec",
             container_id,
             "sh",
             "-c",
             "ps aux | grep -E '(firefox|chromium)' | grep -v grep"
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
        wait_for_chrome(container_id, max_wait, elapsed + @check_interval)
    end
  end

  defp generate_container_name do
    timestamp = System.system_time(:second)
    random = :rand.uniform(10000)
    "#{@container_name_prefix}#{timestamp}_#{random}"
  end
end
