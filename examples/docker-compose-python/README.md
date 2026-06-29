# Docker Compose Python Example

This example demonstrates how to build and run a custom Python application using Docker Compose.

## How to Run

1. Open your terminal and navigate to this directory:
   ```bash
   cd examples/docker-compose-python
   ```

2. Build the image and start the container:
   ```bash
   docker compose up --build -d
   ```

3. Test the application:
   ```bash
   curl http://localhost:8080
   # or visit http://localhost:8080 in a web browser
   ```

4. View the logs to see Python output:
   ```bash
   docker compose logs -f
   ```

5. Clean up:
   ```bash
   docker compose down
   ```
