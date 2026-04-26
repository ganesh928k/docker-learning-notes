# 04 — Container Lifecycle Management

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

> ⚠️ Flags must come BEFORE the container name: `docker start -dit con1` ✅

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
