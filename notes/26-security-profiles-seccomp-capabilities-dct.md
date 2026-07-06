# 🔐 26 — Docker Security Profiles: seccomp, Capabilities, SELinux & AppArmor

> **Session 8** | Tested on: AlmaLinux 9 | Author: Ganesh

Docker runs containers in **isolated namespaces** but shares the host kernel. Security profiles restrict what system calls containers can make and what kernel features they can access — adding a critical defence-in-depth layer.

---

## 🗂️ Overview of Linux Security Mechanisms in Docker

| Mechanism | Platform | Purpose |
|---|---|---|
| **seccomp** | All Linux | Block specific system calls |
| **Linux Capabilities** | All Linux | Granular root privilege control |
| **SELinux** | RHEL / Fedora / AlmaLinux | Mandatory access control labels |
| **AppArmor** | Debian / Ubuntu | Path-based mandatory access control |
| **User Namespaces** | All Linux | Remap container root to unprivileged host UID |
| **Docker Content Trust (DCT)** | All | Cryptographic image authenticity |

---

## 1️⃣ seccomp (Secure Computing Mode)

**seccomp** filters which Linux **system calls** (syscalls) a container process is allowed to make. Docker applies a **default seccomp profile** to every container automatically.

### How Docker's Default seccomp Profile Works

```
Linux has ~350+ system calls.
Docker's default profile BLOCKS ~44 of them.
This prevents containers from:
  - Loading kernel modules (insmod)
  - Changing the system clock (clock_settime)
  - Mounting filesystems (mount)
  - Creating new namespaces (unshare)
  - ... and ~40 more dangerous syscalls
```

```bash
# Verify default profile is applied
docker info | grep -i seccomp
# Output: Security Options: seccomp Profile: builtin

# Run container with default seccomp — insmod is blocked
docker run --rm alpine sh -c "insmod /lib/modules/$(uname -r)/modules.builtin"
# Error: Operation not permitted (seccomp blocks it)

# Run with --privileged disables seccomp entirely ← DANGEROUS
docker run --rm --privileged alpine sh -c "echo 'All syscalls allowed'"
```

### Custom seccomp Profile

You can write a JSON profile to allow/deny specific syscalls.

```bash
# Lab: Create a profile that blocks 'chmod'
mkdir seccomp && cd seccomp
vim seccomp-profile.json
```

```json
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": [
    {
      "name": "chmod",
      "action": "SCMP_ACT_ERRNO",
      "args": []
    }
  ]
}
```

```bash
# Apply the custom profile
docker run -it --name my-con \
  --security-opt seccomp=seccomp-profile.json \
  alpine:latest sh

# Inside the container — chmod is blocked!
chmod 777 /tmp/test
# chmod: /tmp/test: Operation not permitted

# Exit
exit
```

### seccomp Actions

| Action | Meaning |
|---|---|
| `SCMP_ACT_ALLOW` | Allow the syscall |
| `SCMP_ACT_ERRNO` | Block and return "Operation not permitted" |
| `SCMP_ACT_KILL` | Kill the process attempting the syscall |
| `SCMP_ACT_LOG` | Allow but log (audit mode) |

```bash
# Disable seccomp entirely (for debugging only)
docker run --rm --security-opt seccomp=unconfined alpine sh

# Use no-new-privileges (prevents privilege escalation even if exploit succeeds)
docker run --rm --security-opt no-new-privileges alpine sh
```

> [!IMPORTANT]
> Docker's default seccomp profile disables ~44 syscalls — a balanced security/compatibility trade-off. Always use it (it's on by default). Only disable it if you have a specific need and compensate with other controls.

---

## 2️⃣ Linux Capabilities

Traditional Unix has only two privilege modes: **root** (UID 0, all-powerful) and **non-root**. Linux **capabilities** break root's privileges into ~40 independent units so you can grant only what's needed.

### Common Capabilities

| Capability | What It Allows |
|---|---|
| `CAP_NET_ADMIN` | Configure network interfaces, firewall rules |
| `CAP_SYS_TIME` | Set the system clock |
| `CAP_CHOWN` | Change file ownership |
| `CAP_SYS_ADMIN` | Almost everything (mini-root) — avoid! |
| `CAP_NET_RAW` | Use raw sockets (ping, packet crafting) |
| `CAP_KILL` | Send signals to any process |
| `CAP_SYS_PTRACE` | Trace/debug other processes |

### Docker's Default Capability Set

Docker grants a **reduced set** of capabilities by default (not all of root's). Key ones included: `CHOWN`, `DAC_OVERRIDE`, `FSETID`, `FOWNER`, `NET_RAW`, `SETGID`, `SETUID`, `SETPCAP`, `NET_BIND_SERVICE`.

### Dropping and Adding Capabilities

```bash
# Drop ALL capabilities — most minimal possible
docker run -dit --cap-drop ALL alpine

# Add back only what you need (e.g., chown but nothing else)
docker run -itd --cap-drop ALL --cap-add CHOWN alpine:latest sh

# Verify inside container
docker exec -it hardcore_jennings sh
# Try chown — it works
chown root /tmp/testfile
# Try something else — it's blocked
ping 8.8.8.8  # ping needs CAP_NET_RAW — blocked!
```

```bash
# Drop a specific capability from default set
# Example: prevent container from changing ownership
docker run -dit --cap-drop CHOWN alpine

# Example: drop network configuration capability
docker run -dit --cap-drop NET_ADMIN myapp

# Check effective capabilities of a running container
docker inspect mycontainer | grep -A 20 CapAdd
docker inspect mycontainer | grep -A 20 CapDrop
```

### Real-World Example — Minimal Web Server

```dockerfile
FROM nginx:alpine
# Remove extra packages
RUN apk del curl wget
```

```bash
docker run -d \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add CHOWN \
  --cap-add SETUID \
  --cap-add SETGID \
  --security-opt no-new-privileges \
  nginx:alpine
```

---

## 3️⃣ SELinux (RHEL / AlmaLinux / Fedora)

**SELinux** (Security-Enhanced Linux) enforces **mandatory access control (MAC)** using labels. Every file, process, and network port has an SELinux label — and rules define what labels can interact.

### Docker + SELinux

```bash
# Check if SELinux is enforcing
getenforce
# Enforcing

# Check Docker's SELinux status
docker info | grep -i selinux
# Security Options: selinux

# Run container with SELinux label
docker run --security-opt label:type:container_t myimage

# Run container with SELinux disabled (use sparingly)
docker run --security-opt label:disable myimage
```

### SELinux Labels for Volumes

```bash
# Without :z or :Z — SELinux may DENY container access to bind-mounts
docker run -v /host/data:/data myimage  # ← May get permission denied

# :z — label the volume (shared between containers)
docker run -v /host/data:/data:z myimage

# :Z — label the volume (private to this container)
docker run -v /host/data:/data:Z myimage
```

> [!NOTE]
> On RHEL/AlmaLinux with SELinux Enforcing, always use `:z` or `:Z` on bind-mounts or containers will be denied access to host directories.

```bash
# Enable userns-remap with SELinux
# /etc/docker/daemon.json:
# { "userns-remap": "default" }
# Then restart: systemctl restart docker
```

---

## 4️⃣ AppArmor (Debian / Ubuntu)

**AppArmor** enforces **path-based access control** — it restricts which files, directories, and syscalls a container can access.

```bash
# Check AppArmor status (Debian/Ubuntu)
aa-status

# Docker's default AppArmor profile
# Named: docker-default
# Loaded automatically for all containers

# Run with a custom AppArmor profile
docker run --security-opt apparmor=my-custom-profile myimage

# Run without AppArmor (unconfined)
docker run --security-opt apparmor=unconfined myimage
```

> [!NOTE]
> AppArmor is Debian/Ubuntu-specific. On RHEL/AlmaLinux, use **SELinux** instead. Both provide similar mandatory access control guarantees.

---

## 5️⃣ Docker Content Trust (DCT) — Final Security Layer

**Docker Content Trust (DCT)** uses **Notary** (based on The Update Framework) to cryptographically sign and verify images. When enabled, Docker **refuses to pull unsigned images**.

### How DCT Works

```
Publisher signs image → signature stored in Notary server → 
Consumer's Docker daemon verifies signature before pull → 
Tampering = verification failure = pull refused
```

### Enable DCT

```bash
# Check current DCT status (0 = disabled, 1 = enabled)
echo $DOCKER_CONTENT_TRUST

# Enable DCT for this terminal session
export DOCKER_CONTENT_TRUST=1

# Verify
echo $DOCKER_CONTENT_TRUST  # 1

# Now any pull will verify signature
docker pull nginx  # Only succeeds if nginx is signed (it is — by Docker)

# Unsigned image pull fails with DCT=1
docker pull someunsignedimage  # Error: No valid trust data
```

### Generate Signing Keys

```bash
# Generate a new key pair for signing
docker trust key generate my_key
# Generates: ~/.docker/trust/private/my_key.key

# Sign and push an image
docker login -u yourusername

# Tag your image
docker tag nginx:latest yourusername/nginx-signed:latest

# Push with signing (DCT must be enabled)
export DOCKER_CONTENT_TRUST=1
docker push yourusername/nginx-signed:latest
# Prompts for passphrase, signs the image, pushes both image + signature
```

### View Trust Information

```bash
# Check trust status of an image
docker trust inspect --pretty yourusername/nginx-signed:latest

# List signers for a repo
docker trust inspect yourusername/nginx-signed
```

### Disable DCT (temporarily)

```bash
# Disable for current session
export DOCKER_CONTENT_TRUST=0

# Or use --disable-content-trust flag per command
docker pull --disable-content-trust myimage:latest
```

> [!TIP]
> For production environments, set `DOCKER_CONTENT_TRUST=1` permanently in `/etc/environment` or in your CI/CD pipeline environment variables. This prevents accidental deployment of unsigned or tampered images.

---

## 6️⃣ User Namespace Remapping

Covered in [Note 15](15-namespaces-pid-uts-ipc-user.md) — key point for security:

```bash
# /etc/docker/daemon.json
{
  "userns-remap": "default"
}

# This maps container root (UID 0) → host UID 100000+
# So if a container escapes, it gets UID 100000 on the host (unprivileged)
```

---

## 📊 Security Layers Summary

```
docker run myapp
    │
    ├── seccomp profile      → Blocks ~44 dangerous syscalls
    ├── Linux capabilities   → Limits what root-inside-container can do
    ├── SELinux/AppArmor     → Labels/paths restrict file access
    ├── User namespaces      → Container root ≠ Host root
    ├── Network policies     → Inter-container isolation
    └── Read-only filesystem → --read-only flag
```

---

## ⚡ Quick Reference

```bash
# seccomp
docker run --security-opt seccomp=/path/to/profile.json myimage
docker run --security-opt seccomp=unconfined myimage   # Disable (dangerous)

# Capabilities
docker run --cap-drop ALL --cap-add NET_BIND_SERVICE myimage
docker run --cap-drop CHOWN myimage

# SELinux
docker run --security-opt label:type:container_t myimage
docker run -v /data:/data:Z myimage   # Private SELinux label

# AppArmor
docker run --security-opt apparmor=docker-default myimage

# no-new-privileges (always use in prod!)
docker run --security-opt no-new-privileges myimage

# DCT
export DOCKER_CONTENT_TRUST=1
docker pull nginx
docker trust inspect --pretty nginx

# Inspect security options applied to a running container
docker inspect mycontainer | grep -A 10 SecurityOpt
```

---

> [!TIP]
> **Next:** [27 — Container Privilege Escalation (Understanding Attack Vectors)](27-container-privilege-escalation.md)

---

*← [25 — Docker Security Fundamentals](25-docker-security-fundamentals.md) | [27 — Container Privilege Escalation →](27-container-privilege-escalation.md)*
