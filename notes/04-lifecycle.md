# 04 — Container Lifecycle Management

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

```
create → start → (pause / unpause) → stop → rm
```

---

## Stop a container

```bash
docker stop con1
docker stop con1 con2 con3    # stop multiple at once
```

Sends `SIGTERM`, waits 10 seconds, then sends `SIGKILL`.

---

## Start a stopped container

```bash
docker start con1
docker start -dit con1    # start with interactive terminal
```

> [!WARNING] Flags must come BEFORE the container name: `docker start -dit con1` ✅

---

## Remove containers

```bash
docker rm con1                              # remove one (must be stopped)
docker rm con1 con2 con3                    # remove multiple
docker rm -f con1                           # force-remove a running container
docker container rm -f $(docker ps -a -q)  # force-remove ALL containers
```

---

## Pause / Unpause

```bash
docker pause con1      # freeze all processes (uses Linux cgroups)
docker unpause con1    # resume
```

Use case: freeze a container during a snapshot or backup.

---

## Rename

```bash
docker container rename con4 con1
```

---

## View logs

```bash
docker container logs con1
docker logs con1 --follow     # stream live (like tail -f)
docker logs con1 --tail 50    # last 50 lines
```

---

## Live resource stats

```bash
docker stats           # all running containers
docker stats con1      # specific container
```

Press `Ctrl+C` to exit. Shows CPU %, memory, network I/O, disk I/O.


---

## Restart Policies

Restart policies control what Docker does when a container exits. Essential for production.

```bash
# Set at run time
docker run -d --restart always --name web nginx
docker run -d --restart on-failure:3 --name worker myapp
docker run -d --restart unless-stopped --name db mysql:8.0

# Update restart policy on existing container (no restart needed)
docker update --restart always web
docker update --restart no web   # disable
```

| Policy | Behaviour |
|---|---|
| `no` | Never restart (default) |
| `on-failure[:max]` | Restart only on non-zero exit code |
| `always` | Always restart — even after `docker daemon` reboot |
| `unless-stopped` | Like `always`, but respects manual `docker stop` |

> [!TIP]
> Use `unless-stopped` for services you always want running.
> Use `on-failure:3` for batch jobs that should retry but not loop forever.

---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker stop con1` | Graceful stop (SIGTERM → SIGKILL) |
| `docker kill con1` | Immediate kill (SIGKILL) |
| `docker start con1` | Start stopped container |
| `docker restart con1` | Stop + start |
| `docker pause con1` | Freeze (cgroups) |
| `docker unpause con1` | Resume |
| `docker rm con1` | Remove stopped container |
| `docker rm -f con1` | Force remove running container |
| `docker rename con1 web` | Rename container |
| `docker logs con1 --follow` | Stream live logs |
| `docker logs con1 --tail 50` | Last 50 log lines |
| `docker stats` | Live CPU/memory/IO usage |
| `--restart always` | Auto-restart on exit/reboot |
| `--restart on-failure:3` | Retry up to 3 times on failure |
| `--restart unless-stopped` | Always restart unless manually stopped |

---

*Navigation:*<br>[&larr; Previous Note](03-containers.md) | [Next Note &rarr;](05-networking.md)
