---
name: docker-ops
description: Docker and Docker Compose operations. Use for building images, running containers, composing multi-service stacks, debugging container issues, managing volumes/networks, and writing Dockerfiles or compose.yaml files. Trigger for any Docker, container, docker-compose, image, registry, or containerization task.
---

# Docker Ops

## Scope

Docker Engine + Docker Compose v2 on Windows (Docker Desktop or via WSL). Patterns apply equally on Linux.

## Quick checks

```bash
docker version           # confirm engine running
docker compose version   # v2 required (no hyphen)
docker info              # storage driver, root dir, contexts
docker context ls        # which docker host is active
```

If Docker Desktop isn't running on Windows, ask user to start it.

## Common operations

### Build image

```
cdx "GOAL: Build Docker image from Dockerfile in <dir>.
TAG: <name>:<version> + :latest
PLATFORM: linux/amd64 (or linux/arm64 if specified)
CONTEXT: <dir>
CACHE: use BuildKit, cache mounts where applicable.
RETURN: STATUS + SUMMARY (image id, size) + EVIDENCE (build log tail)."
```

### Run container

Prefer compose for anything multi-service. For one-off:

```bash
docker run --rm -d \
  --name <name> \
  -p <host>:<container> \
  -e KEY=value \
  -v $(pwd)/data:/data \
  --network <network> \
  <image>:<tag>
```

### Multi-service stack (compose)

`docker-compose.yaml` template:

```yaml
services:
  app:
    build: ./app
    image: myapp:latest
    ports: ["8080:8080"]
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    volumes:
      - dbdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 5s
      timeout: 3s
      retries: 5
    restart: unless-stopped

volumes:
  dbdata:
```

### Run stack

```
cdx "GOAL: Bring up compose stack defined in docker-compose.yaml.
ACTIONS: docker compose up -d --build
SUCCESS: all services healthy within 60 seconds.
RETURN: STATUS + SUMMARY (services + status) + EVIDENCE (docker compose ps output)."
```

### Inspect logs

```bash
docker compose logs -f --tail=100 <service>
docker logs --since 10m <container>
```

### Debug a container

```bash
docker exec -it <container> sh
docker inspect <container> | jq '.[0].State'
docker stats <container>
```

## Dockerfile best practices

Lean Dockerfiles:

```dockerfile
# Multi-stage: build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package*.json ./
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

Rules:
- Multi-stage when build deps differ from runtime deps.
- Pin base image versions.
- Run as non-root.
- One process per container.
- HEALTHCHECK if no orchestrator does it.
- `.dockerignore` to keep context small.

## Volumes vs bind mounts

- **Named volumes**: managed by Docker, persist across container removes. Best for DB data.
- **Bind mounts** (`-v $(pwd)/src:/app/src`): live-edit during dev. Slow on Windows/macOS.
- **tmpfs**: in-memory only.

## Networking

```bash
docker network create mynet
docker run --network mynet ...
```

Compose creates a project-scoped network automatically. Services reach each other by service name.

## Registry operations

```bash
docker login <registry>
docker tag local-image:tag registry/repo:tag
docker push registry/repo:tag
docker pull registry/repo:tag
```

For ECR/GCR/etc., use the cloud provider's auth helper.

## Common patterns

### Local dev: services + hot-reload app

Two compose files: `docker-compose.yaml` (services) + `docker-compose.dev.yaml` (override with bind mounts and dev commands). Use:

```bash
docker compose -f docker-compose.yaml -f docker-compose.dev.yaml up
```

### One-shot tasks (migrations, seeds)

```bash
docker compose run --rm app npm run migrate
```

`--rm` cleans up the container after.

### Production-ish smoke

```bash
docker compose -f docker-compose.prod.yaml up -d
docker compose ps
docker compose exec app curl localhost:8080/health
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Engine not running | Start Docker Desktop / `sudo systemctl start docker` |
| Build very slow | Large context | Add `.dockerignore` |
| Container exits immediately | No long-running process | Verify CMD; check logs |
| `OCI runtime exec failed` | Wrong shell | Use `sh` not `bash` on Alpine |
| Compose up hangs on healthcheck | Healthcheck wrong | Test manually; check `pg_isready` etc. |
| Volume data lost | Used anonymous volume | Use named volume |
| Port conflict | Another process on host port | Change host port mapping |

## Cleanup

```bash
docker system df                   # see what's using disk
docker system prune -f             # remove unused
docker system prune -a --volumes   # nuclear: ALL unused incl. volumes (confirm first)
```

Never run prune on a host with shared dev volumes without confirming.

## n8n via Docker

Common pattern (links to skill `n8n-workflows`):

```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    ports: ["5678:5678"]
    environment:
      N8N_HOST: localhost
      N8N_PORT: 5678
      WEBHOOK_URL: http://localhost:5678/
      GENERIC_TIMEZONE: America/New_York
    volumes:
      - n8n_data:/home/node/.n8n
volumes:
  n8n_data:
```

## Pitfalls

- `latest` tag in production. Pin versions.
- Logs filling disk. Use log rotation: `--log-opt max-size=10m --log-opt max-file=3`.
- Secrets in env vars in compose file. Use `.env` file (gitignored) or Docker secrets.
- Building on slow networks; use `--build-arg HTTP_PROXY=...` if needed.

## Anti-patterns

- One image with everything (web + db + cache).
- Running as root.
- Volumes mounted over node_modules causing platform mismatches.
- Hardcoded DB connection strings; use env.
