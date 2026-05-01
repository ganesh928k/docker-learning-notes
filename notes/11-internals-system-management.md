# 11 — Docker Internals & System Management

Understanding what lives on disk and how Docker's daemon is configured.

---

## docker system df — Disk usage

```bash
docker system df          # summary table
docker system df -v       # verbose: per-image, per-container, per-volume
```

Sample output:
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          5         2         1.2GB     800MB (66%)
Containers      3         1         12MB      8MB
Local Volumes   2         1         500MB     0B
Build Cache     10        0         300MB     300MB
```

> `RECLAIMABLE` = disk space you can free with `docker system prune`

---

## docker info — Full daemon configuration

```bash
docker info
```

Shows: Docker version, container/image counts, storage driver (`overlay2`),
logging driver, cgroup driver, kernel version, OS, RAM, CPUs.

> 💡 First thing to run when debugging Docker on a new machine.

---

## /var/lib/docker — Where Docker stores everything

Requires `root` (or `sudo`) to browse.

```bash
sudo ls -lh /var/lib/docker/
```

```
containers/    ← config + logs per container
image/         ← image metadata and layer references
network/       ← network configs
volumes/       ← named volumes data
buildkit/      ← build cache
plugins/       ← plugin data
engine-id      ← unique ID for this Docker daemon
```

### Exploring subdirectories
```bash
sudo ls -lh /var/lib/docker/containers/
sudo ls -lh /var/lib/docker/image/
sudo ls -lh /var/lib/docker/volumes/
sudo ls -lh /var/lib/docker/network/files/
sudo ls -lh /var/lib/docker/buildkit/
```

> ⚠️ Never manually edit/delete files here — always use Docker CLI.
> Manual changes corrupt Docker's internal state.

---

## OverlayFS — How Docker layers work

Docker uses **OverlayFS** (overlay2 driver) to stack image layers efficiently.

```bash
docker image inspect nginx:latest | grep -i upper   # UpperDir (writable)
docker image inspect nginx:latest | grep -i lower   # LowerDir (read-only layers)
```

| Layer | Description |
|---|---|
| **LowerDir** | Read-only image layers (shared between containers) |
| **UpperDir** | Writable layer unique to this container |
| **MergedDir** | Union view the container sees |

```bash
# Visualise with tree
yum install tree -y
tree -af /var/lib/docker/image/
tree -af . | grep layer

# Find overlay dirs on disk
updatedb
locate overlay2
locate overlay
```

---

## Docker daemon — systemd service

```bash
systemctl status docker                               # check daemon health
systemctl restart docker                              # restart daemon
systemctl daemon-reload && systemctl restart docker   # after editing .service file
```

### Edit the service file
```bash
vim /lib/systemd/system/docker.service
```

### Enable Docker TCP API (port 2375)

In the `[Service]` section, find `ExecStart` and append `-H tcp://0.0.0.0:2375`:

```ini
ExecStart=/usr/bin/dockerd \
  -H fd:// \
  -H tcp://0.0.0.0:2375 \
  --containerd=/run/containerd/containerd.sock
```

```bash
systemctl daemon-reload
systemctl restart docker
firewall-cmd --permanent --add-port=2375/tcp
firewall-cmd --reload
```

> ⚠️ Port 2375 is **unauthenticated**. Use only on trusted internal networks.
> For internet-facing access, use port **2376 with TLS**.

---

## Useful system commands

```bash
cat /etc/os-release       # check OS version (inside container or on host)
htop                      # real-time process monitor on host
updatedb                  # refresh the locate file index
locate <filename>         # find files fast
```

---

## Section Summary

| Command | What it does |
|---|---|
| `docker system df` | Disk usage summary |
| `docker system df -v` | Per-object breakdown |
| `docker info` | Full daemon config |
| `sudo ls -lh /var/lib/docker/` | Browse Docker data root |
| `docker image inspect nginx \| grep -i lower` | Show OverlayFS layers |
| `systemctl daemon-reload && systemctl restart docker` | Apply daemon config changes |
| `tree -af /var/lib/docker/image/` | Visualise layer structure |
