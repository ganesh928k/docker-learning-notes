# 06 — Dockerfile & Building Images

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

A **Dockerfile** is a text script of instructions to build a custom image.

---

## Setup

```bash
mkdir myproject
cd myproject
vim Dockerfile       # capital D — this is the convention!
```

> [!WARNING] Name it `Dockerfile` (capital D), not `dockerfile`.
> Docker looks for this exact name by default.

---

## Example Dockerfile (Apache web server)

```dockerfile
FROM httpd:latest
COPY ./public/ /usr/local/apache2/htdocs/
EXPOSE 80
```

| Instruction | Meaning |
|---|---|
| `FROM` | Base image to build on — always first |
| `COPY` | Copy files from host into the image |
| `RUN` | Execute a shell command during build |
| `EXPOSE` | Documents which port the app uses (informational only) |
| `CMD` | Default command to run when container starts |

---

## Build the image

```bash
docker image build -t myimage .
```

- `-t myimage` — name/tag the resulting image
- `.` — use current directory as build context (where Dockerfile lives)

---

## Build with a version tag

```bash
docker image build -t myimage:v2 .
```

---

## Run your custom image

```bash
docker run -d --name con1 myimage:latest
docker run -d --name con1 -p 8080:80 myimage:latest   # with port mapping
```

---

## Verify the contents

```bash
docker exec -it con1 bash
# now you're inside — explore with ls, cat, etc.
```

---

## Full example workflow

```bash
mkdir mysite && cd mysite
mkdir public
echo "<h1>Hello Docker!</h1>" > public/index.html

cat > Dockerfile << 'EOF'
FROM httpd:latest
COPY ./public/ /usr/local/apache2/htdocs/
EXPOSE 80
EOF

docker image build -t mysite:v1 .
docker run -d --name mysite -p 8080:80 mysite:v1
# Open http://localhost:8080 in your browser
```


---

## .dockerignore — Speed Up Builds, Prevent Leaks

When you run `docker build`, Docker sends the **entire build context** (the `.` directory) to the daemon. Without `.dockerignore`, this includes `.git/`, `node_modules/`, `.env` files, logs, and anything else in the folder — making builds slow and potentially leaking secrets into the image.

`.dockerignore` works exactly like `.gitignore`.

```bash
# Create a .dockerignore file alongside your Dockerfile
vim .dockerignore
```

```
# .dockerignore

# Version control
.git
.gitignore

# Dependencies (rebuilt inside container)
node_modules/
__pycache__/
*.pyc
.pytest_cache/
venv/

# Build output
dist/
build/
*.o
*.class

# Secrets and config
.env
*.key
*.pem
credentials*

# Logs and temp files
*.log
*.tmp

# Docs (not needed in image)
*.md
docs/
```

```bash
# Verify: Docker prints context size before build
docker build -t myimage .
# Sending build context to Docker daemon  4.096kB   ← small = good
# vs.
# Sending build context to Docker daemon  250.5MB   ← missing .dockerignore!
```

> [!CAUTION]
> Forgetting `.dockerignore` on a Node.js project sends `node_modules/` (100MB+) to the daemon on every build.
> Always create `.dockerignore` as the first file in every Docker project.

---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker build -t myimage .` | Build image from Dockerfile in current dir |
| `docker build -t myimage:v2 .` | Build with version tag |
| `docker build -f MyDockerfile .` | Build using a non-default Dockerfile name |
| `docker build --no-cache -t myimage .` | Force rebuild all layers |
| `docker run -d -p 8080:80 myimage` | Run with port mapping |
| `docker inspect myimage` | Full image metadata |
| `docker image history myimage` | Show all build layers |

| Instruction | Purpose |
|---|---|
| `FROM image:tag` | Base image (always first) |
| `COPY src dest` | Copy files from host to image |
| `RUN command` | Execute shell command at build time |
| `EXPOSE 80` | Document the port the app uses |
| `CMD ["cmd"]` | Default command on container start |

---

*Navigation:*<br>[&larr; Previous Note](05-networking.md) | [Next Note &rarr;](07-dockerhub.md)
