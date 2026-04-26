# 03 — Docker Containers — Basics

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

> ⚠️ Pressing `Ctrl+C` here **stops the container**!
> Safe exit: `Ctrl+P` then `Ctrl+Q`

### exec vs attach

| | `exec -it` | `attach` |
|---|---|---|
| What it does | New shell process | Connects to PID 1 |
| Exit risk | Safe | Ctrl+C stops container |
| Preferred | ✅ Yes | Only for specific debugging |
