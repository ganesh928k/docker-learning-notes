# 08 — System Cleanup

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

> ⚠️ **WARNING:** Never run `docker system prune -a -f` on a production server.
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
