# 📈 Docker Swarm — Auto Scaling

Docker Swarm does **not have built-in automatic scaling** (unlike Kubernetes). However, you can implement CPU-based auto-scaling using a simple Bash script that monitors cluster-wide CPU usage and adjusts service replicas dynamically.

---

## 🤔 Why Auto Scaling?

| Scenario | Without Auto Scaling | With Auto Scaling |
|---|---|---|
| Traffic spike | Containers overloaded | New replicas added automatically |
| Traffic drops | Wasted resources | Replicas reduced to minimum |
| Night/Weekend | Same cost, low utilization | Scales down, saves resources |

---

## 🏗️ How It Works

The auto-scaling approach we built:

```
┌─────────────────────────────────────────────────────┐
│               auto_scale.sh (runs on manager)        │
│                                                     │
│  every 10 seconds:                                  │
│  1. docker stats → collect CPU% from ALL containers │
│  2. Sum CPU% with awk                               │
│  3. Get current replica count from service inspect  │
│                                                     │
│  if CPU > 50% AND replicas < MAX:                   │
│      → docker service scale +1                      │
│                                                     │
│  if CPU < 25% AND replicas > MIN:                   │
│      → docker service scale -1                      │
└─────────────────────────────────────────────────────┘
```

---

## 📜 The Auto-Scaling Script

This script was built and tested on our `swarm-manager` node:

```bash
#!/bin/bash

SERVICE_NAME="mynginx"
MAX_REPLICAS=10
MIN_REPLICAS=3
THRESHOLD=50    # CPU Usage %

while true; do

    # Collect total CPU% across all running containers
    CPU_USAGE=$(docker stats --no-stream --format "{{.CPUPerc}}" \
        | awk '{sum+=$1} END {print sum}')

    # Get current replica count from the service definition
    REPLICAS=$(docker service inspect \
        --format '{{.Spec.Mode.Replicated.Replicas}}' \
        $SERVICE_NAME)

    # Scale UP if CPU exceeds threshold and we're below max
    if (( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) )) && \
       [ "$REPLICAS" -lt "$MAX_REPLICAS" ]; then

        NEW_REPLICAS=$((REPLICAS + 1))
        echo "$(date): CPU at ${CPU_USAGE}% — Scaling UP to $NEW_REPLICAS replicas"
        docker service scale $SERVICE_NAME=$NEW_REPLICAS

    # Scale DOWN if CPU drops below half the threshold and we're above min
    elif (( $(echo "$CPU_USAGE < ($THRESHOLD / 2)" | bc -l) )) && \
         [ "$REPLICAS" -gt "$MIN_REPLICAS" ]; then

        NEW_REPLICAS=$((REPLICAS - 1))
        echo "$(date): CPU at ${CPU_USAGE}% — Scaling DOWN to $NEW_REPLICAS replicas"
        docker service scale $SERVICE_NAME=$NEW_REPLICAS

    else
        echo "$(date): CPU at ${CPU_USAGE}% — Replicas at $REPLICAS — No change"
    fi

    sleep 10    # Check every 10 seconds

done
```

---

## 🚀 Running the Script

```bash
# Save the script
vim auto_scale.sh

# Make it executable
chmod +x auto_scale.sh

# Run it (keep terminal open to watch it)
./auto_scale.sh

# Or run in background with nohup (persists after SSH disconnect)
nohup ./auto_scale.sh > /var/log/autoscale.log 2>&1 &
```

---

## 🔬 Simulating CPU Load to Test It

Open a second terminal and create artificial CPU load:

```bash
# Run a CPU-intensive container (uses 0.5 CPUs in a tight loop)
docker run --rm -it --cpus=".5" busybox sh -c "while true; do :; done"
```

> 💡 The `:` (colon) in bash is a no-op that loops as fast as possible — perfect for generating CPU load without any side effects.

While it's running, watch your auto-scaler output in the first terminal and verify with:

```bash
# Watch service tasks in real time
watch -n 2 docker service ps mynginx

# Or just check periodically
docker service ps mynginx
```

---

## 📊 Monitoring During Auto Scaling

```bash
# Real-time CPU/memory stats for ALL running containers (across this node)
docker stats

# Stats without live refresh (single snapshot)
docker stats --no-stream

# Stats for a specific container
docker stats <container-id>

# Monitor the service task distribution across nodes
docker service ps mynginx
```

> 💡 `docker stats` only shows containers **on the node you're connected to**. To get cluster-wide stats, you'd query each node or use a monitoring stack like Prometheus + Grafana.

---

## ⚙️ Tuning the Script

| Variable | Default | Meaning |
|---|---|---|
| `MAX_REPLICAS` | `10` | Never scale beyond this |
| `MIN_REPLICAS` | `3` | Never scale below this |
| `THRESHOLD` | `50` | CPU % that triggers scale-up |
| `THRESHOLD / 2` | `25` | CPU % that triggers scale-down |
| `sleep 10` | 10 seconds | How often to check |

**Scaling thresholds explained:**
- **Scale UP when**: CPU > 50% AND replicas < 10
- **Scale DOWN when**: CPU < 25% AND replicas > 3
- The gap between 50% and 25% prevents **thrashing** (rapid scale-up/scale-down)

---

## ⚠️ Limitations of This Approach

This is a great learning exercise. For production, be aware of:

| Limitation | Production Alternative |
|---|---|
| CPU measured only on manager node | Prometheus node-exporter on all nodes |
| No cooldown period after scaling | Add a timer variable to prevent rapid thrashing |
| No health-check awareness | Use proper readiness probes |
| Script dies if manager restarts | Use `systemd` service or external orchestrator |
| No multi-metric support (CPU + memory) | Kubernetes HPA or KEDA |

---

## 🧠 Key Takeaway

Even without a built-in autoscaler, Docker Swarm gives you all the **primitives** needed:
- `docker stats` — for metrics collection
- `docker service scale` — for adjusting replicas
- `docker service inspect` — for reading current state

A simple shell script ties them together. This is exactly how many real-world lightweight autoscalers work.

---

*Navigation:*<br>[&larr; Previous Note](23-docker-swarm-services.md)
