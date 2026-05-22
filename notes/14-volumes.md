# 14 — Docker Volumes

Containers are **ephemeral** — data inside is lost when the container is removed.
Volumes store data **outside** the container so it survives restarts, removals, and upgrades.

---

## Types of storage

| Type | Syntax | Data location | Survives removal |
|---|---|---|---|
| Named volume | `-v my_vol:/data` | `/var/lib/docker/volumes/` | ✅ Yes |
| Anonymous volume | `-v /data` | `/var/lib/docker/volumes/<hash>/` | ✅ Until pruned |
| Bind mount | `-v /host/path:/container/path` | Anywhere on host | ✅ Yes |

---

## Named volumes

```bash
# Create
docker volume create my_vol

# List
docker volume ls

# Inspect (shows Mountpoint on host)
docker volume inspect my_vol
# Mountpoint: /var/lib/docker/volumes/my_vol/_data

# Mount into container
docker run -d --name con1 -v my_vol:/data nginx
```

### Write from inside container, read from host

```bash
docker exec -it con1 bash
# inside:
echo "hello from con1" > /data/ganesh.txt
exit

# on host:
cat /var/lib/docker/volumes/my_vol/_data/ganesh.txt
```

---

## Sharing a volume between containers

```bash
# con1 already has my_vol mounted at /data
# Attach same volume to con2 at a different path
docker run -d --name con2 -v my_vol:/shared_data alpine:latest sleep 1000

# Read from con2
docker exec con2 cat /shared_data/ganesh.txt     # sees con1's file ✅
docker exec -it con2 sh                           # shell in and write more
```

Any file written by one container instantly appears in the other — same underlying directory.

---

## Anonymous volumes

```bash
docker run -d --name con3 -v /data nginx
docker volume ls    # shows a long hash-named volume
docker volume inspect <hash>
```

Hard to manage — no friendly name. Use named volumes for anything important.

---

## Volume namespace isolation

Each volume is an independent directory — even if two containers both mount at `/data`:

```bash
docker run -d --name con5 -v vol1:/data nginx:latest
docker run -d --name con6 -v vol2:/data nginx:latest

# Completely separate on the host:
ls /var/lib/docker/volumes/vol1/_data
ls /var/lib/docker/volumes/vol2/_data
```

---

## Remove volumes

```bash
# Must stop + remove the container first
docker stop con1 con2
docker rm -f con1 con2
docker volume rm my_vol

# Remove ALL unused volumes
docker volume prune
```

> ⚠️ `docker volume rm` fails if any container (even stopped) references the volume.

---

## Backup a volume

```bash
docker run --rm \
  -v my_vol:/data \
  -v $(pwd):/backup \
  ubuntu \
  tar cvf /backup/backup.tar /data
```

- `--rm` — container auto-removes after the command
- `-v my_vol:/data` — mount the volume to back up
- `-v $(pwd):/backup` — mount current host directory as output
- Result: `backup.tar` appears in your current directory

---

## Restore a volume from backup

```bash
docker run --rm \
  -v my_vol:/data \
  -v $(pwd):/backup \
  ubuntu:latest \
  tar xvf /backup/backup.tar -C /
```

The `my_vol` volume is created automatically if it doesn't exist.

---

## Section Summary

| Command | What it does |
|---|---|
| `docker volume create my_vol` | Create named volume |
| `docker volume ls` | List all volumes |
| `docker volume inspect my_vol` | Details + host path |
| `docker volume rm my_vol` | Delete volume (stop containers first) |
| `docker volume prune` | Delete all unused volumes |
| `-v my_vol:/data` | Mount named volume |
| `-v /data` | Mount anonymous volume |
| `-v $(pwd):/backup` | Bind mount current directory |
| `tar cvf /backup/backup.tar /data` | Backup volume contents |
| `tar xvf /backup/backup.tar -C /` | Restore volume contents |
