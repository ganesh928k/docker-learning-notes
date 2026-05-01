# 09 — Commit, Inspect & Tag

---

## docker commit — Save a container as an image

You ran commands inside a container (e.g. installed nginx, curl), and you want to save that modified state as a new image.

```bash
docker commit <container_id> <new_image_name>:<tag>
```

### Basic commit
```bash
docker run -it ubuntu bash
# ... install stuff inside ...
docker commit 188434b948da ubuntu-nginx:latest
```

### Commit with metadata (author + message)
```bash
docker commit \
  --author="ganesh" \
  --message="curl image created" \
  1fcb2f48616f curl-ubuntu:1st
```

| Flag | Purpose |
|---|---|
| `--author` | Who made this image |
| `--message` | Describe what changed |

> 💡 **When to use commit vs Dockerfile?**
> - `commit` = quick, ad-hoc snapshots during exploration
> - `Dockerfile` = reproducible, version-controlled builds ← preferred for real projects

### Verify the committed image
```bash
docker images
docker run -it curl-ubuntu:1st bash
```

---

## docker inspect — Deep dive into any image or container

Returns a full JSON object with every detail about an image or container.

```bash
docker inspect ubuntu:latest          # inspect an image
docker inspect curl-ubuntu:1st        # inspect a committed image
docker inspect <container_id>         # inspect a running/stopped container
```

### Useful grep filters
```bash
docker image inspect nginx:latest | grep -i upper   # UpperDir (writable layer)
docker image inspect nginx:latest | grep -i lower   # LowerDir (read-only layers)
docker inspect <container_id> | grep IPAddress      # container's internal IP
docker inspect <container_id> | grep Mounts         # volume mount info
```

> The `UpperDir` and `LowerDir` are part of the **OverlayFS** filesystem Docker uses.
> Each image layer = a LowerDir. The writable container layer = UpperDir.

---

## docker tag — Rename or alias an image

`tag` does NOT copy the image — it just adds another name pointing to the same image ID.

```bash
docker tag 0395d4f646e9 mybitnami:stable
docker tag mybitnami:stable mybitnami:v2
docker tag apache-rhel9-ganesh928:latest jaatxog/apache-rhel9-ganesh928:latest
```

### Remove a tag (without deleting the image)
```bash
docker rmi mybitnami:stable
# Only removes the tag — image still exists if another tag points to it
```

---

## Filter images by name

```bash
docker images nginx               # exact match
docker images "nginx*"            # wildcard — always quote it
```

> ⚠️ `docker images *nginx` without quotes: shell expands `*` before Docker sees it. Always quote wildcards.

---

## Section Summary

| Command | What it does |
|---|---|
| `docker commit <id> name:tag` | Save container state as new image |
| `docker inspect <name/id>` | Full JSON details of image or container |
| `docker tag <src> <dest>` | Add a new name/tag to an existing image |
| `docker images "nginx*"` | Filter image list by name |
