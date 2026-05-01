# ⚡ Docker Quick Cheat Sheet

---

## 🖼️ Images

```bash
docker pull nginx:latest          # Download image
docker images                     # List local images
docker images nginx               # Filter by name
docker images "nginx*"            # Wildcard filter (quote it!)
docker search nginx               # Search Docker Hub
docker image history nginx        # Show image layers
docker rmi nginx                  # Remove image
docker rmi $(docker images -q)    # Remove ALL images (careful!)
```

---

## 📦 Run Containers

```bash
docker run nginx                              # Run foreground
docker run -d nginx                           # Run in background
docker run -it ubuntu bash                    # Interactive shell
docker run -dit --name web nginx              # Background + attachable
docker run -d --name web -p 8080:80 nginx     # With port mapping
docker run -d --rm nginx                      # Auto-delete on stop
```

---

## 📋 Inspect & Monitor

```bash
docker ps / docker ps -a                           # Running / all containers
docker inspect web                                 # Full JSON details
docker inspect web | grep IPAddress                # Container IP
docker image inspect nginx:latest | grep -i lower  # OverlayFS layers
docker logs web / --follow / --tail 50             # Logs
docker stats / docker stats web                    # Live resource usage
docker info                                        # Daemon config & stats
docker system df / docker system df -v             # Disk usage
```

---

## 💾 Commit & Tag

```bash
docker commit <id> myimage:v1                              # Save container state
docker commit --author="ganesh" --message="msg" <id> name  # With metadata
docker tag myimage:v1 myimage:stable                       # Add alias tag
docker tag myimage:v1 jaatxog/myimage:latest               # Tag for Hub push
docker rmi myimage:stable                                  # Remove a tag only
```

---

## 🌐 Registry — Docker Hub

```bash
docker login -u <username>                    # Log in
docker logout                                 # Log out
docker tag myimage:v1 user/myimage:v1         # Tag for push
docker push user/myimage:v1                   # Push to Hub
docker pull user/myimage:v1                   # Pull from Hub
docker search jaatxog                         # Search repos
```

---

## 🏠 Local Registry

```bash
docker pull registry:2
docker run -d -p 5000:5000 --name local-registry registry:2
docker tag alpine:latest localhost:5000/alpine:latest
docker push localhost:5000/alpine:latest
docker pull localhost:5000/alpine:latest
curl http://localhost:5000/v2/_catalog        # List stored images
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
docker attach web                # Attach (Ctrl+P Ctrl+Q to exit safely)
docker cp web:/path ./local      # Copy file out
docker cp ./file web:/path       # Copy file in
```

---

## 🏗️ Build

```bash
docker build -t myapp .          # Build from ./Dockerfile
docker build -t myapp:v2 .       # With version tag
docker inspect myapp:latest      # Inspect built image
```

---

## ⚙️ Daemon (systemd)

```bash
systemctl status docker
systemctl daemon-reload && systemctl restart docker
vim /lib/systemd/system/docker.service
firewall-cmd --permanent --add-port=2375/tcp && firewall-cmd --reload
```

---

## 🔍 Internals

```bash
sudo ls -lh /var/lib/docker/
sudo ls -lh /var/lib/docker/containers/
sudo ls -lh /var/lib/docker/image/
sudo ls -lh /var/lib/docker/volumes/
yum install tree -y && tree -af /var/lib/docker/image/
updatedb && locate overlay2
```

---

## 🗑️ Cleanup

```bash
docker container prune             # Stopped containers
docker image prune                 # Dangling images
docker system prune                # Everything unused
docker system prune -a             # + unused images
docker rm $(docker ps -a -q)       # All stopped containers
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
| `docker pull ngnix` | `docker pull nginx` |
| `update db` | `updatedb` (one word) |
| `docker images -ls` | `docker image ls` |
