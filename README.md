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
