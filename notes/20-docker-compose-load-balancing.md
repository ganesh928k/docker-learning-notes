# ⚖️ Docker Compose Scaling & Load Balancing

Scaling applications and distributing traffic are key aspects of containerized environments. Using Docker Compose with a reverse proxy like Nginx is a classic way to achieve this locally.

## 🏗️ Architecture

A typical setup involves:
1. **Application Containers**: Multiple instances of the same service (e.g., a Python/Flask or Node.js app).
2. **Nginx Load Balancer**: A single Nginx container that receives incoming HTTP traffic and routes it to the application containers (often using round-robin).

## 🚀 Scaling with Docker Compose

You don't need to write multiple service definitions in your `docker-compose.yml` to run multiple instances. Use the `--scale` flag instead.

```bash
# Build and start services in the background, scaling 'app1' and 'app2'
docker compose up -d --build --scale app1=3 --scale app2=3

# Scale an existing service up or down dynamically
docker compose up -d --scale app1=5
```

## 🔄 Live Reloading Nginx Configuration

If you update your `nginx.conf` file to change routing rules or add new upstream servers, you **do not** need to restart the Nginx container (which would cause downtime). Instead, you can reload the configuration dynamically using `docker exec`:

```bash
# Test the new nginx configuration for syntax errors
docker exec nginx-lb nginx -t

# Reload nginx gracefully without dropping connections
docker exec nginx-lb nginx -s reload
```

## 📝 Example `docker-compose.yml`

```yaml
version: '3.8'

services:
  app:
    build: ./app
    # Notice: We don't map ports here to the host, 
    # as Nginx will handle the external routing.

  nginx-lb:
    image: nginx:latest
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "8080:80"
    depends_on:
      - app
```

## 🔍 Checking Status

```bash
# See all running instances of your scaled services
docker compose ps

# Check the logs of the load balancer to see round-robin in action
docker compose logs -f nginx-lb
```
