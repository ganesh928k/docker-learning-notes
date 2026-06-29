# 🐳 Docker Learning Notes

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-Tested-2496ED?logo=docker&logoColor=white)](#)
[![Linux](https://img.shields.io/badge/Linux-RHEL%209%20%2F%20AlmaLinux-FCC624?logo=linux&logoColor=black)](#)

> Practical, hands-on Docker notes built from real terminal sessions.
> Beginner-to-intermediate friendly. No fluff — just working commands and clear explanations.

## 🎯 Why this repo?
Most tutorials are either too high-level or overly theoretical. These notes were built from the ground up, inside a real terminal, fixing real errors. It serves as both a reference and a step-by-step interactive course.

---

## 📚 Table of Contents

| # | File | Topics Covered |
|---|------|----------------|
| 1 | [Installation & Setup](notes/01-installation-setup.md) | DNF repo, Docker CE, systemctl |
| 2 | [Docker Images](notes/02-images.md) | pull, search, history, rmi |
| 3 | [Docker Containers](notes/03-containers.md) | run, ps, stop, rm, exec, attach |
| 4 | [Container Lifecycle](notes/04-lifecycle.md) | start, pause, rename, stats, logs |
| 5 | [Port Mapping & Networking](notes/05-networking.md) | -p flag, bridge network, ip a |
| 6 | [Dockerfile](notes/06-dockerfile.md) | FROM, COPY, EXPOSE, build |
| 7 | [Docker Hub](notes/07-dockerhub.md) | pull, run public images |
| 8 | [System Cleanup](notes/08-cleanup.md) | prune, rm -f, batch delete |
| 9 | [Commit, Inspect & Tag](notes/09-commit-inspect-tag.md) | commit, inspect, tag, wildcards |
| 10 | [Login, Push & Local Registry](notes/10-login-push-local-registry.md) | Docker Hub push, private registry |
| 11 | [Internals & System Management](notes/11-internals-system-management.md) | /var/lib/docker, OverlayFS, systemd |
| 12 | [Resource Constraints & cgroups](notes/12-resource-constraints-cgroups.md) | CPU, memory, I/O, PID limits, docker update |
| 13 | [Networking Deep Dive](notes/13-networking-deep-dive.md) | bridge, host, internal, custom networks |
| 14 | [Volumes](notes/14-volumes.md) | named, anonymous, bind, backup, restore |
| 15 | [Linux Namespaces](notes/15-namespaces-pid-uts-ipc-user.md) | PID, UTS, IPC, user namespace remapping |
| 16 | [Advanced Dockerfile Instructions](notes/16-dockerfile-advanced-instructions.md) | WORKDIR, ENV, LABEL, ADD, ENTRYPOINT |
| 17 | [Practical App Deployments](notes/17-practical-app-deployments.md) | Dockerfiles for Node.js, Python, Nginx, Jenkins |
| 18 | [Multi-Stage Builds](notes/18-multistage-builds.md) | Stage separation, tiny images, Go example |
| 19 | [Docker Compose](notes/19-docker-compose.md) | docker-compose.yml, up, down, scaling, WordPress app |
| 20 | [Docker Compose Load Balancing](notes/20-docker-compose-load-balancing.md) | --scale flag, Nginx reverse proxy, live reload |
| 21 | [Linux Essentials for Docker](notes/21-linux-essentials-for-docker.md) | Chrony time sync, dnf updates, enterprise bash history |
| ⚡ | [Quick Cheat Sheet](cheatsheet.md) | All essential commands at a glance |

---

## 🚀 How to Use

1. ⭐ **Star** this repo so you can find it later
2. Read notes **in order (01 → 19)** for a structured learning path
3. Keep the **[Cheat Sheet](cheatsheet.md)** open while practising
4. Every command was tested on **AlmaLinux 9 / RHEL 9**

---

## 🗺️ Learning Path

```
Basics (01-08)          → Core Docker CLI, images, containers, cleanup
Intermediate (09-11)    → commit, tag, push, local registry, internals
Advanced (12-19)        → cgroups, networking, namespaces, advanced Dockerfiles, Docker Compose
Ecosystem (20-21)       → Compose Load Balancing, Linux Essentials (Chrony, Bash History)
```

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
│   ├── 11-internals-system-management.md
│   ├── 12-resource-constraints-cgroups.md
│   ├── 13-networking-deep-dive.md
│   ├── 14-volumes.md
│   ├── 15-namespaces-pid-uts-ipc-user.md
│   ├── 16-dockerfile-advanced-instructions.md
│   ├── 17-practical-app-deployments.md
│   ├── 18-multistage-builds.md
│   ├── 19-docker-compose.md
│   ├── 20-docker-compose-load-balancing.md
│   └── 21-linux-essentials-for-docker.md
├── examples/
│   ├── docker-compose-nginx/
│   ├── docker-compose-python/
│   ├── docker-compose-wordpress/
│   └── dockerfile-projects/
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
