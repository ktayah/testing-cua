import Config
import Dotenvy

# Load .env file from parent directory if it exists
env_path = Path.join(["..", ".env"])

case Dotenvy.source(env_path) do
  {:ok, _} -> :ok
  # Silently continue if .env doesn't exist
  {:error, _} -> :ok
end

config :cua_app, CuaApp.Agent,
  width: env!("DISPLAY_WIDTH", :integer?, 1280),
  height: env!("DISPLAY_HEIGHT", :integer?, 800),
  display_number: env!("DISPLAY_NUMBER", :integer?, 1)

# Runtime configuration (loaded at application start)
config :cua_app, :anthropic,
  api_key: env!("ANTHROPIC_API_KEY", :string!),
  model: env!("ANTHROPIC_MODEL", :string!, "claude-haiku-4-5"),
  max_tokens: env!("MAX_TOKENS", :integer?, 12_000)

config :cua_app, :browserbase,
  api_key: env!("BROWSERBASE_API_KEY", :string!),
  project_id: env!("BROWSERBASE_PROJECT_ID", :string!)

# Browser adapter configuration
# Options: :browserbase (cloud) or :docker (local)
config :cua_app, :browser_adapter, env!("BROWSER_ADAPTER", :atom?, :docker)

# Docker adapter configuration (when using :docker adapter)
config :cua_app, :docker,
  cdp_port: env!("DOCKER_CDP_PORT", :integer?, 9222),
  vnc_port: env!("DOCKER_VNC_PORT", :integer?, 5900),
  container_name: env!("DOCKER_CONTAINER_NAME", :string?, "cua_browser_main"),
  remove_on_exit: env!("DOCKER_REMOVE_ON_EXIT", :boolean?, false)
