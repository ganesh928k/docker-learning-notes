# 01 — Installation & Setup (AlmaLinux 9 / RHEL 9)

## Step 1 — Remove old Docker packages

```bash
sudo dnf remove docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate \
  docker-selinux docker-engine-selinux docker-engine
```

Cleans out any conflicting old versions before installing Docker CE.

---

## Step 2 — Add the Docker repository

```bash
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf repolist   # verify repo was added
```

> **Tip:** Always use the RHEL repo URL on AlmaLinux 9, not the Fedora URL.

---

## Step 3 — Install Docker CE

```bash
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

| Package | Purpose |
|---|---|
| `docker-ce` | Docker Community Edition engine |
| `docker-ce-cli` | CLI tools |
| `containerd.io` | Low-level container runtime |
| `docker-buildx-plugin` | Extended `docker build` features |
| `docker-compose-plugin` | `docker compose` command |

---

## Step 4 — Enable and start Docker

```bash
sudo systemctl enable --now docker
```

- `enable` = start on every boot
- `--now` = start immediately too

---

## Step 5 — Verify installation

```bash
sudo docker run hello-world   # pull and run test container
docker --version              # short version string
docker version                # full client + server details
```

---

## Optional — Run Docker without sudo

```bash
sudo usermod -aG docker $USER
newgrp docker          # apply without logging out
docker run hello-world # should work without sudo now
```
