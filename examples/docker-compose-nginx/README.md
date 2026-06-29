# Docker Compose Nginx Example

This example demonstrates how to set up an Nginx reverse proxy / load balancer with a basic web backend.

## How to Run

1. Open your terminal and navigate to this directory:
   ```bash
   cd examples/docker-compose-nginx
   ```

2. Start the services in the background:
   ```bash
   docker compose up -d
   ```

3. Test the application by visiting `http://localhost:8080` in your browser, or run:
   ```bash
   curl http://localhost:8080
   ```

4. Stop and clean up the containers when you're done:
   ```bash
   docker compose down
   ```
