# 07 — Working with Docker Hub

Docker Hub is the default public registry.
Anyone can pull public images; you need an account to push your own.

---

## Pull a custom image

```bash
docker pull codexchangee/mysite:latest
```

Format: `docker pull <username>/<repository>:<tag>`

---

## Run a public image directly

Docker auto-pulls the image if not already local:

```bash
docker run -dit --name con5 codexchangee/mysite:latest
docker run -dit --name con5 -p 8080:80 codexchangee/mysite:latest
```

---

## Log in to Docker Hub

```bash
docker login
# enter your Docker Hub username and password/token
```

---

## Tag and push your own image

```bash
# Tag local image for Docker Hub
docker tag mysite:v1 ganesh928k/mysite:v1

# Push to Docker Hub
docker push ganesh928k/mysite:v1
```

---

## Official vs Community images

| Type | Example | Trust level |
|---|---|---|
| Official | `httpd`, `nginx`, `ubuntu` | ✅ Maintained by Docker/vendors |
| Verified Publisher | `bitnami/nginx` | ✅ Verified company |
| Community | `username/imagename` | ⚠️ Review before using |

> **Tip:** For production, always prefer Official or Verified Publisher images.
