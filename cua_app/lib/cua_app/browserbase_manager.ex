defmodule CuaApp.BrowserbaseManager do
  @moduledoc """
  Manages Browserbase sessions for computer use.
  Handles session creation, CDP connection URL retrieval, and cleanup.
  """

  alias BrowserbaseAPI.Api.Default
  alias BrowserbaseAPI.Connection

  @doc """
  Creates a new Browserbase session with CDP enabled.

  ## Options
  - project_id: Browserbase project ID (required)
  - timeout: Session timeout in seconds (optional)
  - keep_alive: Whether to keep session alive (optional, default: false)
  - region: Preferred region (optional)

  ## Returns
  {:ok, session_info} or {:error, reason}

  Session info includes:
  - session_id: The session ID
  - cdp_url: The CDP WebSocket URL for connection
  """
  def create_session(opts \\ []) do
    api_key = Application.fetch_env!(:cua_app, :browserbase)[:api_key]
    project_id = Keyword.get(opts, :project_id) || get_default_project_id()

    connection = build_connection(api_key)

    # Create session params as a map, excluding nil values
    session_params =
      %{
        projectId: project_id,
        timeout: Keyword.get(opts, :timeout),
        keepAlive: Keyword.get(opts, :keep_alive, false),
        region: Keyword.get(opts, :region)
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    case Default.sessions_create(connection, session_params) do
      {:ok, response} ->
        session_info = %{
          session_id: response.id,
          cdp_url: extract_cdp_url(response.connectUrl),
          connect_url: response.connectUrl,
          status: response.status,
          created_at: response.createdAt
        }

        {:ok, session_info}

      {:error, error} ->
        {:error, "Failed to create Browserbase session: #{inspect(error)}"}
    end
  end

  @doc """
  Retrieves information about an existing session.

  ## Parameters
  - session_id: The session ID to query

  ## Returns
  {:ok, session} or {:error, reason}
  """
  def get_session(session_id) do
    api_key = Application.fetch_env!(:cua_app, :browserbase)[:api_key]
    connection = build_connection(api_key)

    case Default.sessions_get(connection, session_id) do
      {:ok, session} -> {:ok, session}
      {:error, error} -> {:error, "Failed to get session: #{inspect(error)}"}
    end
  end

  @doc """
  Updates a session's status (e.g., to complete it).

  ## Parameters
  - session_id: The session ID
  - update_params: SessionUpdate struct with status change

  ## Returns
  {:ok, session} or {:error, reason}
  """
  def update_session(session_id, update_params) do
    api_key = Application.fetch_env!(:cua_app, :browserbase)[:api_key]
    connection = build_connection(api_key)

    case Default.sessions_update(connection, session_id, update_params) do
      {:ok, session} -> {:ok, session}
      {:error, error} -> {:error, "Failed to update session: #{inspect(error)}"}
    end
  end

  @doc """
  Gets live debug URLs for a session.

  ## Parameters
  - session_id: The session ID

  ## Returns
  {:ok, live_urls} or {:error, reason}
  """
  def get_debug_urls(session_id) do
    api_key = Application.fetch_env!(:cua_app, :browserbase)[:api_key]
    connection = build_connection(api_key)

    case Default.sessions_get_debug(connection, session_id) do
      {:ok, urls} -> {:ok, urls}
      {:error, error} -> {:error, "Failed to get debug URLs: #{inspect(error)}"}
    end
  end

  defp build_connection(api_key) do
    # Build middleware with API key header (Browserbase uses X-BB-API-Key)
    middleware =
      Connection.middleware() ++ [{Tesla.Middleware.Headers, [{"X-BB-API-Key", api_key}]}]

    # Create Tesla client with middleware and adapter
    Tesla.client(middleware, Connection.adapter())
  end

  defp extract_cdp_url(connect_url) when is_binary(connect_url) do
    connect_url
  end

  defp extract_cdp_url(%{"connectUrl" => url}), do: url
  defp extract_cdp_url(_), do: nil

  defp get_default_project_id do
    Application.fetch_env!(:cua_app, :browserbase)[:project_id] ||
      raise "BROWSERBASE_PROJECT_ID must be set in config or passed as option"
  end
end
