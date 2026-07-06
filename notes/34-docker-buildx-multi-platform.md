# 🏗️ 34 — docker buildx & Multi-Platform Builds

> **Session 10 (Bonus)** | Tested on: AlmaLinux 9 | Author: Ganesh

Historically, a Docker image built on an Intel/AMD (`amd64`) machine would only run on `amd64` machines. If you tried to run it on an Apple Silicon Mac or a Raspberry Pi (`arm64`), it would crash.

`docker buildx` solves this by enabling **Multi-Platform Builds**.

---

## What is buildx?

`buildx` is a Docker CLI plugin that extends the `docker build` command with the full feature set of **BuildKit** (Docker's next-generation build engine).

It allows you to:
- Build for multiple architectures simultaneously (e.g., `amd64` and `arm64`)
- Export build cache to external registries
- Run distributed builds across multiple nodes

---

## 1. Enable and Setup Buildx

```bash
# Check if buildx is installed (included in modern Docker Desktop and Docker CE)
docker buildx version

# Create a new builder instance that supports multi-platform
docker buildx create --name mybuilder --use

# Inspect the builder to see supported platforms
docker buildx inspect --bootstrap
```

Sample output:
```text
Platforms: linux/amd64, linux/arm64, linux/riscv64, linux/ppc64le, linux/s390x, linux/386, linux/arm/v7, linux/arm/v6
```

---

## 2. Building a Multi-Platform Image

When you build for multiple platforms, you **must** push the image directly to a registry (like Docker Hub). Docker cannot store a multi-platform manifest in the local image cache easily.

```bash
# Build for AMD64 and ARM64, and push to Docker Hub
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/myapp:latest \
  --push .
```

### How it works:
1. Docker uses QEMU (an emulator) to run the ARM64 build steps on your AMD64 machine (or vice versa).
2. It builds two separate images.
3. It creates a **Manifest List** tying them both to the `yourusername/myapp:latest` tag.
4. It pushes everything to the registry.

---

## 3. Pulling a Multi-Platform Image

When a user runs `docker pull yourusername/myapp:latest`, Docker automatically detects their host architecture and pulls the correct binary.

```bash
# Inspect the manifest of an image on Docker Hub to see its supported architectures
docker manifest inspect nginx:latest | grep architecture
```

---

## 4. BuildKit Secrets (Bonus Feature)

`buildx` also unlocks BuildKit secrets. This is the **only secure way** to use secrets (like GitHub tokens or NPM auth tokens) during the build process without them leaking into the image history.

**Dockerfile:**
```dockerfile
# syntax=docker/dockerfile:1
FROM alpine
# Mount the secret and use it in a single RUN command
RUN --mount=type=secret,id=my_token \
    echo "The secret is $(cat /run/secrets/my_token)" > /tmp/output
```

**Build Command:**
```bash
# Pass the secret from the host environment
docker buildx build --secret id=my_token,src=./token.txt -t secret-app .
```
The file `./token.txt` is temporarily mounted, used, and then securely discarded. It is **never** saved in the image layers.

---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker buildx create --use` | Create and switch to a new builder |
| `docker buildx inspect` | View supported platforms |
| `docker buildx build --platform linux/amd64,linux/arm64 --push .` | Build multi-arch and push |
| `docker manifest inspect <image>` | View multi-arch manifest details |
| `RUN --mount=type=secret,id=token` | Use BuildKit secrets securely |

---

*Navigation:*<br>[&larr; Previous Note](33-docker-best-practices.md)
