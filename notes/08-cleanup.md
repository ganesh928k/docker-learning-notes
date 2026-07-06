# 08 — System Cleanup

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

Regular cleanup prevents Docker from consuming all your disk space.

---

## Remove stopped containers

```bash
docker container prune        # asks for confirmation
docker container prune -f     # no confirmation (use in scripts)
```

---

## Remove all containers (force)

```bash
docker container rm -f $(docker ps -a -q)
```

- `docker ps -a -q` — lists only the IDs of all containers
- `$()` — passes those IDs as arguments to `rm -f`

---

## Remove images

```bash
docker rmi nginx                   # specific image
docker image prune                 # dangling (untagged) images only
docker image prune -a              # ALL unused images
```

---

## Nuclear option — remove everything unused

```bash
docker system prune
```

Removes in one shot:
- All stopped containers
- All dangling images
- All unused networks
- Build cache

```bash
docker system prune -a     # also removes images not used by any container
docker system prune -f     # skip confirmation prompt
```

> [!WARNING] **WARNING:** Never run `docker system prune -a -f` on a production server.
> It will remove images that containers might need on next start.

---

## Check disk usage first

```bash
docker system df           # summary of Docker disk usage
docker system df -v        # verbose breakdown by image/container/volume
```

---

## Safe cleanup workflow (recommended)

```bash
# 1. See what's there
docker ps -a
docker images

# 2. Remove specific things you don't need
docker rm con1 con2
docker rmi myoldimage

# 3. If still bloated, prune selectively
docker container prune
docker image prune
```


---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker system df` | Check disk usage summary |
| `docker system df -v` | Verbose per-object breakdown |
| `docker container prune` | Remove all stopped containers |
| `docker container rm -f $(docker ps -a -q)` | Force-remove ALL containers |
| `docker image prune` | Remove dangling (untagged) images |
| `docker image prune -a` | Remove all unused images |
| `docker volume prune` | Remove all unused volumes |
| `docker network prune` | Remove unused networks |
| `docker system prune` | Remove stopped containers + dangling images + networks + build cache |
| `docker system prune -a` | Same + all unused images |
| `docker system prune -a -f` | ⚠️ Non-interactive nuclear option — never on production! |

---

*Navigation:*<br>[&larr; Previous Note](07-dockerhub.md) | [Next Note &rarr;](09-commit-inspect-tag.md)
