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

> [!WARNING] Use the exact container name — `ipc_shared1` (underscore), not `ipc-shared1` (hyphen).

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

> [!WARNING] `rm -rf /var/lib/docker` destroys ALL containers, images, and volumes.
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


---

*Navigation:*<br>[&larr; Previous Note](14-volumes.md) | [Next Note &rarr;](16-dockerfile-advanced-instructions.md)
