# 17 — Practical Application Deployments

This note covers full examples of Dockerfiles used to deploy various types of applications. These templates demonstrate how advanced instructions (`WORKDIR`, `ENV`, `ADD`) come together in real-world scenarios.

---

## 1. Node.js Application

A typical Node.js app requires downloading dependencies via `npm install`. To optimize Docker layer caching, we copy `package.json` first, install dependencies, and *then* copy the rest of the source code.

**Dockerfile (`/projects/node-js/Dockerfile`)**
```dockerfile
FROM node:14

WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
```

**Running it:**
```bash
docker build -t node-app .
docker run -d --name My-nodeapp -p 3000:3000 node-app:latest
```

---

## 2. Python Application

A simple Python app. If you had dependencies, you would add a `COPY requirements.txt .` and `RUN pip install -r requirements.txt` step.

**Dockerfile (`/projects/python/Dockerfile`)**
```dockerfile
FROM python:3.9

COPY app.py /app/app.py

WORKDIR /app

CMD ["python", "app.py"]
```

**Running it:**
```bash
docker build -t python-app .
docker run python-app:latest
```

---

## 3. Jenkins Server

Instead of building an app from source, this Dockerfile provisions a Java runtime environment and downloads the Jenkins `.war` file directly from the internet using the `ADD` instruction.

**Dockerfile (`/projects/jenkins/Dockerfile`)**
```dockerfile
FROM eclipse-temurin:11-jdk

LABEL env=production
ENV apparea=/data/app

RUN mkdir -p ${apparea}

# Download Jenkins war file
ADD https://get.jenkins.io/war/2.397/jenkins.war ${apparea}/jenkins.war

WORKDIR ${apparea}

EXPOSE 8080

CMD ["java", "-jar", "jenkins.war"]
```

**Running it:**
Jenkins requires a volume for persistent data and multiple exposed ports.
```bash
docker build -t jenkin:1 .
docker run -d --name jenkins -p 9090:8080 -p 50000:50000 -v jenkins_home:/var/jenkins_home jenkin:1
```

---

## 4. Static Nginx Web Server

Serving static HTML files using the official Nginx image.

**Dockerfile (`/projects/nginx/Dockerfile`)**
```dockerfile
FROM nginx:latest

# Copy local HTML files to the default Nginx html serving directory
COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

**Running it:**
```bash
docker build -t my-nginx-server .
docker run -d -p 8080:80 --name my_nginx_app my-nginx-server:latest
```


---

## ⚡ Quick Reference

| App Type | Key Techniques Used |
|---|---|
| **Node.js** | Cache `package.json` first, then copy source code. |
| **Python** | Copy `requirements.txt`, install dependencies, copy source. |
| **Jenkins** | Use `ADD` to download remote `.war` file directly. |
| **Nginx** | Serve static files by copying to `/usr/share/nginx/html/`. |

---

*Navigation:*<br>[&larr; Previous Note](16-dockerfile-advanced-instructions.md) | [Next Note &rarr;](18-multistage-builds.md)
