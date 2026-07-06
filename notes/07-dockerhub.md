# 07 — Working with Docker Hub

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

Docker Hub is the world's largest container registry. It hosts **official** images for almost every major technology and allows you to publish your own.

---

## Understanding Image Types

| Type | Example | Trust Level |
|---|---|---|
| **Official** | `nginx`, `ubuntu`, `mysql` | ✅ Maintained by Docker / vendors |
| **Verified Publisher** | `bitnami/nginx` | ✅ Verified company account |
| **Community** | `username/imagename` | ⚠️ Review before using |

> [!TIP] Always prefer **Official** or **Verified Publisher** images in production. Community images are unreviewed.

---

## Searching Docker Hub

```bash
# Basic search
docker search nginx

# Filter to official images only
docker search --filter is-official=true nginx

# Filter by minimum stars (quality signal)
docker search --filter stars=100 python

# Limit results
docker search --limit 5 nginx
```

Sample output:
```
NAME       DESCRIPTION                    STARS    OFFICIAL
nginx      Official build of Nginx        19000    [OK]
unit       Official build of NGINX Unit   100      [OK]
```

---

## Understanding Image Tags

Tags are versions of an image. Always use a specific tag in production — never rely on `:latest`.

```bash
# Pull specific versions
docker pull nginx:latest          # current latest (changes over time!)
docker pull nginx:1.27            # exact version (stable, predictable)
docker pull nginx:1.27-alpine     # alpine variant (smaller, ~7MB)
docker pull ubuntu:22.04          # specific Ubuntu LTS
docker pull python:3.12-slim      # slim = smaller, no extras
```

> [!WARNING]
> `:latest` is **not** the same as "most recently released" — it is whatever the publisher tagged as latest. In CI/CD and production, always pin to a specific version like `nginx:1.27`.

---

## Pull and Run Public Images

```bash
# Pull an image (downloads but does not run)
docker pull codexchangee/mysite:latest

# Run directly — Docker auto-pulls if not local
docker run -dit --name con5 codexchangee/mysite:latest
docker run -dit --name con5 -p 8080:80 codexchangee/mysite:latest
```

---

## Log In and Push Your Own Image

```bash
# Login (use an Access Token, not your password — more secure)
docker login -u ganesh928k
# Enter your Personal Access Token from hub.docker.com → Account Settings → Security

# Tag your local image for Hub
docker tag mysite:v1 ganesh928k/mysite:v1

# Push to Docker Hub
docker push ganesh928k/mysite:v1

# Log out (important on shared machines)
docker logout
```

---

## Docker Hub Rate Limits

Docker Hub throttles unauthenticated pulls:

| Status | Pull Limit |
|---|---|
| **Unauthenticated** | 100 pulls per 6 hours per IP |
| **Free account (logged in)** | 200 pulls per 6 hours |
| **Pro / Team** | Unlimited |

```bash
# Always log in before pulling in CI/CD pipelines to avoid rate limiting
docker login -u ganesh928k --password-stdin < ~/.docker/token.txt
docker pull nginx:latest
```

> [!NOTE]
> If a pipeline fails with "toomanyrequests: Too Many Requests" — you've hit the rate limit. Log in first.

---

## Multi-Architecture Images

Modern images support multiple CPU architectures (AMD64, ARM64 for Apple Silicon / Raspberry Pi). Docker automatically pulls the correct one for your machine.

```bash
# Check what platforms an image supports
docker manifest inspect nginx:latest | grep architecture

# Output shows:
# "architecture": "amd64"
# "architecture": "arm64"
# "architecture": "arm"
```

---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker search nginx` | Search Docker Hub |
| `docker search --filter is-official=true nginx` | Search official only |
| `docker pull nginx:1.27` | Pull specific version |
| `docker pull nginx:alpine` | Pull Alpine variant (small) |
| `docker login -u username` | Log in to Docker Hub |
| `docker logout` | Log out |
| `docker tag myimg:v1 user/myimg:v1` | Tag for Hub |
| `docker push user/myimg:v1` | Push to Hub |
| `docker manifest inspect nginx` | Check supported platforms |

---

*Navigation:*<br>[&larr; Previous Note](06-dockerfile.md) | [Next Note &rarr;](08-cleanup.md)
