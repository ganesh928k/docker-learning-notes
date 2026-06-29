# Dockerfile Projects

This folder contains standalone projects demonstrating how to write `Dockerfile`s for various programming languages and runtimes without using Docker Compose.

## How to Run

Inside any sub-project directory containing a `Dockerfile`, run:

```bash
# 1. Build the image
docker build -t my-app-name .

# 2. Run the container
docker run -d -p 8080:80 --name my-app-container my-app-name
```
