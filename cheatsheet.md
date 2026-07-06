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
docker run -d --restart always nginx # Auto-restart policy
docker update --restart unless-stopped web # Update live
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
# Add .dockerignore file to exclude .git, node_modules, .env from build context

```

---

## 📝 Advanced Dockerfile Instructions

| Instruction | Usage |
|---|---|
| `WORKDIR` | Sets working directory (e.g., `WORKDIR /app`) |
| `ENV` | Sets environment variables (`ENV VAR=value`) |
| `ARG` | Build-time variables (vanished after build) |
| `LABEL` | Adds metadata (`LABEL version="1.0"`) |
| `ADD` | Like `COPY`, but extracts tars & downloads URLs |
| `ENTRYPOINT` | Core executable (appends `docker run` args) |
| `CMD` | Default arguments (overridden by `docker run` args) |
| `HEALTHCHECK` | Container health monitoring |

---

## ⚡ Buildx & Multi-Platform

```bash
docker buildx create --use                  # Setup new builder
docker buildx inspect                       # Check supported platforms
docker buildx build --platform linux/amd64,linux/arm64 --push .
# Use BuildKit secrets securely (no history trace)
# RUN --mount=type=secret,id=token cat /run/secrets/token
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

## 🐙 Docker Compose

```bash
docker compose up -d                  # Build, create, start in background
docker compose down                   # Stop and remove containers, networks
docker compose down -v                # Also remove named volumes
docker compose ps / ls                # List services / projects
docker compose logs -f                # Follow logs for all services
docker compose exec db bash           # Shell into a specific service
docker compose config                 # Validate compose file
docker compose up -d --scale web=3    # Scale a service to 3 instances
docker compose up --build -d          # Build images before starting containers
docker exec nginx-lb nginx -s reload  # Reload Nginx config without restart
```

---

## 🐝 Docker Swarm

```bash
# Cluster Setup
docker swarm init --advertise-addr 192.168.10.129   # Init swarm on manager
docker swarm join --token <TOKEN> <manager-ip>:2377 # Join as worker
docker swarm join-token worker                       # (Re)print worker join token
docker swarm join-token manager                      # (Re)print manager join token
docker swarm leave                                   # Worker leaves swarm
docker swarm leave --force                           # Manager leaves (destroys cluster)

# Node Management
docker node ls                                       # List all nodes in cluster
docker node inspect self                             # Inspect current node
docker node inspect swarm-worker                     # Inspect a specific node
docker node inspect --pretty swarm-manager           # Human-friendly output

# Services
docker service create --name mynginx --replicas 3 -p 8080:80 nginx
docker service ls                                    # List all services
docker service ps mynginx                            # List tasks (containers) per node
docker service inspect mynginx                       # Full service details (JSON)
docker service inspect --pretty mynginx              # Human-readable details
docker service logs -f mynginx                       # Follow logs from all replicas
docker service logs --tail 50 mynginx               # Last 50 log lines

# Scaling
docker service scale mynginx=5                       # Scale to 5 replicas
docker service scale mynginx=2                       # Scale down to 2 replicas

# Rolling Updates & Rollback
docker service update --image nginx:latest mynginx   # Rolling update image
docker service update \
  --image nginx:1.27 \
  --update-parallelism 1 \
  --update-delay 10s mynginx                         # Controlled rolling update
docker service rollback mynginx                      # Rollback to previous spec

# Removing Services
docker service rm mynginx                            # Remove a service (all tasks)
docker service rm svc1 svc2                          # Remove multiple services

# Firewall (run on manager before swarm init)
firewall-cmd --permanent --add-port=2377/tcp --zone=public
firewall-cmd --permanent --add-port=7946/tcp --zone=public
firewall-cmd --permanent --add-port=7946/udp --zone=public
firewall-cmd --permanent --add-port=4789/udp --zone=public
firewall-cmd --reload

# Auto Scaling (manual script approach)
docker stats --no-stream --format "{{.CPUPerc}}"     # Snapshot CPU% of all containers
docker service inspect \
  --format '{{.Spec.Mode.Replicated.Replicas}}' mynginx  # Get current replica count
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

## 🐧 Linux Essentials (Host)

```bash
# Time Synchronization (Chrony)
timedatectl set-ntp true              # Enable NTP
systemctl restart chronyd             # Restart chrony
chronyc -a makestep                   # Force time step
chronyc sources -v                    # Verify sync

# Updates
dnf update 'docker*' -y               # Update docker packages
dnf upgrade --security -y             # Apply security patches
```

---

## 🔐 Security

```bash
# Trivy — image scanning
trivy image ubuntu:latest
trivy image --severity HIGH,CRITICAL myapp:latest
trivy image --exit-code 1 --severity CRITICAL myapp:latest  # Fail CI on CRITICAL

# seccomp profiles
docker run --security-opt seccomp=/path/to/profile.json myimage
docker run --security-opt no-new-privileges myimage           # Prevent escalation

# Linux capabilities
docker run --cap-drop ALL myimage                             # Drop everything
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myimage  # Minimal
docker inspect mycontainer | grep -A 5 -E "CapAdd|CapDrop"

# SELinux (RHEL/AlmaLinux)
docker run -v /data:/data:Z myimage                           # Private label
docker run -v /data:/data:z myimage                           # Shared label
docker run --security-opt label:type:container_t myimage

# Docker Content Trust (DCT)
export DOCKER_CONTENT_TRUST=1
docker trust key generate my_key
docker trust inspect --pretty myimage

# Hardened run command
docker run -d \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges \
  --read-only \
  --user nonroot \
  myapp:latest
```

---

## 🔑 Docker Secrets (Swarm)

```bash
echo "mypassword" | docker secret create db_password -
docker secret ls
docker secret rm db_password
docker service create --secret db_password --name mydb mysql:8.0
# Secret at: /run/secrets/db_password inside container
```

---

## ☸️ Kubernetes (Minikube)

```bash
minikube start --driver=docker && minikube status
alias kubectl="minikube kubectl --"
kubectl get nodes / pods / svc / deployments / all
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80
kubectl scale deployment nginx --replicas=5
kubectl logs -f <pod> && kubectl exec -it <pod> -- bash
kubectl apply -f manifest.yaml && kubectl delete -f manifest.yaml
minikube service nginx --url
minikube stop && minikube delete
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
| `docker compose build` | `docker compose up --build` (build and start) |
| `docker imageges` | `docker images` (typo) |
| `docker-compose up` | `docker compose up` (v2 plugin syntax) |
| `swarm init` without `--advertise-addr` | Always specify `--advertise-addr <ip>` on multi-IP hosts |
| `docker node ls` on a worker | Only managers can run `docker node ls` |
| `docker service create --name ngnix ...` | `nginx` — typo causes image pull failure |
| `docker service ps` (no name) | `docker service ps <service-name>` |
| Removing container directly on worker | Use `docker service rm` — Swarm will just restart it |
| `ENV MYSQL_ROOT_PASSWORD=secret` in Dockerfile | Use Docker secrets or `_FILE` env pattern |
| `docker run --privileged` in production | Use `--cap-drop ALL --cap-add <specific>` |
| Mounting `-v /var/run/docker.sock:/var/run/docker.sock` | Never expose Docker socket to untrusted containers |
| `docker pull` without DCT in production | `export DOCKER_CONTENT_TRUST=1` |
| Not scanning images before deploy | `trivy image --exit-code 1 --severity CRITICAL myapp` |
