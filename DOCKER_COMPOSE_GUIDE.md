# Docker Compose Guide - CUA Testing Environment

This docker-compose setup runs both the CUA browser container and the challenge website together.

## Services

### 1. cua-browser
- **Container:** `cua_browser_main`
- **Image:** `cua_computer_use`
- **Ports:**
  - `9222` - Chrome DevTools Protocol (CDP)
  - `5900` - VNC for visual debugging
- **Resources:** Up to 2 CPU cores, 4GB RAM

### 2. cua-challenge (NEW)
- **Container:** `cua_challenge_web`
- **Image:** `cua-challenge`
- **Ports:**
  - `8080` - Web interface for challenge
- **Resources:** Up to 0.5 CPU cores, 256MB RAM

Both services are connected via the `cua-network` bridge network, allowing them to communicate.

## Quick Commands

### Start all services
```bash
docker-compose up -d
```

### Start specific service
```bash
# Only browser
docker-compose up -d cua-browser

# Only challenge
docker-compose up -d cua-challenge
```

### Build and start
```bash
docker-compose up -d --build
```

### Stop all services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f cua-browser
docker-compose logs -f cua-challenge
```

### Restart a service
```bash
docker-compose restart cua-browser
docker-compose restart cua-challenge
```

### Check status
```bash
docker-compose ps
```

## Access Points

Once running, you can access:

- **Challenge Website:** http://localhost:8080
- **Browser CDP:** ws://localhost:9222
- **Browser VNC:** vnc://localhost:5900

## Testing Your Agent

With both services running:

1. Your agent connects to the browser via CDP (port 9222)
2. The agent navigates to the challenge at `http://cua_challenge_web:80` (internal network) or `http://localhost:8080` (from host)
3. The agent completes the 4-page challenge

### From Inside the Browser Container

The challenge website is accessible at:
```
http://cua-challenge  # Service name DNS resolution
http://cua_challenge_web:80  # Container name
```

### From Host Machine

The challenge website is accessible at:
```
http://localhost:8080
```

## Agent Configuration

When configuring your Elixir agent to test against the challenge:

```elixir
# In your agent code, navigate to:
task = "Navigate to http://cua-challenge and complete the form challenge"

# Or if testing from host:
task = "Navigate to http://localhost:8080 and complete the form challenge"
```

## Persistent Containers

To keep containers running between sessions, uncomment the `restart` lines:

```yaml
restart: unless-stopped
```

## Resource Adjustment

Modify the `deploy.resources` sections if you need to adjust CPU/memory limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'      # Maximum CPUs
      memory: 4G     # Maximum RAM
    reservations:
      cpus: '1'      # Guaranteed CPUs
      memory: 2G     # Guaranteed RAM
```

## Troubleshooting

### Port conflicts
If ports 8080, 9222, or 5900 are already in use:

```yaml
ports:
  - "8081:80"  # Change 8080 to 8081
```

### Container won't start
```bash
# Check logs
docker-compose logs cua-challenge

# Rebuild from scratch
docker-compose down
docker-compose up -d --build
```

### Network issues
```bash
# Recreate network
docker-compose down
docker network prune
docker-compose up -d
```

## Development Workflow

### Update challenge website
```bash
# Edit files in cua_challenge/
cd cua_challenge
# ... make changes ...

# Rebuild and restart
cd ..
docker-compose up -d --build cua-challenge
```

### Test browser manually
```bash
# Start services
docker-compose up -d

# View browser via VNC
# Connect VNC client to localhost:5900

# Or access via CDP
# Connect CDP client to localhost:9222
```

## Clean Up

### Remove all containers and images
```bash
docker-compose down --rmi all

# Or keep images
docker-compose down
```

### Remove volumes (if using)
```bash
docker-compose down -v
```

## Example: Full Testing Session

```bash
# 1. Start both services
docker-compose up -d

# 2. Wait for services to be ready
sleep 2

# 3. Check status
docker-compose ps

# 4. Run your Elixir agent
cd cua_app
mix run -e "CuaApp.Agent.execute_task(\"Navigate to http://cua-challenge and complete all form pages\")"

# 5. Check challenge website manually
open http://localhost:8080

# 6. View logs if needed
docker-compose logs -f

# 7. Stop when done
docker-compose down
```

## Integration with Elixir App

Your Elixir app can use the internal Docker network to access the challenge:

```elixir
# config/config.exs
config :cua_app,
  challenge_url: System.get_env("CHALLENGE_URL", "http://cua-challenge")

# Or use localhost when testing from host machine
config :cua_app,
  challenge_url: System.get_env("CHALLENGE_URL", "http://localhost:8080")
```

## Notes

- The challenge website is stateless (uses browser sessionStorage)
- Each browser session starts fresh
- The browser container includes Chrome with CDP enabled
- Both containers share the same Docker network for easy communication
- The challenge container is very lightweight (~25MB)

---

**Ready to test?** Run `docker-compose up -d` and visit http://localhost:8080 🚀
