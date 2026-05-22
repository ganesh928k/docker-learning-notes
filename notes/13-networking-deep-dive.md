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
