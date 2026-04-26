# 06 — Dockerfile & Building Images

A **Dockerfile** is a text script of instructions to build a custom image.

---

## Setup

```bash
mkdir myproject
cd myproject
vim Dockerfile       # capital D — this is the convention!
```

> ⚠️ Name it `Dockerfile` (capital D), not `dockerfile`.
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
