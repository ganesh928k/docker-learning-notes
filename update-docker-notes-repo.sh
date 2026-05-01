#!/usr/bin/env bash
# ============================================================
#  update-docker-notes-repo.sh
#  Adds new notes (09, 10, 11) + updated cheatsheet + README
#  Run from INSIDE your cloned repo directory:
#    cd docker-learning-notes
#    bash update-docker-notes-repo.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
die()     { echo -e "${RED}[ERR]${RESET}   $*" >&2; exit 1; }

echo -e "\n${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║   Docker Notes — Update Script (Session 2)       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${RESET}\n"

# ── sanity checks ─────────────────────────────────────────
command -v git &>/dev/null || die "git not found."
[[ -f "README.md" ]] || die "Run this from inside your cloned repo directory!"
[[ -d "notes" ]]    || die "'notes/' directory not found. Wrong directory?"

success "Repo directory confirmed: $(pwd)"

# ── PAT for push ──────────────────────────────────────────
read -rsp "$(echo -e ${CYAN}Paste your GitHub PAT \(hidden\):${RESET} )" GIT_PAT
echo ""
[[ -z "${GIT_PAT}" ]] && die "PAT cannot be empty."
git remote set-url origin "https://ganesh928k:${GIT_PAT}@github.com/ganesh928k/docker-learning-notes.git"

# ── pull latest first ─────────────────────────────────────
info "Pulling latest from origin/main..."
git pull origin main
success "Up to date."

# ════════════════════════════════════════════════════════════
#  NEW FILE: notes/09-commit-inspect-tag.md
# ════════════════════════════════════════════════════════════
info "Writing notes/09-commit-inspect-tag.md ..."
cat > notes/09-commit-inspect-tag.md << 'EOF'
# 09 — Commit, Inspect & Tag

---

## docker commit — Save a container as an image

You ran commands inside a container (e.g. installed nginx, curl), and you want to save that modified state as a new image.

```bash
docker commit <container_id> <new_image_name>:<tag>
```

### Basic commit
```bash
docker run -it ubuntu bash
# ... install stuff inside ...
docker commit 188434b948da ubuntu-nginx:latest
```

### Commit with metadata (author + message)
```bash
docker commit \
  --author="ganesh" \
  --message="curl image created" \
  1fcb2f48616f curl-ubuntu:1st
```

| Flag | Purpose |
|---|---|
| `--author` | Who made this image |
| `--message` | Describe what changed |

> 💡 **When to use commit vs Dockerfile?**
> - `commit` = quick, ad-hoc snapshots during exploration
> - `Dockerfile` = reproducible, version-controlled builds ← preferred for real projects

### Verify the committed image
```bash
docker images
docker run -it curl-ubuntu:1st bash
```

---

## docker inspect — Deep dive into any image or container

Returns a full JSON object with every detail about an image or container.

```bash
docker inspect ubuntu:latest          # inspect an image
docker inspect curl-ubuntu:1st        # inspect a committed image
docker inspect <container_id>         # inspect a running/stopped container
```

### Useful grep filters
```bash
docker image inspect nginx:latest | grep -i upper   # UpperDir (writable layer)
docker image inspect nginx:latest | grep -i lower   # LowerDir (read-only layers)
docker inspect <container_id> | grep IPAddress      # container's internal IP
docker inspect <container_id> | grep Mounts         # volume mount info
```

> The `UpperDir` and `LowerDir` are part of the **OverlayFS** filesystem Docker uses.
> Each image layer = a LowerDir. The writable container layer = UpperDir.

---

## docker tag — Rename or alias an image

`tag` does NOT copy the image — it just adds another name pointing to the same image ID.

```bash
docker tag 0395d4f646e9 mybitnami:stable
docker tag mybitnami:stable mybitnami:v2
docker tag apache-rhel9-ganesh928:latest jaatxog/apache-rhel9-ganesh928:latest
```

### Remove a tag (without deleting the image)
```bash
docker rmi mybitnami:stable
# Only removes the tag — image still exists if another tag points to it
```

---

## Filter images by name

```bash
docker images nginx               # exact match
docker images "nginx*"            # wildcard — always quote it
```

> ⚠️ `docker images *nginx` without quotes: shell expands `*` before Docker sees it. Always quote wildcards.

---

## Section Summary

| Command | What it does |
|---|---|
| `docker commit <id> name:tag` | Save container state as new image |
| `docker inspect <name/id>` | Full JSON details of image or container |
| `docker tag <src> <dest>` | Add a new name/tag to an existing image |
| `docker images "nginx*"` | Filter image list by name |
EOF
success "09-commit-inspect-tag.md written."

# ════════════════════════════════════════════════════════════
#  NEW FILE: notes/10-login-push-local-registry.md
# ════════════════════════════════════════════════════════════
info "Writing notes/10-login-push-local-registry.md ..."
cat > notes/10-login-push-local-registry.md << 'EOF'
# 10 — Docker Hub Login, Push & Local Registry

---

## Pushing your own image to Docker Hub

### Step 1 — Log in
```bash
docker login -u jaatxog
# prompts for password / access token
```

> 💡 Use a **Docker Hub Access Token** instead of your real password.
> Create one at: https://hub.docker.com → Account Settings → Security → New Access Token

### Step 2 — Tag for Docker Hub

Image must be named `<dockerhub_username>/<repo>:<tag>` before pushing.

```bash
docker tag apache-rhel9-ganesh928:latest jaatxog/apache-rhel9-ganesh928:latest
docker images   # verify the new tag exists
```

### Step 3 — Push
```bash
docker push jaatxog/apache-rhel9-ganesh928:latest
```

Docker pushes layer by layer. Already-uploaded layers are skipped (cache).

### Step 4 — Log out
```bash
docker logout
```

### Step 5 — Pull it back to verify
```bash
docker pull jaatxog/apache-rhel9-ganesh928
docker run -dit -p 8080:80 jaatxog/apache-rhel9-ganesh928:latest
```

### Search your own Docker Hub account
```bash
docker search jaatxog
```

---

## Running a Local Private Registry

A local registry is a **private Docker Hub running on your own machine** — nothing leaves your network.

### Pull the official registry image
```bash
docker pull registry:2
```

### Start the local registry
```bash
docker run -d -p 5000:5000 --name local-registry registry:2
```

| Part | Meaning |
|---|---|
| `-d` | Run in background |
| `-p 5000:5000` | Expose registry API on host port 5000 |
| `--name local-registry` | Friendly name |

### Tag an image for local registry

Format: `localhost:5000/<image>:<tag>`

```bash
docker pull alpine:latest
docker tag alpine:latest localhost:5000/alpine:latest
docker images   # see both tags
```

### Push to local registry
```bash
docker push localhost:5000/alpine:latest
```

### Verify what's stored
```bash
curl -X GET http://localhost:5000/v2/_catalog
# {"repositories":["alpine"]}
```

### Delete local copies and pull back from local registry
```bash
docker rmi alpine:latest
docker rmi localhost:5000/alpine:latest
docker pull localhost:5000/alpine:latest
```

### Run from local registry
```bash
docker run -it --name myalpine localhost:5000/alpine:latest
```

---

## Local Registry vs Docker Hub

| | Docker Hub | Local Registry |
|---|---|---|
| Location | Cloud | Your own server |
| Privacy | Public (or paid private) | Fully private |
| Internet needed | Yes | No |
| Speed | Depends on bandwidth | Fast (local LAN) |
| Use case | Share with world | Internal/air-gapped teams |

---

## Full build → push workflow

```bash
vim Dockerfile
docker build -t apache-rhel9-ganesh928 .
docker run -d -p 8080:80 apache-rhel9-ganesh928:latest   # test locally
docker tag apache-rhel9-ganesh928:latest jaatxog/apache-rhel9-ganesh928:latest
docker login -u jaatxog
docker push jaatxog/apache-rhel9-ganesh928:latest
docker inspect apache-rhel9-ganesh928:latest             # verify
```

---

## Section Summary

| Command | What it does |
|---|---|
| `docker login -u <user>` | Authenticate to Docker Hub |
| `docker logout` | Log out |
| `docker push <image>` | Upload to registry |
| `docker pull <image>` | Download from registry |
| `docker run -d -p 5000:5000 registry:2` | Start local private registry |
| `curl localhost:5000/v2/_catalog` | List images in local registry |
EOF
success "10-login-push-local-registry.md written."

# ════════════════════════════════════════════════════════════
#  NEW FILE: notes/11-internals-system-management.md
# ════════════════════════════════════════════════════════════
info "Writing notes/11-internals-system-management.md ..."
cat > notes/11-internals-system-management.md << 'EOF'
# 11 — Docker Internals & System Management

Understanding what lives on disk and how Docker's daemon is configured.

---

## docker system df — Disk usage

```bash
docker system df          # summary table
docker system df -v       # verbose: per-image, per-container, per-volume
```

Sample output:
```
TYPE            TOTAL     ACTIVE    SIZE      RECLAIMABLE
Images          5         2         1.2GB     800MB (66%)
Containers      3         1         12MB      8MB
Local Volumes   2         1         500MB     0B
Build Cache     10        0         300MB     300MB
```

> `RECLAIMABLE` = disk space you can free with `docker system prune`

---

## docker info — Full daemon configuration

```bash
docker info
```

Shows: Docker version, container/image counts, storage driver (`overlay2`),
logging driver, cgroup driver, kernel version, OS, RAM, CPUs.

> 💡 First thing to run when debugging Docker on a new machine.

---

## /var/lib/docker — Where Docker stores everything

Requires `root` (or `sudo`) to browse.

```bash
sudo ls -lh /var/lib/docker/
```

```
containers/    ← config + logs per container
image/         ← image metadata and layer references
network/       ← network configs
volumes/       ← named volumes data
buildkit/      ← build cache
plugins/       ← plugin data
engine-id      ← unique ID for this Docker daemon
```

### Exploring subdirectories
```bash
sudo ls -lh /var/lib/docker/containers/
sudo ls -lh /var/lib/docker/image/
sudo ls -lh /var/lib/docker/volumes/
sudo ls -lh /var/lib/docker/network/files/
sudo ls -lh /var/lib/docker/buildkit/
```

> ⚠️ Never manually edit/delete files here — always use Docker CLI.
> Manual changes corrupt Docker's internal state.

---

## OverlayFS — How Docker layers work

Docker uses **OverlayFS** (overlay2 driver) to stack image layers efficiently.

```bash
docker image inspect nginx:latest | grep -i upper   # UpperDir (writable)
docker image inspect nginx:latest | grep -i lower   # LowerDir (read-only layers)
```

| Layer | Description |
|---|---|
| **LowerDir** | Read-only image layers (shared between containers) |
| **UpperDir** | Writable layer unique to this container |
| **MergedDir** | Union view the container sees |

```bash
# Visualise with tree
yum install tree -y
tree -af /var/lib/docker/image/
tree -af . | grep layer

# Find overlay dirs on disk
updatedb
locate overlay2
locate overlay
```

---

## Docker daemon — systemd service

```bash
systemctl status docker                               # check daemon health
systemctl restart docker                              # restart daemon
systemctl daemon-reload && systemctl restart docker   # after editing .service file
```

### Edit the service file
```bash
vim /lib/systemd/system/docker.service
```

### Enable Docker TCP API (port 2375)

In the `[Service]` section, find `ExecStart` and append `-H tcp://0.0.0.0:2375`:

```ini
ExecStart=/usr/bin/dockerd \
  -H fd:// \
  -H tcp://0.0.0.0:2375 \
  --containerd=/run/containerd/containerd.sock
```

```bash
systemctl daemon-reload
systemctl restart docker
firewall-cmd --permanent --add-port=2375/tcp
firewall-cmd --reload
```

> ⚠️ Port 2375 is **unauthenticated**. Use only on trusted internal networks.
> For internet-facing access, use port **2376 with TLS**.

---

## Useful system commands

```bash
cat /etc/os-release       # check OS version (inside container or on host)
htop                      # real-time process monitor on host
updatedb                  # refresh the locate file index
locate <filename>         # find files fast
```

---

## Section Summary

| Command | What it does |
|---|---|
| `docker system df` | Disk usage summary |
| `docker system df -v` | Per-object breakdown |
| `docker info` | Full daemon config |
| `sudo ls -lh /var/lib/docker/` | Browse Docker data root |
| `docker image inspect nginx \| grep -i lower` | Show OverlayFS layers |
| `systemctl daemon-reload && systemctl restart docker` | Apply daemon config changes |
| `tree -af /var/lib/docker/image/` | Visualise layer structure |
EOF
success "11-internals-system-management.md written."

# ════════════════════════════════════════════════════════════
#  UPDATED FILE: cheatsheet.md
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
EOF
success "cheatsheet.md updated."

# ════════════════════════════════════════════════════════════
#  UPDATED FILE: README.md
# ════════════════════════════════════════════════════════════
info "Updating README.md ..."
cat > README.md << 'EOF'
# 🐳 Docker Learning Notes

> Practical, hands-on Docker notes built from real terminal sessions.
> Beginner-to-intermediate friendly. No fluff — just working commands and clear explanations.

---

## 📚 Table of Contents

| # | File | Topics Covered |
|---|------|---------------|
| 1 | [Installation & Setup](notes/01-installation-setup.md) | DNF repo, Docker CE, systemctl |
| 2 | [Docker Images](notes/02-images.md) | pull, push, search, history, rmi |
| 3 | [Docker Containers](notes/03-containers.md) | run, ps, stop, rm, exec, attach |
| 4 | [Container Lifecycle](notes/04-lifecycle.md) | start, pause, unpause, rename, stats |
| 5 | [Port Mapping & Networking](notes/05-networking.md) | -p flag, bridge network, ip a |
| 6 | [Dockerfile](notes/06-dockerfile.md) | FROM, COPY, EXPOSE, build |
| 7 | [Docker Hub](notes/07-dockerhub.md) | pull, run public images |
| 8 | [System Cleanup](notes/08-cleanup.md) | prune, rm -f, batch delete |
| 9 | [Commit, Inspect & Tag](notes/09-commit-inspect-tag.md) | commit, inspect, tag, wildcards |
| 10 | [Login, Push & Local Registry](notes/10-login-push-local-registry.md) | Docker Hub push, private registry |
| 11 | [Internals & System Management](notes/11-internals-system-management.md) | /var/lib/docker, OverlayFS, systemd daemon |
| ⚡ | [Quick Cheat Sheet](cheatsheet.md) | All essential commands at a glance |

---

## 🚀 How to Use

1. ⭐ **Star** this repo so you can find it later
2. Read notes **in order (01 → 11)** for a structured learning path
3. Keep the **[Cheat Sheet](cheatsheet.md)** open as a quick reference while practising
4. Every command was tested on **AlmaLinux 9 / RHEL 9**

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
│   └── 11-internals-system-management.md
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
info "Staging changes..."
git add .

info "Committing..."
git commit -m "feat: add session-2 notes (commit/inspect/tag, registry, internals)

New notes:
- 09-commit-inspect-tag.md: docker commit, inspect, tag, wildcard filtering
- 10-login-push-local-registry.md: Docker Hub push workflow, local registry
- 11-internals-system-management.md: /var/lib/docker, OverlayFS, systemd daemon

Updated:
- cheatsheet.md: added new commands from session 2
- README.md: updated table of contents (8 → 11 notes)"

info "Pushing to GitHub..."
git push origin main

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║   ✅  Repo updated! 3 new notes + updated cheatsheet.    ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  🔗 ${CYAN}https://github.com/ganesh928k/docker-learning-notes${RESET}"
echo ""
echo -e "  ${GREEN}✔${RESET} notes/09-commit-inspect-tag.md        (NEW)"
echo -e "  ${GREEN}✔${RESET} notes/10-login-push-local-registry.md (NEW)"
echo -e "  ${GREEN}✔${RESET} notes/11-internals-system-management.md (NEW)"
echo -e "  ${GREEN}✔${RESET} cheatsheet.md                          (UPDATED)"
echo -e "  ${GREEN}✔${RESET} README.md                              (UPDATED)"
echo ""
