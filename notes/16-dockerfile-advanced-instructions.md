# 16 — Advanced Dockerfile Instructions

While `FROM`, `COPY`, `RUN`, `EXPOSE`, and `CMD` are the core instructions, Docker provides several advanced instructions to make your images more robust, configurable, and secure.

---

## 1. WORKDIR — The Working Directory

`WORKDIR` sets the working directory for any `RUN`, `CMD`, `ENTRYPOINT`, `COPY`, and `ADD` instructions that follow it. If the directory doesn't exist, Docker will create it for you.

> [!TIP]
> **Best Practice:** Always use `WORKDIR` instead of `RUN cd /some/path`. The `cd` command in a `RUN` instruction only applies to that specific layer!

**Example:**
```dockerfile
FROM node:14
# Set the working directory
WORKDIR /app

# Now COPY operates inside /app
COPY package*.json ./
RUN npm install
COPY . .
```

---

## 2. ENV — Environment Variables

`ENV` allows you to set environment variables inside the container. These variables are available to subsequent instructions in the Dockerfile and are baked into the final image (so applications can read them at runtime).

**Example:**
```dockerfile
FROM eclipse-temurin:11-jdk

# Define a custom environment variable
ENV apparea=/data/app

# Use the variable in the build process
RUN mkdir -p ${apparea}
WORKDIR ${apparea}
```

---

## 3. ADD — Fetching Remote Files

`ADD` is similar to `COPY`, but it has two extra features:
1. It can download files directly from a **URL**.
2. It can automatically extract **local tarballs** (e.g., `.tar.gz`) into the image.

> [!WARNING]
> **Best Practice:** Docker recommends using `COPY` over `ADD` for copying local files because `COPY` is more transparent. Only use `ADD` when you explicitly need to fetch a URL or auto-extract an archive.

**Example: Downloading Jenkins**
```dockerfile
FROM eclipse-temurin:11-jdk
ENV apparea=/data/app
RUN mkdir -p ${apparea}

# Download the Jenkins WAR file directly from the internet
ADD https://get.jenkins.io/war/2.397/jenkins.war ${apparea}/jenkins.war
```

---

## 4. LABEL — Metadata

`LABEL` allows you to add key-value metadata to your image. This is highly useful for organizing images, documenting the author, marking the environment, or defining versioning.

**Example:**
```dockerfile
FROM eclipse-temurin:11-jdk

LABEL maintainer="ganesh@example.com"
LABEL version="1.0"
LABEL env="production"
```
You can view these labels later using the `docker inspect` command.

*(Note: The older `MAINTAINER` instruction is deprecated. Always use `LABEL` instead).*

---

## 5. ENTRYPOINT vs CMD

While both `CMD` and `ENTRYPOINT` specify what command runs when a container starts, they behave slightly differently when you pass arguments via `docker run`:

- **`CMD`**: Easily overridden. If a user runs `docker run myimage bash`, the `CMD` is ignored, and `bash` is executed instead.
- **`ENTRYPOINT`**: Harder to override. Arguments passed in `docker run` are **appended** to the `ENTRYPOINT`.

**Common Pattern:** Use `ENTRYPOINT` for the core executable, and `CMD` for default flags.
```dockerfile
FROM ubuntu
ENTRYPOINT ["ping"]
CMD ["-c", "3", "8.8.8.8"]
```
If you run `docker run myimage`, it pings `8.8.8.8` three times.
If you run `docker run myimage google.com`, it pings `google.com`!


---

*Navigation:*<br>[&larr; Previous Note](15-namespaces-pid-uts-ipc-user.md) | [Next Note &rarr;](17-practical-app-deployments.md)
