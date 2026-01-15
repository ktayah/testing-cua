# CuaApp - Computer Use Anthropic with Browserbase

An Elixir application for browser automation using Anthropic's Claude Computer Use API with Browserbase.

## Features

- Long-running GenServer-based agent architecture
- Integration with Anthropic's Computer Use API (claude-3-5-sonnet-20241022)
- Browserbase session management with CDP support
- Agentic loop for autonomous task completion
- Configurable iteration limits and session parameters

## Prerequisites

- Elixir 1.18 or higher
- Anthropic API key
- Browserbase API key and project ID

## Setup

### 1. Install Dependencies

```bash
cd cua_app
mix deps.get
```

### 2. Configure Environment Variables

Add the following to the `.env` file in the parent directory:

```bash
ANTHROPIC_API_KEY=sk-ant-api03-...
BROWSERBASE_API_KEY=your_browserbase_key
BROWSERBASE_PROJECT_ID=your_project_id

# Optional configuration
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
MAX_TOKENS=4096
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
DISPLAY_NUMBER=1
```

### 3. Compile the Application

```bash
mix compile
```

## Usage

### Start IEx Shell

```bash
iex -S mix
```

### Execute a Task

```elixir
# Simple task
CuaApp.run("Go to example.com and take a screenshot")

# Task with options
CuaApp.run(
  "Navigate to google.com, search for 'Elixir programming', and click the first result",
  max_iterations: 30,
  browserbase_opts: [
    project_id: "proj_123",
    timeout: 600,
    keep_alive: true
  ]
)

# Check agent status
CuaApp.status()

# Stop the agent
CuaApp.stop()
```

### Example: Form Filling

```elixir
task = """
Navigate to https://example.com/contact-form
Fill out the form with:
- Name: John Doe
- Email: john@example.com
- Message: Hello from the CUA agent!
Click the submit button and wait for confirmation.
"""

CuaApp.run(task)
```

## Architecture

```
CuaApp
├── Application (Supervisor)
│   └── Agent (GenServer)
│       ├── BrowserbaseManager (Session management)
│       └── Anthropix Client (Anthropic API)
└── config/ (Elixir configuration)
```

### Key Modules

- **CuaApp** - Main interface for running tasks
- **CuaApp.Agent** - GenServer that manages the agentic loop
- **CuaApp.BrowserbaseManager** - Handles Browserbase session lifecycle
- **CuaApp.Application** - Application supervisor

## How It Works

1. **Session Creation**: Agent creates a Browserbase session with CDP enabled
2. **Initial Prompt**: Sends task description to Claude with computer use tools
3. **Agentic Loop**:
   - Claude analyzes the task and decides on actions
   - Agent executes tool calls (computer actions)
   - Results are sent back to Claude
   - Loop continues until task completion or max iterations
4. **Completion**: Final response is returned to the caller

## Configuration

### Agent Options

- `max_iterations` - Maximum number of loop iterations (default: 50)
- `browserbase_opts` - Browserbase session options
  - `project_id` - Your Browserbase project ID
  - `timeout` - Session timeout in seconds
  - `keep_alive` - Keep session alive after completion
  - `region` - Preferred region for the browser

### Display Settings

Customize the virtual display resolution for the computer use tool:

```bash
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
DISPLAY_NUMBER=1
```

### Configuration System

The application uses standard Elixir configuration management:

- **config/config.exs** - Base configuration that imports environment-specific configs
- **config/dev.exs** - Development environment configuration
- **config/test.exs** - Test environment configuration
- **config/prod.exs** - Production environment configuration
- **config/runtime.exs** - Runtime configuration that loads environment variables from `.env`

Environment variables are loaded at runtime from the `.env` file in the parent directory. Configuration is accessed via `Application.fetch_env!/2` and `Application.get_env/3` throughout the codebase.

## Troubleshooting

### "ANTHROPIC_API_KEY environment variable not set"

Ensure your `.env` file is in the parent directory (`testing-cua/.env`) and contains your API key.

### "BROWSERBASE_PROJECT_ID must be set"

Add `BROWSERBASE_PROJECT_ID` to your `.env` file or pass it as an option:

```elixir
CuaApp.run(task, browserbase_opts: [project_id: "proj_your_id"])
```

### Agent reaches max iterations

Increase the `max_iterations` parameter if your task is complex:

```elixir
CuaApp.run(task, max_iterations: 100)
```

## Development

### Run Tests

```bash
mix test
```

### Generate Documentation

```bash
mix docs
```

### Format Code

```bash
mix format
```

