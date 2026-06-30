# ⚙️ Docker Swarm Services

In Docker Swarm, you don't start individual containers — you declare **services**. A service is a definition of the desired state for a containerized application running across the cluster. The Swarm manager ensures that state is always maintained.

---

## 🔑 Key Concept: Services vs Containers

| | `docker run` (standalone) | `docker service` (Swarm) |
|---|---|---|
| **Scope** | Single host | Entire cluster |
| **Scheduling** | Manual | Automatic |
| **Fault tolerance** | None (dies = gone) | Replaced automatically |
| **Scaling** | Manual `docker run` again | `docker service scale` |
| **Rolling updates** | Not built-in | Built-in |

---

## 🚀 Creating a Service

### Basic Syntax

```bash
docker service create \
  --name <service-name> \
  --replicas <number-of-instances> \
  -p <host-port>:<container-port> \
  <image>
```

### Example — Deploy 3 Nginx Replicas

```bash
docker service create --name mynginx --replicas 3 -p 8080:80 nginx
```

**What happens:**
1. Manager pulls `nginx` image on all nodes (if not cached)
2. Schedules 3 **tasks** (one container each) across available nodes
3. Maps host port `8080` to container port `80` via the ingress mesh network

> 💡 With 1 manager + 1 worker, Swarm may place 2 replicas on one node and 1 on the other — it balances automatically.

---

## 📋 Listing & Inspecting Services

```bash
# List all services in the swarm
docker service ls

# Show all tasks (containers) for a service — which node each runs on
docker service ps mynginx

# Full JSON inspection of the service definition
docker service inspect mynginx

# Readable human-friendly summary
docker service inspect --pretty mynginx
```

**Sample `docker service ls` output:**
```
ID             NAME      MODE         REPLICAS   IMAGE         PORTS
z6leq6p5sv5e   mynginx   replicated   3/3        nginx:latest   *:8080->80/tcp
```

| Column | Meaning |
|---|---|
| `REPLICAS 3/3` | 3 desired, 3 running — fully healthy |
| `REPLICAS 1/3` | Only 1 is up — Swarm is working to fix it |
| `MODE: replicated` | Fixed number of replicas across the cluster |
| `MODE: global` | One instance on **every** node (e.g., for monitoring agents) |

**Sample `docker service ps mynginx` output:**
```
ID             NAME         IMAGE         NODE            DESIRED STATE   CURRENT STATE
abc1           mynginx.1    nginx:latest  swarm-manager   Running         Running 2 min ago
def2           mynginx.2    nginx:latest  swarm-worker    Running         Running 2 min ago
ghi3           mynginx.3    nginx:latest  swarm-manager   Running         Running 2 min ago
```

---

## 📊 Viewing Service Logs

```bash
# View combined logs from all tasks/replicas
docker service logs mynginx

# Follow logs in real time
docker service logs -f mynginx

# Show last 50 lines
docker service logs --tail 50 mynginx
```

> 💡 Unlike `docker logs <container>`, `docker service logs` aggregates logs from **all replicas** across all nodes.

---

## ⚖️ Scaling a Service

Scale up or down with a single command — no downtime:

```bash
# Scale up to 5 replicas
docker service scale mynginx=5

# Scale down to 2 replicas
docker service scale mynginx=2

# Verify immediately
docker service ps mynginx
```

Swarm handles scheduling: new replicas are placed on nodes with available capacity, and removed replicas are gracefully stopped.

---

## 🔄 Rolling Updates (Zero-Downtime Deployments)

Update the image used by a service without any downtime:

```bash
# Update service to a new image version
docker service update --image nginx:latest mynginx

# More controlled update — one at a time, 10s between each
docker service update \
  --image nginx:1.27 \
  --update-parallelism 1 \
  --update-delay 10s \
  mynginx
```

**What Swarm does:**
1. Stops one old task
2. Starts one new task with the updated image
3. Waits for it to become healthy
4. Moves to the next — repeat until all replicas are updated

> ⚠️ Watch the update progress with:
> ```bash
> docker service ps mynginx
> ```

---

## ↩️ Rolling Back a Service

If a deployment goes wrong, roll back instantly to the previous configuration:

```bash
docker service rollback mynginx
```

Swarm stores the **previous service spec** automatically, so one command is all it takes.

```bash
# Confirm rollback completed
docker service ps mynginx
docker service inspect --pretty mynginx
```

---

## 🧹 Removing a Service

```bash
# Remove a single service (stops and removes all its tasks)
docker service rm mynginx

# Remove multiple services at once
docker service rm service1 service2

# Verify
docker service ls
docker ps -a   # On any node — containers should be gone
```

---

## 🌐 The Ingress Mesh Network

When you publish a port (`-p 8080:80`), Docker Swarm creates an **ingress mesh network**. This means:

```
Client Request → Port 8080 on ANY node
                    ↓
         Swarm Ingress Load Balancer (built-in)
                    ↓
         Round-robin to any healthy task
         (even if the task is on a different node)
```

```bash
# Both of these work — even if no task runs on 192.168.10.130
curl http://192.168.10.129:8080
curl http://192.168.10.130:8080
```

This is called **routing mesh** — the single most powerful Swarm networking feature.

---

## 📌 Service Modes: Replicated vs Global

```bash
# Replicated (default) — fixed number of replicas
docker service create --name mynginx --replicas 3 nginx

# Global — exactly ONE replica on EVERY node (perfect for agents/monitors)
docker service create --name node-exporter --mode global prom/node-exporter
```

---

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct |
|---|---|
| `docker service create --name ngnix ...` | `nginx` (check spelling — typo = image pull failure) |
| `docker service ps` (no service name) | `docker service ps <service-name>` |
| `docker ps` to check service tasks | Use `docker service ps <name>` (shows all nodes) |
| Removing container directly on worker | Use `docker service rm` — container will just restart |
| `docker service ls -a` | There's no `-a` flag; finished services are already removed |

---

*Navigation:*<br>[&larr; Previous Note](22-docker-swarm-setup.md) | [Next Note &rarr;](24-docker-swarm-auto-scaling.md)
