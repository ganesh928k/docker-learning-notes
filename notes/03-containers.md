# 03 — Docker Containers — Basics

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

A **container** is a running instance of an image. You can run many containers from the same image.

---

## Run modes

### Interactive shell (-it)

```bash
docker run -it almalinux:latest
```

- `-i` — keep STDIN open
- `-t` — allocate a pseudo-terminal (gives you a prompt)

Use this to explore an image or debug.

---

### Background / detached (-d)

```bash
docker run -d --name con1 httpd:latest
```

- `-d` — runs in the background, returns the container ID
- `--name con1` — gives it a friendly name

---

### Background + attachable (-dit)

```bash
docker run -dit --name con1 almalinux:latest
```

Runs in background but keeps a terminal ready so you can `docker attach` later.

---

## List containers

```bash
docker ps          # running only
docker ps -a       # all (including stopped)
```

---

## Enter a running container

```bash
docker exec -it con1 bash
```

Preferred method — starts a **new** shell process inside the container.
Exiting does NOT stop the container.

---

## Attach to main process

```bash
docker attach con1
```

Connects to the container's **primary** process.

> [!WARNING] Pressing `Ctrl+C` here **stops the container**!
> Safe exit: `Ctrl+P` then `Ctrl+Q`

### exec vs attach

| | `exec -it` | `attach` |
|---|---|---|
| What it does | New shell process | Connects to PID 1 |
| Exit risk | Safe | Ctrl+C stops container |
| Preferred | ✅ Yes | Only for specific debugging |


---

## Copy Files Between Host and Container

```bash
# Host → Container
docker cp ./index.html con1:/usr/share/nginx/html/
docker cp ./config.conf con1:/etc/myapp/

# Container → Host
docker cp con1:/etc/nginx/nginx.conf ./nginx.conf
docker cp con1:/var/log/app.log ./app.log
```

> [!TIP] `docker cp` works on both running and stopped containers.

---

## Export & Import Container Filesystem

```bash
# Export — snapshot the full container filesystem as a tar
docker export con1 > container-backup.tar
docker export con1 | gzip > container-backup.tar.gz

# Import — create a NEW image from an exported tar
cat container-backup.tar | docker import - myimage:restored
docker run -it myimage:restored bash
```

| | `docker export` + `import` | `docker commit` |
|---|---|---|
| What it saves | Container filesystem only | Image layers + metadata |
| History | ❌ Stripped | ✅ Preserved |
| Use case | Snapshot/migrate filesystem | Save changes as image |

---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker run -it image bash` | Interactive shell |
| `docker run -d --name web nginx` | Background container |
| `docker run -dit --name web nginx` | Background + attachable |
| `docker ps` | List running containers |
| `docker ps -a` | List all (including stopped) |
| `docker exec -it con1 bash` | Shell into running container ✅ |
| `docker attach con1` | Attach to PID 1 (Ctrl+P,Q to detach) |
| `docker cp ./file con1:/path` | Copy file into container |
| `docker cp con1:/path ./file` | Copy file out of container |
| `docker export con1 > backup.tar` | Export container filesystem |
| `cat backup.tar \| docker import - img:tag` | Create image from export |

---

*Navigation:*<br>[&larr; Previous Note](02-images.md) | [Next Note &rarr;](04-lifecycle.md)
