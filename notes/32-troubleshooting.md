# 🛠️ 32 — Troubleshooting Common Docker Issues

> **Session 10 (Bonus)** | Tested on: AlmaLinux 9 | Author: Ganesh

When running Docker in production or development, you will inevitably hit errors. This note compiles the most common Docker issues and their exact fixes based on real-world troubleshooting.

---

## 1. "Cannot connect to the Docker daemon"

**Error:**
```text
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

**Cause:** The Docker background service (daemon) is not running, or your user lacks permissions.

**Fix:**
```bash
# 1. Check if it's running
systemctl status docker

# 2. Start it if it's dead
sudo systemctl start docker
sudo systemctl enable docker

# 3. If running but still failing, check permissions
sudo usermod -aG docker $USER
newgrp docker
```

---

## 2. Container Keeps Restarting / Exiting

**Error:** Container shows `Restarting (1)` in `docker ps` or keeps disappearing.

**Cause:** The main process inside the container crashed, exited, or threw a fatal error.

**Fix:**
```bash
# 1. Look at the logs for the exact error!
docker logs <container_name>
docker logs -f <container_name>   # tail the logs live

# 2. Inspect the exit code
docker ps -a
# (Exit 1)   = Application crashed
# (Exit 137) = OOM (Out of Memory) Killed by Linux
# (Exit 0)   = Application finished successfully and exited

# 3. If OOM Killed, increase memory limits
docker run -m 512m ...
```

---

## 3. "No space left on device"

**Error:**
```text
docker: Error processing tar file(exit status 1): write /xxx: no space left on device
```

**Cause:** Docker has consumed all available disk space with dangling images, stopped containers, and unused volumes.

**Fix:**
```bash
# 1. Check what is taking up space
docker system df

# 2. Safely prune unused objects
docker system prune

# 3. Aggressively prune ALL unused images (including non-dangling)
docker system prune -a
```

---

## 4. Port Already in Use

**Error:**
```text
Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use.
```

**Cause:** Another process (like Apache, Nginx, or another container) is already using the host port you are trying to map (e.g., `-p 80:80`).

**Fix:**
```bash
# 1. Find what is using the port (requires root)
sudo netstat -tulpn | grep :80

# 2. Stop the conflicting service
sudo systemctl stop httpd

# 3. OR change your container's port mapping
docker run -p 8080:80 ...
```

---

## 5. SELinux Denying Access to Bind Mounts

**Error:**
```text
nginx: [emerg] open() "/usr/share/nginx/html/index.html" failed (13: Permission denied)
```

**Cause:** On RHEL/AlmaLinux, SELinux prevents containers from accessing host files by default.

**Fix:** Append the `:Z` or `:z` flag to the volume mount to apply the correct SELinux context.
```bash
# :Z applies a private, unshared label
docker run -v /host/path:/container/path:Z nginx

# :z applies a shared label (multiple containers can access)
docker run -v /host/path:/container/path:z nginx
```

---

## 6. Docker Hub Rate Limit Reached

**Error:**
```text
toomanyrequests: You have reached your pull rate limit. You may increase the limit by authenticating and upgrading...
```

**Cause:** You are pulling images anonymously, and your IP address hit the 100 pulls / 6 hours limit.

**Fix:**
```bash
# 1. Create a free Docker Hub account
# 2. Log in (increases limit to 200 pulls)
docker login -u yourusername
```

---

## 7. "exec failed: container not running"

**Error:**
```text
OCI runtime exec failed: exec failed: container_linux.go:xxx: starting container process caused... container not running
```

**Cause:** You tried to run `docker exec` on a container that is stopped or crashed.

**Fix:**
```bash
# Check if it is actually running
docker ps -a

# Start it first
docker start <container_name>
docker exec -it <container_name> bash
```

---

## ⚡ Quick Reference

| Issue | Quick Fix |
|---|---|
| Daemon not running | `sudo systemctl start docker` |
| Container crashing | `docker logs <container>` |
| Out of disk space | `docker system prune -a` |
| Port conflict | `sudo netstat -tulpn \| grep :<port>` |
| Permission denied (mount) | Use `:Z` flag on `-v` |
| Rate limited pull | `docker login` |

---

*Navigation:*<br>[&larr; Previous Note](31-conclusion.md) | [Next Note &rarr;](33-docker-best-practices.md)
