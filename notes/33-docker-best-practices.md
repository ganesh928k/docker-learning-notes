# 🌟 33 — Docker Best Practices

> **Session 10 (Bonus)** | Tested on: AlmaLinux 9 | Author: Ganesh

Writing a Dockerfile that works is easy. Writing a Dockerfile that is secure, fast, and production-ready requires discipline. This note synthesizes the best practices learned throughout the repository.

---

## 1. Image Building & Dockerfiles

- **Always use `.dockerignore`**: Never send `.git`, `node_modules`, or `.env` to the Docker daemon. It bloats context and leaks secrets.
- **Use specific tags, avoid `:latest`**: `FROM node:18.17.1-alpine` is reproducible. `FROM node:latest` will break your app when Node 20 is released.
- **Order matters for caching**: Put frequently changing instructions (like `COPY . .`) at the very bottom. Put rarely changing instructions (like `RUN apt-get update`) at the top.
- **Combine `RUN` commands**: Every `RUN` creates a new layer.
  - ❌ `RUN apt-get update` \n `RUN apt-get install -y vim`
  - ✅ `RUN apt-get update && apt-get install -y vim && rm -rf /var/lib/apt/lists/*`
- **Use Multi-Stage Builds**: Never ship compilers or build tools (like `gcc` or `go build`) in your final production image. Use a `builder` stage, then copy the binary to a `scratch` or `alpine` image.

---

## 2. Security

- **Never run as root**: By default, containers run as root. Always create a dedicated user.
  ```dockerfile
  RUN useradd -m appuser
  USER appuser
  ```
- **Never bake secrets in `ENV`**: Use Docker Secrets, Vault, or BuildKit `--mount=type=secret`.
- **Drop capabilities**: Containers run with default privileges. Drop what you don't need.
  ```bash
  docker run --cap-drop ALL --cap-add NET_BIND_SERVICE ...
  ```
- **Use read-only file systems**: Prevent attackers from writing malicious payloads.
  ```bash
  docker run --read-only -v /app/tmp:/tmp ...
  ```
- **Scan your images**: Use `trivy` to scan for CVEs before pushing to a registry.

---

## 3. Container Lifecycle & State

- **Containers must be ephemeral**: You should be able to destroy and recreate a container at any time without losing data.
- **State lives in volumes, not containers**: Databases, uploads, and logs must be stored in Docker Volumes or external services (S3, RDS).
- **One process per container**: Don't run Nginx and MySQL in the same container. Run two containers and link them via a Docker network.
- **Handle signals gracefully**: Your app should catch `SIGTERM` and shut down cleanly instead of waiting for Docker to send `SIGKILL`.

---

## 4. Networking & Configuration

- **Use custom bridge networks**: Never use the default `bridge` network for multi-container apps. Custom bridges provide automatic DNS resolution by container name.
- **Inject configuration via environment variables**: Code should be environment-agnostic. Pass DB URLs, API keys, and log levels via `docker run -e` or `docker-compose.yml`.
- **Implement Health Checks**: Don't rely on the process running. Add a `HEALTHCHECK` to verify the application is actually ready to serve traffic.

---

## ⚡ Quick Checklist for Production

- [ ] `.dockerignore` exists
- [ ] Base image is pinned to a specific version (e.g., `alpine:3.18`)
- [ ] `USER` is set to non-root
- [ ] Secrets are NOT in the Dockerfile
- [ ] `HEALTHCHECK` instruction is present
- [ ] Data is stored in Volumes, not the container filesystem
- [ ] Image scanned for vulnerabilities (e.g., `trivy`)
- [ ] Restrictive restart policy (`--restart unless-stopped` or `on-failure:5`)

---

*Navigation:*<br>[&larr; Previous Note](32-troubleshooting.md) | [Next Note &rarr;](34-docker-buildx-multi-platform.md)
