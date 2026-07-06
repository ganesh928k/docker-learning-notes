# 02 — Docker Images

> **Session 1** | Tested on: AlmaLinux 9 | Author: Ganesh

An **image** is a read-only template (blueprint) used to create containers.
Images are made of layers and stored locally after being pulled.

---

## Pull an image

```bash
docker pull almalinux            # pulls :latest by default
docker pull httpd:latest         # explicit tag
docker pull ubuntu:22.04         # specific version
```

---

## List local images

```bash
docker images
docker image ls
```

Sample output:
```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
httpd        latest    331548c5249b   2 weeks ago    148MB
almalinux    latest    8f50403cd881   3 weeks ago    196MB
```

> [!TIP] Use the Image ID (e.g. `8f50403cd881`) when running an image that has no tag.

---

## Search Docker Hub

```bash
docker search httpd
```

Shows name, description, stars, and whether it's an Official image.
Always prefer **Official** images when possible — they are maintained and security-patched.

---

## View image layer history

```bash
docker image history httpd:latest
```

Shows every layer/command that was used to build the image.

---

## Remove an image

```bash
docker rmi httpd             # by name
docker rmi 331548c5249b      # by ID
```

> You cannot remove an image while a container (even stopped) is using it. Remove the container first.


---

## ⚡ Quick Reference

| Command | What it does |
|---|---|
| `docker pull nginx:latest` | Download image |
| `docker pull nginx:1.27` | Pull specific version |
| `docker images` | List local images |
| `docker image ls` | Same as above |
| `docker images nginx` | Filter by name |
| `docker images "nginx*"` | Wildcard filter (always quote!) |
| `docker search nginx` | Search Docker Hub |
| `docker search --filter is-official=true nginx` | Official images only |
| `docker image history nginx` | Show image layers |
| `docker rmi nginx` | Remove image (by name or ID) |
| `docker rmi $(docker images -q)` | Remove ALL images |
| `docker image prune` | Remove dangling images |
| `docker image prune -a` | Remove all unused images |

---

*Navigation:*<br>[&larr; Previous Note](01-installation-setup.md) | [Next Note &rarr;](03-containers.md)
