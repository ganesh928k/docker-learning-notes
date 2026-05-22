#!/usr/bin/env bash
# ============================================================
#  update-docker-notes-repo-session3.sh
#  Adds notes 12-15 + updated cheatsheet + README
#  Run from INSIDE your cloned repo directory:
#    cd docker-learning-notes
#    bash update-docker-notes-repo-session3.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}[ERR]${RESET}   $*" >&2; exit 1; }

echo -e "\n${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Docker Notes — Update Script (Session 3)           ║${RESET}"
echo -e "${BOLD}║   Topics: cgroups, networking, volumes, namespaces   ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}\n"

# ── sanity checks ─────────────────────────────────────────
command -v git &>/dev/null || die "git not found."
[[ -f "README.md" ]] || die "Run this from inside your cloned repo directory!"
[[ -d "notes" ]]     || die "'notes/' directory not found. Wrong directory?"

success "Repo directory confirmed: $(pwd)"

# ── PAT ───────────────────────────────────────────────────
read -rsp "$(echo -e ${CYAN}Paste your GitHub PAT \(hidden\):${RESET} )" GIT_PAT
echo ""
[[ -z "${GIT_PAT}" ]] && die "PAT cannot be empty."
git remote set-url origin "https://ganesh928k:${GIT_PAT}@github.com/ganesh928k/docker-learning-notes.git"

info "Pulling latest from origin/main..."
git pull origin main
success "Up to date."

# ════════════════════════════════════════════════════════════
#  NOTE 12 — Resource Constraints & cgroups
# ════════════════════════════════════════════════════════════
info "Writing notes/12-resource-constraints-cgroups.md ..."
cat > notes/12-resource-constraints-cgroups.md << 'EOF'
# 12 — Resource Constraints (CPU, Memory, I/O, PIDs)

Docker uses Linux **cgroups (control groups)** to enforce resource limits on containers.
Without limits, a single container can consume all host CPU/RAM and starve everything else.

---

## Setting limits at container creation

```bash
docker run -d --name con1 \
  --cpus "1.5" \
  --memory="500m" \
  --memory-swap="1g" \
  busybox sleep 1000
```

| Flag | Meaning |
|---|---|
| `--cpus "1.5"` | Allow up to 1.5 CPU cores |
| `--memory="500m"` | Hard RAM limit = 500 MB |
| `--memory-swap="1g"` | Total RAM+swap = 1 GB (swap = 500 MB) |

> **memory-swap** = RAM + swap combined. Set equal to `--memory` to disable swap entirely.

---

## Verify limits are applied

```bash
docker inspect con1 | grep -i "memory"
docker inspect con1 | grep -i "cpu"
```

Key fields:
- `Memory` — hard memory limit in bytes
- `NanoCpus` — CPU quota (1.5 CPUs = 1500000000 nanocores)
- `MemorySwap` — total memory+swap limit

---

## Stress-test CPU to verify the cap

```bash
# Run infinite loop inside the container
docker exec -it con1 sh -c "while :; do :; done"

# In another terminal — watch it hit the cap
docker stats
# CPU% will be capped at ~150% (1.5 cores x 100%)
```

---

## I/O limits — device-write-bps

```bash
# Find your block device first
lsblk

# For LVM-based AlmaLinux 9, use the mapper path:
docker run -d --name io_test \
  --device-write-bps /dev/mapper/almalinux-root:1mb \
  busybox sleep 10000

# Verify
docker inspect io_test | grep -i "rate"
```

> ⚠️ `/dev/sda2` won't work on LVM setups. Always use the `lsblk` output to find the correct device path.

---

## PID limits

```bash
docker run -it --name pid_test --pids-limit 6 alpine sh
```

> ⚠️ The flag is `--pids-limit` (with an **s**), NOT `--pid-limit`.

---

## Update limits on a running container

No need to recreate — `docker update` applies changes live:

```bash
docker update --cpus 2 --memory 250m con1

# Verify
docker inspect con1 | grep -i "cpu"
docker inspect con1 | grep -i "memory"
```

> `docker update` supports: `--cpus`, `--memory`, `--memory-swap`, `--pids-limit`, `--restart`
> It does **not** support `--device-write-bps` on a running container.

---

## docker inspect --format — extract a single field

```bash
# Get full container ID
docker inspect --format '{{.Id}}' con1

# Get the host PID of the container's main process
docker inspect --format '{{.State.Pid}}' con1
```

Cleaner than piping through grep when you need one exact value.

---

## Exploring cgroups on disk

Docker enforces limits through cgroup files you can read directly.

```bash
# Get container PID
docker inspect --format '{{.State.Pid}}' con1
# e.g. 6620

# Check which cgroup the process is in
cat /proc/6620/cgroup

# Navigate to the container's cgroup scope
cd /sys/fs/cgroup/system.slice/docker-<FULL_CONTAINER_ID>.scope
ll
```

Read enforced limits directly:
```bash
cat cpu.max       # CPU quota/period  e.g. "150000 100000" = 1.5 CPUs
cat memory.max    # Memory hard limit in bytes
cat io.max        # I/O rate limits
cat io.stat       # Live I/O stats
cat pids.max      # PID limit
```

---

## PID namespace — isolating process visibility

```bash
# Default — isolated PID namespace
docker run -d --name pid_test ubuntu sleep infinity
docker exec pid_test ps aux        # sees only its own processes

# Share host PID namespace
docker run -d --name pid_host --pid=host ubuntu:latest sleep infinity
docker exec pid_host ps aux        # sees ALL host processes

# Host perspective — same sleep process, different PID numbers
ps aux | grep sleep
```

| | Isolated (default) | `--pid=host` |
|---|---|---|
| Container sees | Only its own processes | All host processes |
| Security | ✅ Isolated | ⚠️ Reduced isolation |
| Use case | Normal workloads | Debugging, monitoring agents |

---

## Section Summary

| Command | What it does |
|---|---|
| `--cpus "1.5"` | Limit to 1.5 CPU cores |
| `--memory="500m"` | Hard RAM cap |
| `--memory-swap="1g"` | RAM + swap cap |
| `--device-write-bps /dev/...:1mb` | I/O write rate limit |
| `--pids-limit 6` | Max processes in container |
| `docker update --cpus 2 --memory 250m con1` | Live update limits |
| `docker inspect --format '{{.State.Pid}}' con1` | Extract specific field |
| `cat /sys/fs/cgroup/.../cpu.max` | Read enforced cgroup limit |
| `--pid=host` | Share host PID namespace |
EOF
success "12-resource-constraints-cgroups.md written."

# ════════════════════════════════════════════════════════════
#  NOTE 13 — Networking Deep Dive
# ════════════════════════════════════════════════════════════
info "Writing notes/13-networking-deep-dive.md ..."
cat > notes/13-networking-deep-dive.md << 'EOF'
# 13 — Docker Networking (Deep Dive)

Docker networking controls how containers communicate with each other and the outside world.
Every container connects to a network — if you don't specify one, Docker uses the default `bridge`.

---

## List networks

```bash
docker network ls
```

Docker creates 3 networks by default:
```
bridge    ← default for all containers
host      ← share host network stack
none      ← no networking
```

---

## Default bridge network

```bash
docker run -dit --name con1 alpine sh
docker run -dit --name con2 alpine sh
docker network inspect bridge     # see IPs of connected containers
```

Ping from host:
```bash
ping 172.17.0.2
```

Ping between containers (by IP only — **no DNS on default bridge**):
```bash
docker exec -it con1 sh
ping 172.17.0.3    # ✅ works by IP
ping con2          # ❌ name resolution fails on default bridge
```

---

## Custom bridge network

Create your own bridge for **automatic DNS name resolution** between containers:

```bash
docker network create my_bridge
docker run -dit --name con3 --network my_bridge alpine:latest
docker run -dit --name con4 --network my_bridge alpine:latest sh
docker network inspect my_bridge
```

Ping by **name** — works on custom bridge:
```bash
docker exec -it con3 sh
ping con4    # ✅ DNS works on custom bridge
```

### Default vs Custom bridge

| Feature | Default `bridge` | Custom bridge |
|---|---|---|
| Container DNS by name | ❌ No | ✅ Yes |
| Isolation | Shared with all containers | Only containers you add |
| Recommended for | Quick testing | All real workloads |

---

## Internal (isolated) network — no internet

```bash
docker network create iso_net --driver bridge --internal
docker run -dit --name con5 --network iso_net alpine:latest sh
docker network inspect iso_net
```

Test isolation:
```bash
docker exec -it con5 ping -c 3 172.19.0.2    # ✅ reaches other containers on same net
ping 172.19.0.2                               # ❌ host cannot reach it
docker exec -it con2 ping 172.19.0.2          # ❌ other network containers blocked
```

**Use case:** Databases, internal microservices that must never be internet-accessible.

---

## Host network

Container shares the host's network stack — no NAT, no isolation:

```bash
docker run -dit --name con6 --network host alpine:latest sh

# Container and host see identical interfaces
docker exec -it con6 ip a
ip a                           # same output
docker inspect con6            # NetworkSettings.Networks → "host"
```

**When to use:** Maximum performance, monitoring agents, containers binding directly to host ports.

> ⚠️ `--network host` only works natively on Linux. Behaves differently on Mac/Windows (Docker runs in a VM there).

---

## Remove networks

```bash
docker network rm iso_net my_bridge
docker network ls
```

> Cannot remove a network with active containers attached. Remove containers first.

---

## Section Summary

| Command | What it does |
|---|---|
| `docker network ls` | List all networks |
| `docker network create my_net` | Create custom bridge |
| `docker network create --internal iso_net` | Isolated (no internet) network |
| `docker network inspect <name>` | Details + connected container IPs |
| `docker network rm <name>` | Remove a network |
| `--network my_bridge` | Attach container to specific network |
| `--network host` | Share host network stack |
| `--network none` | No networking |

### Network type quick reference

| Network | Internet | DNS by name | Use case |
|---|---|---|---|
| Default `bridge` | ✅ | ❌ | Quick testing |
| Custom bridge | ✅ | ✅ | App services (recommended) |
| `host` | ✅ | N/A | Performance, monitoring |
| `--internal` | ❌ | ✅ | Isolated backends, DBs |
| `none` | ❌ | ❌ | Maximum isolation |
EOF
success "13-networking-deep-dive.md written."

# ════════════════════════════════════════════════════════════
#  NOTE 14 — Volumes
# ════════════════════════════════════════════════════════════
info "Writing notes/14-volumes.md ..."
cat > notes/14-volumes.md << 'EOF'
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
EOF
success "14-volumes.md written."

# ════════════════════════════════════════════════════════════
#  NOTE 15 — Linux Namespaces
# ════════════════════════════════════════════════════════════
info "Writing notes/15-namespaces-pid-uts-ipc-user.md ..."
cat > notes/15-namespaces-pid-uts-ipc-user.md << 'EOF'
# 15 — Linux Namespaces in Docker (PID, UTS, IPC, User)

Namespaces are the Linux kernel feature that makes containers possible.
Each namespace type isolates a different aspect of the system.

```
Container isolation = Namespaces (what you see) + cgroups (what you can use)
```

---

## Namespace types Docker uses

| Namespace | Isolates | Docker flag to share |
|---|---|---|
| **PID** | Process IDs | `--pid=host` |
| **NET** | Network interfaces, routes | `--network=host` |
| **MNT** | Filesystem mounts | Volumes punch through this |
| **UTS** | Hostname and domain name | `--uts=host` |
| **IPC** | Shared memory, message queues | `--ipc=host` / `--ipc=container:<name>` |
| **USER** | User and group IDs | `--userns-remap` in daemon.json |

---

## 1. PID Namespace

```bash
# Default — isolated, container sees only its own processes
docker run -d --name pid_test ubuntu sleep infinity
docker exec pid_test ps aux          # sees: sleep + ps only

# Share host PID namespace
docker run -d --name pid_host --pid=host ubuntu:latest sleep infinity
docker exec pid_host ps aux          # sees ALL host processes

# Host side — same process, different PID number
ps aux | grep sleep
```

Linux tools for namespace exploration:
```bash
unshare --help    # create new namespaces manually
man unshare
```

---

## 2. UTS Namespace — Hostname Isolation

UTS = **Unix Time-Sharing System**. Controls what hostname the container sees.

### Isolated hostname (default)

```bash
docker run -it --hostname custom-container-hostname --name uts-example1 ubuntu:latest bash
# inside: hostname → "custom-container-hostname"

docker exec uts-example1 hostname    # custom-container-hostname
```

Changing the host hostname does NOT affect an isolated container:
```bash
hostnamectl set-hostname shared-hostname
docker exec uts-example1 hostname    # still shows custom-container-hostname ✅
```

### Share host UTS namespace

```bash
docker run --name uts-example2 -it --uts=host ubuntu:latest bash
# inside: hostname IS the host's hostname — changes when host changes
```

```bash
hostnamectl set-hostname localhost-gan
docker exec uts-example2 hostname    # localhost-gan ← follows host in real time
docker exec uts-example1 hostname    # custom-container-hostname ← unaffected
```

### Host hostname commands

```bash
hostname                              # show current hostname
hostnamectl status                    # full status
hostnamectl set-hostname myserver     # set new hostname
```

---

## 3. IPC Namespace — Inter-Process Communication

IPC covers shared memory segments and message queues.
Default: each container gets its own isolated IPC namespace.

### Host IPC tools

```bash
ipcmk -M 1024        # create a 1024-byte shared memory segment
ipcs -m              # list shared memory segments
ipcrm -m <shmid>     # remove a shared memory segment (ID from ipcs -m)
```

### Isolated IPC (default)

```bash
docker run -it --name ipc-iso1 ubuntu:latest bash
docker run -it --name ipc-iso2 ubuntu:latest bash
# Memory created in ipc-iso1 is completely invisible to ipc-iso2
```

### Share IPC between two containers

Container 1 — mark as shareable:
```bash
docker run -it --name ipc_shared1 --ipc=shareable ubuntu:latest bash
# inside: ipcmk -M 1024
```

Container 2 — join container 1's IPC namespace:
```bash
docker run -it --name ipc-shared2 --ipc=container:ipc_shared1 ubuntu:latest bash
# inside: ipcs -m  ← sees the shared memory from ipc_shared1 ✅
```

> ⚠️ Use the exact container name — `ipc_shared1` (underscore), not `ipc-shared1` (hyphen).

### Share host IPC namespace

```bash
docker run -it --ipc=host ubuntu:latest bash
# sees and can access all host shared memory segments
```

### IPC mode reference

| Mode | Description | Use case |
|---|---|---|
| default | Own isolated IPC namespace | ✅ Normal workloads |
| `--ipc=shareable` | Can be joined by other containers | Sidecar patterns |
| `--ipc=container:<name>` | Joins another container's IPC | Tightly-coupled containers |
| `--ipc=host` | Shares host IPC | Legacy apps needing host shared memory |

---

## 4. User Namespace — UID Remapping

Maps container UIDs to unprivileged host UIDs.
Root (UID 0) inside the container → unprivileged UID (e.g. 100000) on the host.
This is the strongest security hardening available in Docker.

### Check UID/GID mappings

```bash
cat /etc/subuid    # e.g.: dockremap:100000:65536
cat /etc/subgid    # e.g.: dockremap:100000:65536
```

Container root = UID 0 inside, but UID 100000 on the host.

### Enable user namespace remapping

Test manually:
```bash
systemctl stop docker
dockerd --userns-remap=default &
docker info | grep -i userns
```

For permanent config — add to `/etc/docker/daemon.json`:
```json
{
  "userns-remap": "default"
}
```

```bash
cat /etc/docker/daemon.json
systemctl restart docker
docker info | grep -i userns
```

### Clean restart after userns experiments

If dockerd gets stuck after manual testing:

```bash
# Find and kill stray processes
ps -ef | grep -E 'dockerd|containerd'
kill -9 <PID>

# Clean up stale socket/pid files
rm -f /var/run/docker.pid
rm -f /var/run/docker.sock

# Nuclear clean reset (dev/lab only — deletes ALL data)
systemctl stop docker
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
systemctl restart containerd
systemctl restart docker
docker info    # confirm clean state
```

> ⚠️ `rm -rf /var/lib/docker` destroys ALL containers, images, and volumes.
> Only use on lab machines. NEVER on production.

---

## Namespace big picture

```
Without namespaces: all processes share one hostname, one PID table, one network, one /etc
With namespaces:    each container thinks it IS the only thing running on the machine
```

---

## Section Summary

| Concept | Command |
|---|---|
| Custom hostname | `--hostname myname` |
| Share host hostname | `--uts=host` |
| Share host PID namespace | `--pid=host` |
| Isolated IPC (default) | (nothing needed) |
| Shareable IPC | `--ipc=shareable` |
| Join another container's IPC | `--ipc=container:<name>` |
| Share host IPC | `--ipc=host` |
| Enable user namespace remapping | daemon.json → `"userns-remap": "default"` |
| Check UID mappings | `cat /etc/subuid` / `cat /etc/subgid` |
| Verify userns active | `docker info \| grep -i userns` |
EOF
success "15-namespaces-pid-uts-ipc-user.md written."

# ════════════════════════════════════════════════════════════
#  UPDATED: cheatsheet.md
# ════════════════════════════════════════════════════════════
info "Updating cheatsheet.md ..."
cat > cheatsheet.md << 'EOF'
# ⚡ Docker Quick Cheat Sheet

---

## 🖼️ Images

```bash
docker pull nginx:latest          # Download image
docker images                     # List local images
docker images nginx               # Filter by name
docker images "nginx*"            # Wildcard (always quote)
docker search nginx               # Search Docker Hub
docker image history nginx        # Show image layers
docker rmi nginx                  # Remove image
docker rmi $(docker images -q)    # Remove ALL images (careful!)
```

---

## 📦 Run Containers

```bash
docker run nginx                              # Run foreground
docker run -d nginx                           # Detached/background
docker run -it ubuntu bash                    # Interactive shell
docker run -dit --name web nginx              # Background + attachable
docker run -d --name web -p 8080:80 nginx     # With port mapping
docker run -d --rm nginx                      # Auto-delete on stop
```

---

## 📋 Inspect & Monitor

```bash
docker ps / docker ps -a
docker inspect web
docker inspect --format '{{.Id}}' web               # Extract single field
docker inspect --format '{{.State.Pid}}' web        # Get container host PID
docker inspect web | grep IPAddress
docker image inspect nginx:latest | grep -i lower   # OverlayFS layers
docker logs web / --follow / --tail 50
docker stats / docker stats web
docker info
docker system df / docker system df -v
```

---

## 💾 Commit & Tag

```bash
docker commit <id> myimage:v1
docker commit --author="ganesh" --message="msg" <id> name
docker tag myimage:v1 myimage:stable
docker tag myimage:v1 jaatxog/myimage:latest
docker rmi myimage:stable                            # Remove tag only
```

---

## 🌐 Registry

```bash
docker login -u <username>
docker logout
docker tag myimage:v1 user/myimage:v1
docker push user/myimage:v1
docker pull user/myimage:v1
# Local registry
docker run -d -p 5000:5000 --name local-registry registry:2
docker tag alpine:latest localhost:5000/alpine:latest
docker push localhost:5000/alpine:latest
curl http://localhost:5000/v2/_catalog
```

---

## ⚡ Resource Constraints (cgroups)

```bash
# Set at run time
docker run -d --name con1 \
  --cpus "1.5" --memory="500m" --memory-swap="1g" busybox sleep 1000

# I/O write rate limit
docker run -d --name io_test \
  --device-write-bps /dev/mapper/almalinux-root:1mb busybox sleep 10000

# PID limit
docker run -it --name pid_test --pids-limit 6 alpine sh

# Update live (no restart needed)
docker update --cpus 2 --memory 250m con1

# Verify
docker inspect con1 | grep -i memory
docker inspect con1 | grep -i cpu
docker inspect io_test | grep -i rate

# Read from cgroups directly
cat /proc/$(docker inspect --format '{{.State.Pid}}' con1)/cgroup
# Navigate: /sys/fs/cgroup/system.slice/docker-<ID>.scope/
cat cpu.max && cat memory.max && cat io.max && cat pids.max
```

---

## 🌍 Networking

```bash
docker network ls
docker network create my_bridge                            # Custom bridge (has DNS)
docker network create iso_net --driver bridge --internal   # Isolated (no internet)
docker network inspect my_bridge
docker network rm iso_net my_bridge

docker run -dit --name con3 --network my_bridge alpine sh  # Custom bridge
docker run -dit --name con6 --network host alpine sh       # Host network
```

---

## 💿 Volumes

```bash
docker volume create my_vol
docker volume ls
docker volume inspect my_vol                               # See host path
docker volume rm my_vol                                    # Stop containers first
docker volume prune                                        # Remove all unused

docker run -d --name con1 -v my_vol:/data nginx            # Named volume
docker run -d --name con2 -v my_vol:/shared_data alpine sleep 1000  # Shared
docker run -d --name con3 -v /data nginx                   # Anonymous volume
docker run -d --name con4 -v $(pwd):/app nginx             # Bind mount

# Backup
docker run --rm -v my_vol:/data -v $(pwd):/backup ubuntu \
  tar cvf /backup/backup.tar /data

# Restore
docker run --rm -v my_vol:/data -v $(pwd):/backup ubuntu \
  tar xvf /backup/backup.tar -C /
```

---

## 🔒 Namespaces

```bash
# UTS — hostname
docker run -it --hostname myhost ubuntu bash           # Custom hostname
docker run -it --uts=host ubuntu bash                  # Share host hostname
hostnamectl set-hostname newname                       # Change host hostname
docker exec con1 hostname                              # Check container hostname

# PID
docker run -d --pid=host ubuntu sleep infinity         # Share host PID ns
docker exec con1 ps aux                                # What container sees

# IPC — shared memory
ipcmk -M 1024                                          # Create shared mem (host)
ipcs -m                                                # List shared memory
ipcrm -m <shmid>                                       # Remove shared mem
docker run -it --name s1 --ipc=shareable ubuntu bash
docker run -it --name s2 --ipc=container:s1 ubuntu bash
docker run -it --ipc=host ubuntu bash

# User namespace remapping
cat /etc/subuid && cat /etc/subgid
docker info | grep -i userns
# /etc/docker/daemon.json: { "userns-remap": "default" }
```

---

## ▶️ Lifecycle

```bash
docker start/stop/restart/kill web
docker pause web / docker unpause web
docker rename web mysite
```

---

## 🔧 Interact

```bash
docker exec -it web bash         # ← USE THIS to shell in
docker attach web                # Ctrl+P Ctrl+Q to detach safely
docker cp web:/path ./local
docker cp ./file web:/path
```

---

## 🏗️ Build

```bash
docker build -t myapp .
docker build -t myapp:v2 .
docker inspect myapp:latest
```

---

## ⚙️ Daemon (systemd)

```bash
systemctl status docker
systemctl daemon-reload && systemctl restart docker
vim /lib/systemd/system/docker.service
firewall-cmd --permanent --add-port=2375/tcp && firewall-cmd --reload

# Emergency clean restart
ps -ef | grep -E 'dockerd|containerd'
kill -9 <PID>
rm -f /var/run/docker.pid /var/run/docker.sock
systemctl restart containerd && systemctl restart docker
```

---

## 🔍 Internals

```bash
sudo ls -lh /var/lib/docker/
sudo ls -lh /var/lib/docker/{containers,image,volumes,network}
yum install tree -y && tree -af /var/lib/docker/image/
updatedb && locate overlay2
```

---

## 🗑️ Cleanup

```bash
docker container prune
docker image prune
docker volume prune
docker system prune
docker system prune -a
docker rm -f $(docker ps -a -q)
```

---

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct |
|---|---|
| `docker run it image` | `docker run -it image` |
| `docker rm all` | `docker container prune` |
| `docker image history` | `docker image history <name>` |
| `ipconfig` | `ip a` |
| `dockerfile` | `Dockerfile` (capital D) |
| `docker start <id> -dit` | `docker start -dit <id>` |
| `docker images *nginx` | `docker images "nginx*"` |
| `docker pull ngnix` | `docker pull nginx` (typo) |
| `--pid-limit 6` | `--pids-limit 6` (add the **s**) |
| `--ipc=container:ipc-shared1` | `--ipc=container:ipc_shared1` (exact name) |
| `docker df -v` | `docker system df -v` |
| `${docker ps -a -q}` | `$(docker ps -a -q)` (use `$()` not `${}`) |
| `update db` | `updatedb` (one word) |
EOF
success "cheatsheet.md updated."

# ════════════════════════════════════════════════════════════
#  UPDATED: README.md
# ════════════════════════════════════════════════════════════
info "Updating README.md ..."
cat > README.md << 'EOF'
# 🐳 Docker Learning Notes

> Practical, hands-on Docker notes built from real terminal sessions.
> Beginner-to-intermediate friendly. No fluff — just working commands and clear explanations.

---

## 📚 Table of Contents

| # | File | Topics Covered |
|---|------|----------------|
| 1 | [Installation & Setup](notes/01-installation-setup.md) | DNF repo, Docker CE, systemctl |
| 2 | [Docker Images](notes/02-images.md) | pull, search, history, rmi |
| 3 | [Docker Containers](notes/03-containers.md) | run, ps, stop, rm, exec, attach |
| 4 | [Container Lifecycle](notes/04-lifecycle.md) | start, pause, rename, stats, logs |
| 5 | [Port Mapping & Networking](notes/05-networking.md) | -p flag, bridge network, ip a |
| 6 | [Dockerfile](notes/06-dockerfile.md) | FROM, COPY, EXPOSE, build |
| 7 | [Docker Hub](notes/07-dockerhub.md) | pull, run public images |
| 8 | [System Cleanup](notes/08-cleanup.md) | prune, rm -f, batch delete |
| 9 | [Commit, Inspect & Tag](notes/09-commit-inspect-tag.md) | commit, inspect, tag, wildcards |
| 10 | [Login, Push & Local Registry](notes/10-login-push-local-registry.md) | Docker Hub push, private registry |
| 11 | [Internals & System Management](notes/11-internals-system-management.md) | /var/lib/docker, OverlayFS, systemd |
| 12 | [Resource Constraints & cgroups](notes/12-resource-constraints-cgroups.md) | CPU, memory, I/O, PID limits, docker update |
| 13 | [Networking Deep Dive](notes/13-networking-deep-dive.md) | bridge, host, internal, custom networks |
| 14 | [Volumes](notes/14-volumes.md) | named, anonymous, bind, backup, restore |
| 15 | [Linux Namespaces](notes/15-namespaces-pid-uts-ipc-user.md) | PID, UTS, IPC, user namespace remapping |
| ⚡ | [Quick Cheat Sheet](cheatsheet.md) | All essential commands at a glance |

---

## 🚀 How to Use

1. ⭐ **Star** this repo so you can find it later
2. Read notes **in order (01 → 15)** for a structured learning path
3. Keep the **[Cheat Sheet](cheatsheet.md)** open while practising
4. Every command was tested on **AlmaLinux 9 / RHEL 9**

---

## 🗺️ Learning Path

```
Basics (01-08)          → Core Docker CLI, images, containers, cleanup
Intermediate (09-11)    → commit, tag, push, local registry, internals
Advanced (12-15)        → cgroups, networking, volumes, Linux namespaces
```

---

## 🛠️ Prerequisites

- A Linux machine (AlmaLinux 9, RHEL 9, Fedora, or Ubuntu)
- Basic terminal familiarity (cd, ls, vim)
- A [Docker Hub](https://hub.docker.com) account (free)

---

## 📂 Repo Structure

```
docker-learning-notes/
├── README.md
├── cheatsheet.md
├── notes/
│   ├── 01-installation-setup.md
│   ├── 02-images.md
│   ├── 03-containers.md
│   ├── 04-lifecycle.md
│   ├── 05-networking.md
│   ├── 06-dockerfile.md
│   ├── 07-dockerhub.md
│   ├── 08-cleanup.md
│   ├── 09-commit-inspect-tag.md
│   ├── 10-login-push-local-registry.md
│   ├── 11-internals-system-management.md
│   ├── 12-resource-constraints-cgroups.md
│   ├── 13-networking-deep-dive.md
│   ├── 14-volumes.md
│   └── 15-namespaces-pid-uts-ipc-user.md
└── images/
```

---

## 🤝 Contributing

Found a mistake or want to add a topic?
- Open an **Issue** to report errors or suggest new sections
- Open a **Pull Request** with your improvements

---

## 📄 License

[MIT](LICENSE) — free to use, share, and adapt.

---

*Built with ❤️ while learning DevOps the hands-on way.*
EOF
success "README.md updated."

# ════════════════════════════════════════════════════════════
#  GIT COMMIT & PUSH
# ════════════════════════════════════════════════════════════
echo ""
info "Staging all changes..."
git add .

info "Committing..."
git commit -m "feat: add session-3 notes (cgroups, networking, volumes, namespaces)

New notes:
- 12-resource-constraints-cgroups.md
    CPU/memory/IO/PID limits, docker update, cgroup files, PID namespace
- 13-networking-deep-dive.md
    default bridge, custom bridge, internal network, host network
- 14-volumes.md
    named/anonymous/bind, shared volumes, backup & restore workflow
- 15-namespaces-pid-uts-ipc-user.md
    PID/UTS/IPC/User namespaces, hostname isolation, shared memory,
    userns-remap, clean restart procedure

Updated:
- cheatsheet.md: all new commands from session 3
- README.md: table of contents 11 → 15 notes, added learning path"

info "Pushing to GitHub..."
git push origin main

# ── done ──────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   ✅  Done! 4 new notes + updated cheatsheet pushed.       ║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  🔗 ${CYAN}https://github.com/ganesh928k/docker-learning-notes${RESET}"
echo ""
echo -e "  ${GREEN}✔${RESET} notes/12-resource-constraints-cgroups.md    (NEW)"
echo -e "  ${GREEN}✔${RESET} notes/13-networking-deep-dive.md             (NEW)"
echo -e "  ${GREEN}✔${RESET} notes/14-volumes.md                          (NEW)"
echo -e "  ${GREEN}✔${RESET} notes/15-namespaces-pid-uts-ipc-user.md      (NEW)"
echo -e "  ${GREEN}✔${RESET} cheatsheet.md                                (UPDATED)"
echo -e "  ${GREEN}✔${RESET} README.md                                    (UPDATED)"
echo ""
