# ⚡ Docker Quick Cheat Sheet

> All essential Docker commands in one place.

---

## 🖼️ Images

```bash
docker pull nginx:latest          # Download image
docker images                     # List local images
docker image ls                   # Same as above
docker search nginx               # Search Docker Hub
docker image history nginx        # Show image layers
docker rmi nginx                  # Remove image
docker rmi $(docker images -q)    # Remove ALL images (careful!)
```

---

## 📦 Run Containers

```bash
docker run nginx                          # Run (foreground, auto-removed when stopped)
docker run -d nginx                       # Run in background (detached)
docker run -it ubuntu bash                # Interactive shell
docker run -dit --name web nginx          # Background + attachable, named
docker run -d --name web -p 8080:80 nginx # With port mapping
docker run -d --rm nginx                  # Auto-delete on stop
```

---

## 📋 List & Inspect

```bash
docker ps                    # Running containers
docker ps -a                 # All containers (incl. stopped)
docker inspect web           # Full container details (JSON)
docker logs web              # View stdout/stderr logs
docker logs web --follow     # Stream live logs
docker logs web --tail 50    # Last 50 lines
docker stats                 # Live CPU/RAM for all containers
docker stats web             # Live CPU/RAM for one container
```

---

## ▶️ Lifecycle

```bash
docker start web             # Start stopped container
docker stop web              # Graceful stop (SIGTERM)
docker kill web              # Force stop (SIGKILL)
docker restart web           # Stop + start
docker pause web             # Freeze (cgroups)
docker unpause web           # Unfreeze
docker rename web mysite     # Rename container
```

---

## 🔧 Interact

```bash
docker exec -it web bash     # Shell into running container  ← USE THIS
docker attach web            # Attach to main process (Ctrl+P Ctrl+Q to detach safely)
docker cp web:/etc/nginx .   # Copy file out of container
docker cp ./file.conf web:/etc/nginx/  # Copy file into container
```

---

## 🗑️ Remove

```bash
docker rm web                          # Remove stopped container
docker rm -f web                       # Force remove running container
docker rm $(docker ps -a -q)           # Remove ALL stopped containers
docker container prune                 # Same but with confirmation
docker rmi nginx                       # Remove image
docker image prune                     # Remove dangling images
docker system prune                    # Remove everything unused
docker system prune -a                 # Remove everything including unused images
```

---

## 🏗️ Build

```bash
docker image build -t myapp .          # Build from ./Dockerfile
docker image build -t myapp:v2 .       # Build with version tag
docker image build -f custom.dockerfile -t myapp .  # Custom Dockerfile name
```

---

## 🌐 Networking

```bash
docker run -d -p 8080:80 nginx         # Map host:8080 → container:80
docker run -d -p 443:443 -p 80:80 nginx # Multiple ports
docker network ls                       # List networks
docker network inspect bridge           # Inspect default bridge
ip a                                    # Host network interfaces (shows docker0)
```

---

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct |
|---|---|
| `docker run it image` | `docker run -it image` |
| `docker rm all` | `docker container prune` |
| `docker image history` | `docker image history <name>` |
| `ipconfig` (Linux) | `ip a` |
| `dockerfile` | `Dockerfile` (capital D) |
| `docker start <id> -dit` | `docker start -dit <id>` |
