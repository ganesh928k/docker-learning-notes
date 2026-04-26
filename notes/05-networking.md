# 05 — Port Mapping & Networking

By default, container ports are only accessible **inside Docker's network**.
Port mapping exposes them to your host (and beyond).

---

## Publish a port

```bash
docker run -d --name web -p 8080:80 httpd:latest
```

Format: `-p <host_port>:<container_port>`

- `8080` — port on your host machine (open in browser)
- `80` — port inside the container (where the app listens)

Access: `http://<your-server-ip>:8080`

---

## Multiple ports

```bash
docker run -d -p 80:80 -p 443:443 nginx
```

---

## Check host network interfaces

```bash
ip a
```

You'll see a `docker0` interface — the virtual bridge Docker uses.
All containers on the default network connect through this bridge.

> ⚠️ `ifconfig` is deprecated on AlmaLinux 9. Use `ip a` instead.
> `ipconfig` is a **Windows** command and won't work on Linux.

---

## Useful network commands

```bash
docker network ls                  # list all Docker networks
docker network inspect bridge      # details of default bridge network
docker inspect con1 | grep IPAddress  # container's internal IP
```

---

## Default networks

| Network | Description |
|---|---|
| `bridge` | Default. Containers can talk to each other by IP |
| `host` | Container shares host's network stack |
| `none` | No networking |
