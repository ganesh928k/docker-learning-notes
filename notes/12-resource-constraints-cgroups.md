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

> [!WARNING] `/dev/sda2` won't work on LVM setups. Always use the `lsblk` output to find the correct device path.

---

## PID limits

```bash
docker run -it --name pid_test --pids-limit 6 alpine sh
```

> [!WARNING] The flag is `--pids-limit` (with an **s**), NOT `--pid-limit`.

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


---

*Navigation:*<br>[&larr; Previous Note](11-internals-system-management.md) | [Next Note &rarr;](13-networking-deep-dive.md)
