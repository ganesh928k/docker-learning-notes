# 🔑 29 — Docker Secrets & Sensitive Data Management

> **Session 8** | Tested on: AlmaLinux 9 | Author: Ganesh

Handling sensitive data (passwords, API keys, certificates) incorrectly is one of the most common Docker security mistakes. This note covers the **wrong ways** (to understand what to avoid) and the **right ways** to manage secrets in Docker.

---

## ❌ The Wrong Way — Secrets in Environment Variables

The most common mistake: embedding credentials directly in Dockerfiles or environment variables.

```dockerfile
# ❌ NEVER DO THIS — credentials baked into the image layer
FROM mysql/mysql-server:latest
ENV MYSQL_ROOT_PASSWORD=redhat        # ← Visible in docker inspect
ENV MYSQL_DATABASE=users
ENV MYSQL_USER=root
ENV MYSQL_PASSWORD=redhat             # ← Anyone with image access sees this
ENV MYSQL_ROOT_HOST=mysql-db
```

### Why This Is Dangerous

```bash
# Anyone with Docker access can read these
docker inspect mycontainer | grep -i password
# or
docker history myimage   # Shows ENV layers with values
# or  
docker run myimage env   # Prints all env vars including secrets
```

The issue: **environment variables are visible in `docker inspect`, image history, process listings, and child processes**.

---

## ✅ The Right Ways

### Option 1 — Docker Swarm Secrets (Built-in)

Docker Swarm has a **native secrets manager**. Secrets are:
- Stored encrypted (AES-256-GCM) in the Swarm's Raft log
- Only available to services explicitly granted access
- Mounted as **files** in `/run/secrets/` inside the container (not environment variables)
- Never visible in `docker inspect`

```bash
# Create a secret from stdin (most secure — not stored in shell history)
echo "my_super_secret_password" | docker secret create db_password -

# Create from a file
docker secret create db_password ./password.txt

# List secrets (values are NEVER shown)
docker secret ls
# ID                          NAME          CREATED         UPDATED
# abc123xyz                   db_password   2 minutes ago   2 minutes ago

# Inspect (metadata only — no value)
docker secret inspect db_password

# Use secret in a service
docker service create \
  --name mydb \
  --secret db_password \
  mysql:8.0

# Inside the container — secret is at /run/secrets/db_password
docker exec -it mydb_container cat /run/secrets/db_password
# → my_super_secret_password (readable only to this container's process)

# Remove a secret (must remove from all services first)
docker secret rm db_password
```

### Using Swarm Secrets in docker-compose.yml (Swarm Mode)

```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password   # ← Read from file
      MYSQL_DATABASE: myapp
    secrets:
      - db_root_password

  app:
    image: myapp:latest
    secrets:
      - db_root_password
      - api_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_root_password

secrets:
  db_root_password:
    external: true   # Created via 'docker secret create' beforehand
  api_key:
    external: true
```

---

### Option 2 — `.env` File (Compose Only, Not Swarm)

For local development with Docker Compose (NOT production):

```bash
# Create .env file — NEVER commit to git!
cat > .env << 'EOF'
MYSQL_ROOT_PASSWORD=devpassword
MYSQL_DATABASE=myapp_dev
API_KEY=dev-api-key-12345
EOF

# Add to .gitignore immediately
echo ".env" >> .gitignore
```

```yaml
# docker-compose.yml — references .env automatically
version: '3.8'
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
```

```bash
docker compose up -d   # .env is loaded automatically
```

> [!WARNING]
> `.env` files are plaintext on disk. They are better than Dockerfile hardcoding, but **not suitable for production**. Use Docker Swarm secrets or HashiCorp Vault for production.

---

### Option 3 — BuildKit Secrets (Build-time Only)

For secrets needed **during build** (e.g., npm token to pull private packages):

```dockerfile
# syntax=docker/dockerfile:1
FROM node:18-alpine

# Secret mounted ONLY during this RUN step — not stored in image layer
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    npm install --registry https://npm.example.com
```

```bash
# Build with secret
docker buildx build \
  --secret id=npm_token,env=NPM_TOKEN \
  -t myapp:latest .
```

---

### Option 4 — HashiCorp Vault (Enterprise)

For serious production environments, use a dedicated secrets manager:

```bash
# Concept — app fetches secrets from Vault at runtime
# Instead of: ENV DB_PASSWORD=secret123
# App does:   vault kv get secret/db/password

# Vault integration pattern
docker run -d \
  -e VAULT_ADDR=http://vault:8200 \
  -e VAULT_TOKEN=$(vault login -method=kubernetes -token-only) \
  myapp:latest
```

---

## 🔒 Secret Best Practices

| Practice | Why |
|---|---|
| **Never put secrets in Dockerfiles** | Baked into image layers forever |
| **Never use ENV for passwords in production** | Visible in inspect, logs, process lists |
| **Use Docker secrets for Swarm** | Encrypted at rest, access-controlled |
| **Use `.env` only for local dev** | Plaintext — never for production |
| **Rotate secrets regularly** | Limits exposure window if compromised |
| **Audit secret access** | Know who/what is reading secrets |
| **Use `_FILE` suffixed env vars** | Images that support it read from file, not env |

### The `_FILE` Pattern

Many official images support reading secrets from files:

```yaml
# Instead of:
environment:
  MYSQL_ROOT_PASSWORD: secret123     # ❌ Exposed

# Use:
environment:
  MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password  # ✅
secrets:
  - mysql_root_password
```

Supported images: MySQL, PostgreSQL, MariaDB, Redis, WordPress, and many more.

---

## 🛡️ Avoiding Common Secret Leaks

```bash
# ❌ This leaks the secret into shell history
docker run -e DB_PASS=secret123 myapp

# ✅ Read from a file instead
docker run -e DB_PASS="$(cat /secure/path/db_pass)" myapp

# ✅ Or use Docker secrets (Swarm)
docker service create --secret db_password myapp

# Check if any secrets are visible in image history
docker history --no-trunc myimage | grep -i pass
docker history --no-trunc myimage | grep -i secret
docker history --no-trunc myimage | grep -i key

# Check running container env
docker inspect mycontainer | grep -i "Env" -A 20
```

---

## 📋 Summary — Secret Storage Options Compared

| Method | Encrypted at Rest | Access Control | Audit Log | Best For |
|---|---|---|---|---|
| Dockerfile ENV | ❌ No | ❌ No | ❌ No | Never |
| docker run -e | ❌ No | ❌ No | ❌ No | Never |
| .env file | ❌ No | File perms only | ❌ No | Local dev only |
| Docker Swarm secrets | ✅ Yes (AES-256) | ✅ Per-service | Partial | Swarm production |
| BuildKit secrets | ✅ Not stored | ✅ Build-time only | ❌ No | Build-time only |
| HashiCorp Vault | ✅ Yes | ✅ Full RBAC | ✅ Full | Enterprise |

---

## ⚡ Quick Reference

```bash
# Docker Swarm secrets
echo "mysecret" | docker secret create mypassword -
docker secret ls
docker secret inspect mypassword
docker secret rm mypassword

# Use in service
docker service create --secret mypassword myimage
# Secret available at: /run/secrets/mypassword

# .env file for Compose
echo "MYSQL_ROOT_PASSWORD=devpass" > .env
docker compose up -d

# Check for secret leaks
docker history --no-trunc myimage | grep -iE "pass|secret|key|token"
docker inspect mycontainer | grep -iA5 "Env"
```

---

> [!TIP]
> **Next:** [30 — Kubernetes Introduction (The Natural Next Step)](30-kubernetes-intro.md)

---

*Navigation:*<br>[&larr; Previous Note](28-docker-compose-advanced.md) | [Next Note &rarr;](30-kubernetes-intro.md)
