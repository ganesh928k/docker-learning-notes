# 🐙 28 — Docker Compose Advanced Commands

> **Session 7 (Advanced Compose)** | Tested on: AlmaLinux 9 | Author: Ganesh

Beyond `up`, `down`, and `ps` — Docker Compose has a rich set of commands for inspecting, managing, and debugging multi-container applications. This note covers every command practised in the lab.

---

## 🔧 Docker Compose Advanced Command Reference

### Project State

```bash
# List running compose services in current project
docker compose ps

# List ALL compose projects on this host
docker compose ls

# Validate and print the final resolved compose config
docker compose config

# Print compose and docker versions
docker compose version
```

---

### Images & Containers

```bash
# List images used by the compose project
docker compose images

# Export a container's filesystem as a tar archive
docker compose export wordpress > wordpress.tar

# Commit a service container to a new image
docker compose commit wordpress mywordpress:v1
docker compose images   # Verify new image appears

# Copy files between host and a service container
docker compose cp my.txt wordpress:/var/www/html   # Host → Container
docker compose cp wordpress:/var/www/html ./html   # Container → Host
```

---

### Process Inspection

```bash
# Show running processes inside all service containers (like top)
docker compose top

# Show resource usage (CPU, memory, net I/O) — non-streaming snapshot
docker compose stats

# Watch compose services for file changes and auto-rebuild
docker compose watch
```

---

### Lifecycle Control

```bash
# Kill a specific service (SIGKILL — no graceful shutdown)
docker compose kill wordpress

# Stop services gracefully, then remove containers + networks
docker compose down

# Stop and also remove named volumes
docker compose down -v

# Remove stopped service containers
docker compose rm

# Wait for a service to complete (exit 0 = success, exit 1 = failure)
docker compose wait wordpress

# Push service images to registry
docker compose push
```

---

### Logs & Events

```bash
# Follow real-time logs from all services
docker compose logs -f

# Follow logs from a specific service
docker compose logs -f wordpress

# Stream Docker events for this compose project
docker compose events

# Example output of docker compose events:
# 2026-06-24T12:40:15+05:30 container start wordpress (image=wordpress:latest ...)
# 2026-06-24T12:40:16+05:30 container start db (image=mysql:8.0 ...)
```

---

### Scaling & Building

```bash
# Scale a service while running
docker compose up -d --scale app=3

# Build images before starting
docker compose up --build -d

# Scale multiple services
docker compose up -d --build --scale app1=3 --scale app2=3
```

---

## 🏥 Health Checks in Docker Compose

Health checks let Docker know when a container is actually **ready to serve traffic** — not just started. This prevents race conditions where `nginx` starts before `app` is ready.

### docker-compose.yml with Health Checks

```yaml
version: '3.8'

services:
  app1:
    build: ./app
    networks:
      - mynetwork
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s

  app2:
    build: ./app
    networks:
      - mynetwork
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 10s
      timeout: 5s
      retries: 3

  nginx:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      app1:
        condition: service_healthy    # ← Wait until app1 passes health check
      app2:
        condition: service_healthy    # ← Wait until app2 passes health check
    networks:
      - mynetwork

networks:
  mynetwork:
```

### Health Check Parameters

| Parameter | Meaning | Default |
|---|---|---|
| `test` | Command to run | None (required) |
| `interval` | How often to check | `30s` |
| `timeout` | Max time for check | `30s` |
| `retries` | Failures before unhealthy | `3` |
| `start_period` | Grace period before counting failures | `0s` |

### Health Check States

```
starting  → Container just started, start_period grace period
healthy   → Health check passing
unhealthy → Failing retries exhausted
```

```bash
# View health status
docker compose ps
# NAME        COMMAND     STATUS    PORTS
# app1        ...         healthy   (no ports — internal)
# app2        ...         healthy
# nginx       ...         running   0.0.0.0:8080->80/tcp

# Inspect detailed health
docker inspect app1 | grep -A 10 Health
```

### Application Health Endpoint (Flask)

```python
from flask import Flask
import socket

app = Flask(__name__)

@app.route("/")
def home():
    return f"Hello from {socket.gethostname()}!"

@app.route("/health")
def health():
    return "OK", 200   # ← Health check endpoint

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

---

## ⚖️ Load Balancing with Health Checks

The full architecture used in the lab — two Flask apps, one Nginx reverse proxy, with health checks preventing traffic before apps are ready:

### nginx.conf

```nginx
events {}

http {
    upstream backend {
        server app1:5000;
        server app2:5000;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
}
```

### Full Working Commands

```bash
# Build and start all services — Nginx waits for app health checks
docker compose up --build -d

# Verify health
docker compose ps

# Test load balancing — hostname changes each request
curl http://localhost:8080  # → "Hello from abc123!" (app1)
curl http://localhost:8080  # → "Hello from def456!" (app2)

# Scale app to 3 instances
docker compose up -d --scale app1=3

# Reload nginx to pick up new upstreams
docker exec nginx-lb nginx -s reload

# View logs
docker compose logs -f

# View processes in each container
docker compose top

# Monitor resources
docker compose stats

# Teardown
docker compose down
```

---

## 🔄 Sticky Sessions

If your app requires a user to always reach the **same backend** (sessions, file uploads, etc.), use Nginx `ip_hash`:

```nginx
upstream backend {
    ip_hash;   # ← Client IP → always same backend
    server app1:5000;
    server app2:5000;
}
```

> [!NOTE]
> Sticky sessions break true load balancing. For stateful apps, prefer **shared session storage** (Redis, database) rather than sticky sessions — it scales better.

---

## ⚡ Quick Reference — All Compose Commands

```bash
# State
docker compose ps            # Running services
docker compose ls            # All projects
docker compose config        # Validated config
docker compose version       # Version info

# Run
docker compose up -d         # Start detached
docker compose up --build -d # Build then start
docker compose down          # Stop + remove
docker compose down -v       # Also remove volumes

# Debug
docker compose logs -f       # Follow all logs
docker compose top           # Running processes
docker compose stats         # Resource usage
docker compose events        # Event stream

# Files
docker compose cp src dest   # Copy files
docker compose export svc    # Export filesystem

# Images
docker compose images        # List used images
docker compose push          # Push to registry
docker compose commit svc    # Commit to image

# Misc
docker compose kill svc      # Force kill
docker compose rm            # Remove stopped
docker compose wait svc      # Wait for exit
docker compose watch         # Auto-rebuild on change
```

---

> [!TIP]
> **Next:** [29 — Docker Secrets (Sensitive Data Management)](29-docker-secrets.md)

---

*← [27 — Container Privilege Escalation](27-container-privilege-escalation.md) | [29 — Docker Secrets →](29-docker-secrets.md)*
