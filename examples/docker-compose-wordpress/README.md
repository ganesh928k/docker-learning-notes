# Docker Compose WordPress Example

This is a classic multi-container example: running WordPress backed by a MySQL database, complete with persistent volumes.

## How to Run

1. Navigate to this directory:
   ```bash
   cd examples/docker-compose-wordpress
   ```

2. Start the services:
   ```bash
   docker compose up -d
   ```

3. Initialize your WordPress site:
   - Open your browser and go to `http://localhost:8080`
   - Follow the WordPress setup wizard.

4. Test persistence:
   - Run `docker compose down`
   - Run `docker compose up -d` again.
   - Your WordPress data will survive because it's stored in a named volume (`db_data`).

5. Full cleanup (destroys database!):
   ```bash
   docker compose down -v
   ```
