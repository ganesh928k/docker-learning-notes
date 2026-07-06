# 16 — Advanced Dockerfile Instructions

While `FROM`, `COPY`, `RUN`, `EXPOSE`, and `CMD` are the core instructions, Docker provides several advanced instructions to make your images more robust, configurable, and secure.

---

## 1. WORKDIR — The Working Directory

`WORKDIR` sets the working directory for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, and `ADD` instructions that follow it. If the directory doesn't exist, Docker will create it for you.

> [!TIP]
> **Best Practice:** Always use `WORKDIR` instead of `RUN cd /some/path`. The `cd` command in a `RUN` instruction only applies to that specific layer!

**Example:**
```dockerfile
FROM node:14
# Set the working directory
WORKDIR /app

# Now COPY operates inside /app
COPY package*.json ./
RUN npm install
COPY . .
```

---

## 2. ENV — Environment Variables

`ENV` allows you to set environment variables inside the container. These variables are available to subsequent instructions in the Dockerfile and are baked into the final image (so applications can read them at runtime).

**Example:**
```dockerfile
FROM eclipse-temurin:11-jdk

# Define a custom environment variable
ENV apparea=/data/app

# Use the variable in the build process
RUN mkdir -p ${apparea}
WORKDIR ${apparea}
```

---

## 3. ADD — Fetching Remote Files

`ADD` is similar to `COPY`, but it has two extra features:
1. It can download files directly from a **URL**.
2. It can automatically extract **local tarballs** (e.g., `.tar.gz`) into the image.

> [!WARNING]
> **Best Practice:** Docker recommends using `COPY` over `ADD` for copying local files because `COPY` is more transparent. Only use `ADD` when you explicitly need to fetch a URL or auto-extract an archive.

**Example: Downloading Jenkins**
```dockerfile
FROM eclipse-temurin:11-jdk
ENV apparea=/data/app
RUN mkdir -p ${apparea}

# Download the Jenkins WAR file directly from the internet
ADD https://get.jenkins.io/war/2.397/jenkins.war ${apparea}/jenkins.war
```

---

## 4. LABEL — Metadata

`LABEL` allows you to add key-value metadata to your image. This is highly useful for organizing images, documenting the author, marking the environment, or defining versioning.

**Example:**
```dockerfile
FROM eclipse-temurin:11-jdk

LABEL maintainer="ganesh@example.com"
LABEL version="1.0"
LABEL env="production"
```
You can view these labels later using the `docker inspect` command.

*(Note: The older `MAINTAINER` instruction is deprecated. Always use `LABEL` instead).*

---

## 5. ENTRYPOINT vs CMD

While both `CMD` and `ENTRYPOINT` specify what command runs when a container starts, they behave slightly differently when you pass arguments via `docker run`:

- **`CMD`**: Easily overridden. If a user runs `docker run myimage bash`, the `CMD` is ignored, and `bash` is executed instead.
- **`ENTRYPOINT`**: Harder to override. Arguments passed in `docker run` are **appended** to the `ENTRYPOINT`.

**Common Pattern:** Use `ENTRYPOINT` for the core executable, and `CMD` for default flags.
```dockerfile
FROM ubuntu
ENTRYPOINT ["ping"]
CMD ["-c", "3", "8.8.8.8"]
```
If you run `docker run myimage`, it pings `8.8.8.8` three times.
If you run `docker run myimage google.com`, it pings `google.com`!


---

## 6. ARG — Build-Time Variables

`ARG` defines a variable that is **only available during the build process** — it does NOT persist into the final image or running container. This makes it ideal for build-time configuration without leaking secrets into the image.

> [!IMPORTANT]
> **`ARG` vs `ENV`:**
> - `ARG` = build-time only (gone after build, invisible in `docker inspect`)
> - `ENV` = persists into the image and is visible at runtime and in `docker inspect`

**Example:**
```dockerfile
FROM node:18-alpine

# Build-time variable with a default value
ARG NODE_ENV=production

# Build-time variable without a default (must be supplied at build)
ARG BUILD_VERSION

# Promote ARG to ENV if you need it at runtime too
ENV NODE_ENV=${NODE_ENV}

WORKDIR /app
COPY package*.json ./
RUN echo "Building version: ${BUILD_VERSION}" && npm ci
COPY . .
CMD ["node", "app.js"]
```

```bash
# Pass ARG values at build time with --build-arg
docker build \
  --build-arg NODE_ENV=development \
  --build-arg BUILD_VERSION=1.2.3 \
  -t myapp:dev .

# ARG is NOT visible in the final image
docker inspect myapp:dev | grep BUILD_VERSION   # empty — it's gone
```

> [!CAUTION]
> Never use `ARG` to pass secrets (passwords, tokens) — they appear in `docker history` and the build cache. Use Docker secrets or BuildKit's `--mount=type=secret` for that.

---

## 7. HEALTHCHECK — Container Health Monitoring

`HEALTHCHECK` tells Docker how to test if a container is actually healthy — not just running. Docker uses this to report `healthy` / `unhealthy` status and to implement `depends_on: condition: service_healthy` in Compose.

```dockerfile
FROM nginx:alpine

COPY ./html /usr/share/nginx/html

# HEALTHCHECK syntax:
# HEALTHCHECK [OPTIONS] CMD <command>
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

| Option | Default | Meaning |
|---|---|---|
| `--interval` | `30s` | How often to run the check |
| `--timeout` | `30s` | Max time a check can take |
| `--start-period` | `0s` | Grace period before failures count |
| `--retries` | `3` | Failures before marking unhealthy |

```bash
# Build and run
docker build -t healthy-nginx .
docker run -d --name web healthy-nginx

# Check health status
docker ps                           # shows STATUS column: (healthy)
docker inspect web | grep -A 8 '"Health"'
```

Health states:
```
starting   → within start-period, failures not counted yet
healthy    → check passing
unhealthy  → retries exhausted, check still failing
```

> [!TIP]
> Always add `HEALTHCHECK` to images deployed in Swarm or Compose with `depends_on: condition: service_healthy`. Without it, Docker considers the container healthy as soon as the process starts — even if the app is still initializing.

---

## Dockerfile Instruction Summary

| Instruction | Build-time | Runtime | Purpose |
|---|---|---|---|
| `FROM` | ✅ | — | Base image |
| `COPY` | ✅ | — | Copy files from host |
| `ADD` | ✅ | — | Copy + download URLs + extract tars |
| `RUN` | ✅ | — | Execute shell command |
| `EXPOSE` | ✅ | ℹ️ | Document port (informational) |
| `WORKDIR` | ✅ | ✅ | Set working directory |
| `ENV` | ✅ | ✅ | Environment variable (persists in image) |
| `ARG` | ✅ | ❌ | Build-time variable (gone after build) |
| `LABEL` | ✅ | ✅ | Metadata (author, version, etc.) |
| `CMD` | — | ✅ | Default command (overrideable) |
| `ENTRYPOINT` | — | ✅ | Core executable (args appended) |
| `HEALTHCHECK` | ✅ | ✅ | Health monitoring command |

---

*Navigation:*<br>[&larr; Previous Note](15-namespaces-pid-uts-ipc-user.md) | [Next Note &rarr;](17-practical-app-deployments.md)
