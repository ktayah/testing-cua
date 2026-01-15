defmodule CuaApp.Agent do
  @moduledoc """
  Main agent GenServer that runs the agentic loop with Anthropic.
  Handles computer use automation via Claude and CDP using Docker.
  """

  use GenServer
  require Logger

  alias CuaApp.DockerManager

  defstruct [
    :cdp_url,
    :task,
    :messages,
    :status,
    :max_iterations,
    :tokens_used,
    :current_iteration,
    :anthropic_client,
    :container_id
  ]

  @default_max_iterations 50

  @system_message """
  <SYSTEM_CAPABILITY>
    * You are utilizing an Ubuntu virtual machine with an X11 display with internet access.
    * You can feel free to install Ubuntu applications with your bash tool. Use curl instead of wget.
    * Using bash tool you can start GUI applications, but you need to set export DISPLAY=:1 and use a subshell. For example "(DISPLAY=:1 xterm &)". GUI apps run with bash tool will appear within your desktop environment, but they may take some time to appear. Take a screenshot to confirm it did.
    * When using your bash tool with commands that are expected to output very large quantities of text, redirect into a tmp file and use str_replace_based_edit_tool or `grep -n -B <lines before> -A <lines after> <query> <filename>` to confirm output.
    * When viewing a page it can be helpful to zoom out so that you can see everything on the page.  Either that, or make sure you scroll down to see everything before deciding something isn't available.
    * When using your computer function calls, they take a while to run and send back to you.  Where possible/feasible, try to chain multiple of these calls all into one function calls request.
  </SYSTEM_CAPABILITY>
  <IMPORTANT>
    * When using Firefox, if a startup wizard appears, IGNORE IT.  Do not even click "skip this step".  Instead, click on the address bar where it says "Search or enter address", and enter the appropriate search term or URL there.
    * If the item you are looking at is a pdf, if after taking a single screenshot of the pdf it seems that you want to read the entire document instead of trying to continue to read the pdf from your screenshots + navigation, determine the URL, use curl to download the pdf, install and use pdftotext to convert it to a text file, and then read that text file directly with your str_replace_based_edit_tool.
  </IMPORTANT>
  """

  @doc """
  Starts the agent with a given task.

  ## Options
  - task: The task/goal for the agent (required)
  - max_iterations: Maximum number of agentic loop iterations (default: 50)
  - docker_opts: Options to pass to Docker session creation
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Executes a task with the agent.
  """
  def execute_task(task, opts \\ []) do
    GenServer.call(__MODULE__, {:execute_task, task, opts}, :infinity)
  end

  @doc """
  Gets the current agent status.
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @doc """
  Stops the agent and cleans up resources.
  """
  def stop do
    GenServer.stop(__MODULE__)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    api_key = Application.fetch_env!(:cua_app, :anthropic)[:api_key]

    # anthropic_client = Anthropix.init(api_key, beta: ["computer-use-2025-01-24", "context-1m-2025-08-07"])
    anthropic_client = Anthropix.init(api_key, beta: ["computer-use-2025-01-24"])

    state = %__MODULE__{
      status: :idle,
      messages: [],
      current_iteration: 0,
      tokens_used: %{},
      max_iterations: @default_max_iterations,
      anthropic_client: anthropic_client
    }

    Logger.info("CUA Agent initialized")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status_info = %{
      status: state.status,
      container_id: state.container_id,
      task: state.task,
      iteration: state.current_iteration,
      max_iterations: state.max_iterations
    }

    {:reply, status_info, state}
  end

  @impl true
  def handle_call({:execute_task, task, opts}, _from, state) do
    Logger.info("Starting task execution: #{task}")

    max_iterations = Keyword.get(opts, :max_iterations, @default_max_iterations)
    docker_opts = Keyword.get(opts, :docker_opts, [])

    case DockerManager.create_session(docker_opts) do
      {:ok, session_info} ->
        try do
          state = %{
            state
            | task: task,
              container_id: session_info.container_id,
              cdp_url: session_info.cdp_url,
              status: :running,
              messages: [],
              max_iterations: max_iterations
          }

          Logger.info("Docker session created")
          Logger.info("CDP URL: #{session_info.cdp_url}")

          result = run_agentic_loop(state)

          # Cleanup session
          cleanup_session(state)

          {:reply, result, %{state | status: :idle}}
        catch
          error ->
            Logger.error(inspect(error))
            cleanup_session(state)

            {:reply, {:error, "Task execution failed: #{inspect(error)}"},
             %{state | status: :idle}}
        end

      {:error, reason} ->
        Logger.error("Failed to setup Docker session: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  ## Private Functions

  defp cleanup_session(%{container_id: container_id}) when not is_nil(container_id) do
    Logger.info("Cleaning up Docker container: #{container_id}")
    DockerManager.stop_container(container_id)
  end

  defp cleanup_session(_state), do: :ok

  defp run_agentic_loop(state) do
    initial_message = %{role: "user", content: state.task}
    messages = [initial_message]

    loop_state = %{state | messages: messages}
    execute_loop(loop_state)
  end

  defp execute_loop(state) do
    if state.current_iteration >= state.max_iterations do
      Logger.warning("Max iterations (#{state.max_iterations}) reached")
      {:error, :max_iterations_reached}
    else
      case call_anthropic(state) do
        {:ok, response} ->
          IO.inspect(state.tokens_used, label: "tokens_used")
          IO.inspect(state.messages, label: "messages")
          handle_response(response, state)

        {:error, reason} ->
          Logger.error("Anthropic API error: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp call_anthropic(state) do
    agent_config = Application.fetch_env!(:cua_app, CuaApp.Agent)
    anthropic_config = Application.fetch_env!(:cua_app, :anthropic)

    tools = [
      %{
        type: "computer_20250124",
        name: "computer",
        display_width_px: agent_config[:width],
        display_height_px: agent_config[:height],
        display_number: agent_config[:display_number]
      }
    ]

    params = %{
      model: anthropic_config[:model],
      max_tokens: anthropic_config[:max_tokens],
      messages: state.messages,
      tools: tools,
      system: @system_message
    }

    case Anthropix.chat(state.anthropic_client, params) do
      {:ok, response} -> {:ok, response}
      {:error, error} -> {:error, error}
    end
  end

  defp handle_response(response, state) do
    Logger.info("Iteration #{state.current_iteration + 1}: Got response from Anthropic")

    assistant_message = %{
      role: "assistant",
      content: response["content"]
    }

    tokens_used_in_last_iteration = Map.get(state.tokens_used, state.current_iteration - 1, 0)

    tokens =
      tokens_used_in_last_iteration + response["usage"]["input_tokens"] +
        response["usage"]["output_tokens"]

    tokens_used = Map.put(state.tokens_used, state.current_iteration, tokens)

    state =
      state
      |> Map.put(:tokens_used, tokens_used)
      |> Map.put(:messages, state.messages ++ [assistant_message])
      |> Map.put(:current_iteration, state.current_iteration + 1)

    if has_tool_calls?(response) do
      handle_tool_calls(response, state)
    else
      final_text = extract_final_text(response["content"])
      Logger.info("Task completed: #{final_text}")
      {:ok, final_text}
    end
  end

  defp has_tool_calls?(response) do
    Enum.any?(response["content"], fn
      %{"type" => "tool_use"} -> true
      _ -> false
    end)
  end

  defp handle_tool_calls(response, state) do
    tool_results =
      response["content"]
      |> Enum.filter(fn c -> c["type"] == "tool_use" end)
      |> Enum.map(&execute_tool_call(&1, state))

    user_message = %{
      role: "user",
      content: tool_results
    }

    state = %{
      state
      | messages: extract_relevant_context_messages(state, user_message) ++ [user_message]
    }

    execute_loop(state)
  end

  # Every 3 msgs is a cycle of the second to last tool request and response, and then the last tool request
  @msg_context_limit 7
  @token_limit 200_000

  # Old implementation (commented out for reference):
  # defp extract_relevant_context_messages(state) when state.tokens_used < @token_limit do
  #   state.messages
  # end
  #
  # defp extract_relevant_context_messages(state) do
  #   {initial_msgs, rest_msgs} = Enum.split(state.messages, 2)
  #
  #   chunked_msgs = rest_msgs
  #   |> Enum.chunk_every(2)
  #   |> Enum.with_index(1)
  #   |> Enum.reverse()
  #   |> Enum.reduce_while(%{tokens: Map.get(state.tokens_used, 0), messages: []}, fn {msg_pairs, iteration}, acc ->
  #     tokens_used_for_pair = Map.get(state.tokens_used, iteration)
  #
  #     if tokens_used_for_pair + acc.tokens < @token_limit do
  #       {:cont, %{messages: acc.messages ++ List.flatten(msg_pairs), tokens: tokens_used_for_pair + acc.tokens}}
  #     else
  #       {:halt, acc}
  #     end
  #   end)
  #   |> Map.get(:messages)
  #   |> Enum.reverse()
  #
  #   initial_msgs ++ chunked_msgs
  #   |> IO.inspect(label: "messages")
  # end

  # Fixed implementation:
  defp extract_relevant_context_messages(state, next_user_message \\ nil) do
    # Get the current cumulative token count
    # current_iteration has already been incremented in handle_response
    latest_iteration = state.current_iteration - 1
    total_tokens = Map.get(state.tokens_used, latest_iteration, 0)

    # Estimate tokens for the upcoming user message (tool results)
    # Tool results can be large due to base64 screenshots
    # Rough estimate: 1 token per 4 characters for text, base64 images can be 10k+ tokens
    estimated_next_tokens =
      if next_user_message do
        estimate_message_tokens(next_user_message)
      else
        0
      end

    # Reserve space for the next message
    effective_limit = @token_limit - estimated_next_tokens

    # If under limit (with buffer for next message), return all messages
    if total_tokens < effective_limit do
      state.messages
    else
      # Keep only the initial user request (first message)
      [initial_msg | rest_msgs] = state.messages

      # rest_msgs = [asst_1, user_1, asst_2, user_2, ..., asst_N]
      # We need to keep pairs [asst_i, user_i] together to respect tool_use constraints
      message_pairs = Enum.chunk_every(rest_msgs, 2)

      # Calculate tokens for each pair
      # Since tokens_used is cumulative, we calculate:
      # - pair 0 tokens: tokens_used[0] (includes initial request + first response)
      # - pair i tokens (i > 0): tokens_used[i] - tokens_used[i-1]
      pairs_with_tokens =
        message_pairs
        |> Enum.with_index()
        |> Enum.map(fn {pair, index} ->
          tokens =
            if index == 0 do
              Map.get(state.tokens_used, 0, 0)
            else
              current = Map.get(state.tokens_used, index, 0)
              previous = Map.get(state.tokens_used, index - 1, 0)
              current - previous
            end

          {pair, tokens}
        end)

      # Start from the most recent pairs and work backwards
      # Keep adding pairs until we would exceed the limit (accounting for next message)
      {kept_pairs, _} =
        pairs_with_tokens
        |> Enum.reverse()
        |> Enum.reduce_while({[], 0}, fn {pair, pair_tokens}, {acc_pairs, acc_tokens} ->
          new_total = acc_tokens + pair_tokens

          if new_total < effective_limit do
            {:cont, {[pair | acc_pairs], new_total}}
          else
            {:halt, {acc_pairs, acc_tokens}}
          end
        end)

      # Flatten the kept pairs and prepend the initial message
      kept_messages = List.flatten(kept_pairs)
      result = [initial_msg | kept_messages]

      IO.inspect(length(state.messages) - length(result), label: "Dropped message count")
      IO.inspect(total_tokens, label: "Total tokens before drop")
      IO.inspect(estimated_next_tokens, label: "Estimated next message tokens")
      result
    end
  end

  # Rough token estimation for a message
  # This is approximate - actual tokenization is model-specific
  defp estimate_message_tokens(message) do
    content = message.content

    Enum.reduce(content, 0, fn item, acc ->
      case item do
        %{"type" => "tool_result", "content" => content_str} when is_binary(content_str) ->
          # Base64 encoded images are roughly 1.33x the binary size
          # Screenshots are typically 50-200KB encoded = ~15k-60k tokens
          # Text is roughly 1 token per 4 characters
          char_count = String.length(content_str)

          # Heuristic: if content is very long, assume it's a base64 image
          if char_count > 10_000 do
            # Base64 image: roughly 1 token per 6 characters (less efficient than text)
            acc + div(char_count, 6)
          else
            # Regular text: roughly 1 token per 4 characters
            acc + div(char_count, 4)
          end

        %{"type" => "tool_result"} ->
          # Small overhead for tool result structure
          acc + 50

        _ ->
          acc + 10
      end
    end)
  end

  defp execute_tool_call(tool_call, state) do
    tool_name = tool_call["name"]
    tool_input = tool_call["input"]
    tool_use_id = tool_call["id"]

    Logger.info("Executing tool: #{tool_name} with input: #{inspect(tool_input)}")

    case tool_name do
      "computer" ->
        tool_result = execute_computer_tool(tool_input, state)

        content =
          case tool_input["action"] do
            "screenshot" ->
              %{
                type: "image",
                source: %{type: "base64", media_type: "image/png", data: tool_result}
              }

            _ ->
              %{type: "text", text: tool_result}
          end

        %{
          type: "tool_result",
          tool_use_id: tool_use_id,
          content: [content]
        }

      _ ->
        %{
          type: "tool_result",
          tool_use_id: tool_use_id,
          content: "Error: Failed to perform click action. The application may be unresponsive.",
          is_error: true
        }
    end
  end

  defp execute_computer_tool(input, state) do
    action = input["action"]

    Logger.info("Computer tool action: #{action}")
    container_id = state.container_id
    # From our Dockerfile ENV
    display = ":99"

    case action do
      "key" ->
        text = input["text"]
        # Map key names to xdotool format
        key = map_key_to_xdotool(text)
        docker_exec(container_id, "DISPLAY=#{display} xdotool key #{key}")
        "Key pressed: #{text}"

      "type" ->
        text = input["text"]
        # Escape single quotes for shell
        escaped_text = String.replace(text, "'", "'\\''")
        docker_exec(container_id, "DISPLAY=#{display} xdotool type '#{escaped_text}'")
        "Typed: #{text}"

      "mouse_move" ->
        [x, y] = input["coordinate"]
        docker_exec(container_id, "DISPLAY=#{display} xdotool mousemove #{x} #{y}")
        "Mouse moved to (#{x}, #{y})"

      "left_click" ->
        [x, y] = input["coordinate"]
        docker_exec(container_id, "DISPLAY=#{display} xdotool mousemove #{x} #{y} click 1")
        "Left click executed"

      "right_click" ->
        [x, y] = input["coordinate"]

        docker_exec(container_id, "DISPLAY=#{display} xdotool mousemove #{x} #{y} click 3")
        "Right click executed"

      "middle_click" ->
        [x, y] = input["coordinate"]

        docker_exec(container_id, "DISPLAY=#{display} xdotool mousemove #{x} #{y} click 2")
        "Middle click executed"

      "double_click" ->
        [x, y] = input["coordinate"]

        docker_exec(
          container_id,
          "DISPLAY=#{display} xdotool mousemove #{x} #{y} click --repeat 2 1"
        )

        "Double click executed"

      "screenshot" ->
        # Use ImageMagick to capture screenshot and encode as base64
        base64_screenshot =
          docker_exec(
            container_id,
            "DISPLAY=#{display} import -window root png:- | base64 -w 0"
          )

        screenshot_dir = Path.join([File.cwd!(), "lib", "screenshots"])
        File.mkdir_p!(screenshot_dir)
        screenshot_path = Path.join(screenshot_dir, "#{state.current_iteration}.png")
        File.write!(screenshot_path, Base.decode64!(base64_screenshot))

        base64_screenshot

      "cursor_position" ->
        # Get cursor position using xdotool
        position =
          docker_exec(container_id, "DISPLAY=#{display} xdotool getmouselocation --shell")

        parse_cursor_position(position)

      _ ->
        "Unknown action: #{action}"
    end
  end

  defp docker_exec(container_id, command) do
    # Escape double quotes in the command
    safe_command = String.replace(command, "\"", "\\\"")
    docker_cmd = "docker exec #{container_id} sh -c \"#{safe_command}\""

    case System.cmd("sh", ["-c", docker_cmd], stderr_to_stdout: true) do
      {output, 0} ->
        String.trim(output)

      {output, _exit_code} ->
        Logger.error("Docker exec failed: #{output}")
        "Error executing command: #{output}"
    end
  end

  defp map_key_to_xdotool(key) do
    # Map common key names to xdotool format
    case String.downcase(key) do
      "return" -> "Return"
      "enter" -> "Return"
      "backspace" -> "BackSpace"
      "delete" -> "Delete"
      "tab" -> "Tab"
      "escape" -> "Escape"
      "esc" -> "Escape"
      "space" -> "space"
      "up" -> "Up"
      "down" -> "Down"
      "left" -> "Left"
      "right" -> "Right"
      "home" -> "Home"
      "end" -> "End"
      "pageup" -> "Page_Up"
      "pagedown" -> "Page_Down"
      "ctrl" -> "Control_L"
      "alt" -> "Alt_L"
      "shift" -> "Shift_L"
      "cmd" -> "Super_L"
      "meta" -> "Super_L"
      _ -> key
    end
  end

  defp parse_cursor_position(shell_output) do
    # Parse xdotool getmouselocation output like: X=123\nY=456\n...
    lines = String.split(shell_output, "\n")

    x =
      Enum.find_value(lines, fn line ->
        if String.starts_with?(line, "X=") do
          line |> String.replace("X=", "") |> String.to_integer()
        end
      end)

    y =
      Enum.find_value(lines, fn line ->
        if String.starts_with?(line, "Y=") do
          line |> String.replace("Y=", "") |> String.to_integer()
        end
      end)

    "(#{x || 0}, #{y || 0})"
  end

  defp extract_final_text(content) do
    content
    |> Enum.filter(fn c -> c["type"] == "text" end)
    |> Enum.map(fn c -> c["text"] end)
    |> Enum.join("\n")
  end
end
