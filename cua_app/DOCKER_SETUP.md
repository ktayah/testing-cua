# Docker Adapter Setup Guide

This guide explains how to use the Docker adapter for local computer use with CuaApp, as an alternative to Browserbase.

## Overview

CuaApp supports two browser adapters:

- **Browserbase** (`:browserbase`) - Cloud-based browser sessions (default)
- **Docker** (`:docker`) - Local Docker containers with Chrome and CDP

## Why Use Docker Adapter?

- **Local Development**: Test without cloud dependencies
- **Cost Savings**: No API costs for development/testing
- **Privacy**: All browser activity stays local
- **Debugging**: Direct VNC access to see what the agent is doing
- **Offline Work**: Works without internet (except for Anthropic API)

## Prerequisites

### 1. Install Docker

**macOS**:
```bash
brew install --cask docker
# Or download from https://www.docker.com/products/docker-desktop
```

**Linux**:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

**Windows**:
Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)

### 2. Verify Docker Installation

```bash
docker --version
docker-compose --version
docker ps  # Should not error
```

## Quick Start

### Method 1: Using Docker Compose (Recommended)

1. **Build and start the container**:
   ```bash
   cd cua_app
   docker-compose up -d
   ```

2. **Configure environment**:
   Add to `.env`:
   ```bash
   BROWSER_ADAPTER=docker
   ```

3. **Run your task**:
   ```bash
   iex -S mix
   ```
   ```elixir
   CuaApp.run("Navigate to google.com and search for Elixir")
   ```

4. **Stop the container**:
   ```bash
   docker-compose down
   ```

### Method 2: Automatic Container Management

Let CuaApp manage containers automatically:

1. **Build the image** (one-time):
   ```bash
   cd cua_app
   docker build -t cua_computer_use .
   ```

2. **Configure environment**:
   Add to `.env`:
   ```bash
   BROWSER_ADAPTER=docker
   DOCKER_REMOVE_ON_EXIT=true  # Auto-cleanup containers
   ```

3. **Run tasks**:
   ```elixir
   # Container is created automatically
   CuaApp.run("Your task here")
   # Container is removed after task completes
   ```

## Configuration

### Environment Variables

Add these to your `.env` file:

```bash
# Adapter selection
BROWSER_ADAPTER=docker              # Use Docker instead of Browserbase

# Docker configuration
DOCKER_CDP_PORT=9222                # Chrome DevTools Protocol port
DOCKER_VNC_PORT=5900                # VNC port for debugging
DOCKER_CONTAINER_NAME=cua_browser_main
DOCKER_REMOVE_ON_EXIT=true          # Auto-remove containers when done

# Display settings (same as Browserbase)
DISPLAY_WIDTH=1920
DISPLAY_HEIGHT=1080
DISPLAY_NUMBER=1
```

### Runtime Configuration

Alternatively, configure in `config/runtime.exs`:

```elixir
config :cua_app, :browser_adapter, :docker

config :cua_app, :docker,
  cdp_port: 9222,
  vnc_port: 5900,
  container_name: "cua_browser_main",
  remove_on_exit: true
```

### Per-Task Configuration

You can also specify the adapter per task:

```elixir
# Use Docker for this specific task
CuaApp.run("Your task", adapter: :docker)

# Use Browserbase for this task
CuaApp.run("Your task", adapter: :browserbase, browserbase_opts: [project_id: "..."])

# Docker with custom options
CuaApp.run("Your task",
  adapter: :docker,
  docker_opts: [
    cdp_port: 9223,
    vnc_port: 5901,
    container_name: "my_custom_browser"
  ]
)
```

## Usage Examples

### Basic Usage

```elixir
# Start IEx
iex -S mix

# Run a task with Docker adapter
CuaApp.run("Navigate to github.com and search for 'elixir'")
```

### With Docker Options

```elixir
CuaApp.run(
  "Fill out the contact form on example.com",
  adapter: :docker,
  max_iterations: 30,
  docker_opts: [
    container_name: "contact_form_test",
    remove_on_exit: false  # Keep container for inspection
  ]
)
```

### Multiple Concurrent Sessions

```elixir
# Each task gets its own container
Task.async(fn -> CuaApp.run("Task 1", adapter: :docker, docker_opts: [cdp_port: 9222]) end)
Task.async(fn -> CuaApp.run("Task 2", adapter: :docker, docker_opts: [cdp_port: 9223]) end)
```

## Debugging

### View Live Browser Activity (VNC)

While a task is running, connect via VNC to see what the agent is doing:

**macOS**:
```bash
open vnc://localhost:5900
# Password: secret
```

**Linux**:
```bash
vncviewer localhost:5900
# Or use Remmina, TigerVNC, etc.
```

**Windows**:
Use RealVNC, TightVNC, or similar. Connect to `localhost:5900`

### Inspect CDP Endpoint

```bash
# View available CDP targets
curl http://localhost:9222/json

# View Chrome version
curl http://localhost:9222/json/version
```

### View Container Logs

```bash
# With docker-compose
docker-compose logs -f

# Direct docker
docker logs -f cua_browser_main
```

### Access Container Shell

```bash
docker exec -it cua_browser_main /bin/bash
```

## Container Management

### List Running Containers

```elixir
CuaApp.DockerManager.list_containers()
```

### Stop a Container

```elixir
CuaApp.DockerManager.stop_container("container_id_or_name")
```

### Cleanup Stopped Containers

```elixir
CuaApp.DockerManager.cleanup_stopped_containers()
```

### Manual Container Control

```bash
# List all CUA containers
docker ps -a --filter name=cua_browser

# Stop all CUA containers
docker stop $(docker ps -q --filter name=cua_browser)

# Remove all stopped CUA containers
docker rm $(docker ps -aq --filter name=cua_browser)

# Force remove all CUA containers
docker rm -f $(docker ps -aq --filter name=cua_browser)
```

## Docker vs Browserbase Comparison

| Feature | Docker | Browserbase |
|---------|--------|-------------|
| **Setup** | Build image locally | Just API key |
| **Cost** | Free (uses local resources) | Pay per session |
| **Speed** | Fast (local) | Network latency |
| **Privacy** | Completely local | Cloud-based |
| **Debugging** | VNC access | Debug URLs |
| **Resources** | Uses local CPU/RAM | Cloud resources |
| **Scalability** | Limited by local machine | Unlimited |
| **Dependencies** | Docker required | Internet only |
| **Best For** | Development, testing | Production, scale |

## Troubleshooting

### Error: "Cannot connect to Docker daemon"

```bash
# Start Docker Desktop (macOS/Windows)
# Or start Docker service (Linux)
sudo systemctl start docker

# Check Docker is running
docker ps
```

### Error: "Port already in use"

Another container is using the ports. Either stop it or use different ports:

```elixir
CuaApp.run("Task", docker_opts: [cdp_port: 9223, vnc_port: 5901])
```

### Error: "Image not found"

Build the image:
```bash
cd cua_app
docker build -t cua_computer_use .
```

### Container Keeps Exiting

Check logs:
```bash
docker logs cua_browser_main
```

### Chrome Not Starting

Increase wait time in `DockerManager`:
```elixir
# In docker_manager.ex, increase @max_wait_time
@max_wait_time 60_000  # 60 seconds
```

### Out of Disk Space

Remove old images and containers:
```bash
# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove everything (careful!)
docker system prune -a -f
```

## Performance Tips

### 1. Reuse Containers

Set `remove_on_exit: false` for long sessions:

```bash
DOCKER_REMOVE_ON_EXIT=false
```

### 2. Resource Limits

In `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'      # Increase for better performance
      memory: 8G     # Increase for complex pages
```

### 3. Persistent Browser Data

Uncomment volumes in `docker-compose.yml` to cache browser data:

```yaml
volumes:
  - ./browser-data:/home/computeruse/.config/google-chrome
```

## Advanced Configuration

### Custom Dockerfile

Modify `Dockerfile` to add custom tools or extensions:

```dockerfile
# Add after Chrome installation
RUN apt-get install -y your-custom-tools

# Or install Chrome extensions
COPY my-extension /home/computeruse/.config/google-chrome/extensions/
```

### Custom Startup Script

Modify the startup script in `Dockerfile` to customize Chrome behavior:

```bash
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-data \  # Custom data directory
  --disable-dev-shm-usage \           # Prevent shared memory issues
  --your-custom-flag \
  about:blank
```

## Security Considerations

- Docker containers run with limited privileges
- VNC password is "secret" (change in Dockerfile for production)
- CDP is exposed only on localhost by default
- Consider using Docker networks for isolation
- Don't expose ports publicly without authentication

## Next Steps

- [Main README](README.md) - General CuaApp documentation
- [Configuration Guide](README.md#configuration) - All configuration options
- [Troubleshooting](README.md#troubleshooting) - Common issues
- [Docker Documentation](https://docs.docker.com/) - Official Docker docs

## Support

If you encounter issues:

1. Check Docker is running: `docker ps`
2. Check image exists: `docker images | grep cua`
3. Check logs: `docker logs cua_browser_main`
4. Try rebuilding: `docker build -t cua_computer_use .`
5. Check this guide's troubleshooting section

For Browserbase issues, see the main README.
