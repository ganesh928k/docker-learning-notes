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
