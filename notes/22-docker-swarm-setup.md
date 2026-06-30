# 🐝 Docker Swarm — Setup & Cluster Initialization

Docker Swarm is Docker's native **container orchestration** tool. It lets you manage a cluster of Docker hosts (called a **Swarm**) as a single virtual system — distributing containers automatically, providing high availability, and enabling zero-downtime deployments.

---

## 🤔 Why Swarm? (The Problem with Single-Host Docker)

When you run Docker on a single machine, you have a **single point of failure**:

| Problem | Impact |
|---|---|
| Host goes down | All containers die |
| High load on one machine | No way to spread the load |
| Manual scaling | `docker run` one container at a time |
| Zero-downtime updates | Requires complex scripting |

Docker Swarm solves all of this by clustering multiple machines together.

---

## 🗺️ Swarm Architecture

A Swarm cluster has two types of nodes:

```
┌─────────────────────────────────────────────────────┐
│                  DOCKER SWARM CLUSTER                │
│                                                     │
│  ┌──────────────────────┐                           │
│  │   MANAGER NODE       │  ← controls the cluster   │
│  │  192.168.10.129      │  ← runs the Raft log       │
│  │  (swarm-manager)     │  ← can also run tasks      │
│  └──────────┬───────────┘                           │
│             │ issues tasks                          │
│             ▼                                       │
│  ┌──────────────────────┐                           │
│  │   WORKER NODE        │  ← runs containers only   │
│  │  192.168.10.130      │  ← reports back to mgr     │
│  │  (swarm-worker)      │                           │
│  └──────────────────────┘                           │
└─────────────────────────────────────────────────────┘
```

| Node Type | Responsibility |
|---|---|
| **Manager** | Scheduling, orchestration, cluster state (Raft consensus) |
| **Worker** | Executes tasks (runs containers), reports health back to manager |

> 💡 A manager can also run containers (tasks). In production with 3+ managers, you may want managers to be dedicated to orchestration only.

---

## 🛠️ Lab Setup

Our lab uses two AlmaLinux 9 VMs:

| Role | Hostname | IP Address |
|---|---|---|
| Manager | `swarm-manager` | `192.168.10.129` |
| Worker | `swarm-worker` | `192.168.10.130` |

Both nodes have:
- Docker CE 29.6.1 installed
- `firewalld` running
- Port `2377/tcp` open (Swarm management traffic)

---

## 🔥 Firewall Preparation (Manager Node)

Before initializing, open the required ports on the **manager**:

```bash
# Port 2377 — Swarm cluster management communication
firewall-cmd --permanent --add-port=2377/tcp --zone=public
firewall-cmd --reload

# Verify
firewall-cmd --zone=public --list-all
```

> ⚠️ **All Swarm ports to know:**
> | Port | Protocol | Purpose |
> |------|----------|---------|
> | `2377` | TCP | Cluster management (manager only) |
> | `7946` | TCP + UDP | Node-to-node communication |
> | `4789` | UDP | Overlay network traffic (VXLAN) |

For a production cluster, open all three. Our lab only needs `2377` since we use a single overlay on one subnet.

---

## 🚀 Step 1 — Initialize the Swarm (Manager Node)

Run this on `swarm-manager` (`192.168.10.129`):

```bash
docker swarm init --advertise-addr 192.168.10.129
```

**What this does:**
- Promotes this host to **Swarm Manager**
- Generates a **join token** for workers
- Creates an encrypted overlay network (`ingress`)
- Starts the **Raft consensus** engine to store cluster state

**Expected output:**
```
Swarm initialized: current node (abc123...) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3y8qf5jbo0prnvz2fxo9ifxi3m1k6x287dfomxawq8atqi0xuy-ehnrqef4yf30vz4wt0as9fh31 192.168.10.129:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

> 📌 **Save that join token!** You need it to add worker nodes.

---

## 🔗 Step 2 — Join the Worker Node

Run this on `swarm-worker` (`192.168.10.130`):

```bash
docker swarm join \
  --token SWMTKN-1-3y8qf5jbo0prnvz2fxo9ifxi3m1k6x287dfomxawq8atqi0xuy-ehnrqef4yf30vz4wt0as9fh31 \
  192.168.10.129:2377
```

**Expected output:**
```
This node joined a swarm as a worker.
```

> 💡 If you lose the token, regenerate it from the manager:
> ```bash
> docker swarm join-token worker    # Get worker join token
> docker swarm join-token manager   # Get manager join token
> ```

---

## ✅ Step 3 — Verify the Cluster

Back on the **manager**, confirm both nodes are in the cluster:

```bash
docker node ls
```

**Expected output:**
```
ID                            HOSTNAME        STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
abc123def456 *                swarm-manager   Ready     Active         Leader           29.6.1
xyz789ghi012                  swarm-worker    Ready     Active                          29.6.1
```

| Column | Meaning |
|---|---|
| `*` (asterisk) | The node you are currently on |
| `STATUS: Ready` | Node is healthy and connected |
| `AVAILABILITY: Active` | Node is eligible to receive tasks |
| `MANAGER STATUS: Leader` | This is the active manager running the Raft log |

---

## 🔍 Inspecting Nodes

```bash
# Inspect the current (manager) node
docker node inspect self

# Inspect a specific node
docker node inspect swarm-worker

# Inspect with a readable summary
docker node inspect --pretty swarm-manager
```

---

## ↩️ Leaving the Swarm

```bash
# On a worker — leave gracefully
docker swarm leave

# On a manager — force leave (breaks cluster if only one manager)
docker swarm leave --force
```

---

## ⚠️ Common Mistakes

| ❌ Wrong | ✅ Correct |
|---|---|
| Running `swarm init` without `--advertise-addr` on multi-IP hosts | Always specify `--advertise-addr <manager-ip>` |
| Forgetting to open port `2377` in firewalld | Open before `swarm init` |
| Running `docker node ls` on a worker | Only managers can run `docker node ls` |
| `docker swarm leave` on the only manager | Use `--force` but you will destroy the cluster |

---

*Navigation:*<br>[&larr; Previous Note](21-linux-essentials-for-docker.md) | [Next Note &rarr;](23-docker-swarm-services.md)
