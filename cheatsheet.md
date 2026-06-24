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

## 📝 Advanced Dockerfile Instructions

| Instruction | Usage |
|---|---|
| `WORKDIR` | Sets working directory (e.g., `WORKDIR /app`) |
| `ENV` | Sets environment variables (`ENV VAR=value`) |
| `LABEL` | Adds metadata (`LABEL version="1.0"`) |
| `ADD` | Like `COPY`, but extracts tars & downloads URLs |
| `ENTRYPOINT` | Core executable (appends `docker run` args) |
| `CMD` | Default arguments (overridden by `docker run` args) |

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
| `docker compose build` | `docker compose up --build` (build and start) |
| `docker imageges` | `docker images` (typo) |
| `docker-compose up` | `docker compose up` (v2 plugin syntax) |
