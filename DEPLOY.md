# Deployment Guide

## Prerequisites

- Docker and Docker Compose installed
- Git (for cloning repositories)
- 8GB+ RAM recommended
- 2+ vCPU cores
- 40GB+ disk space
- curl installed (for health checks)

## Initial Setup

### Production Deployment (Recommended)

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd odoo
   ```

2. **Run automated deployment:**
   ```bash
   ./deploy.sh
   ```

   This script will:
   - Check prerequisites (Docker, Docker Compose)
   - Create `.env` from template if needed
   - Pull latest Docker images
   - Start services with health checks
   - Wait for Odoo to be ready
   - Confirm everything is working

3. **Access Odoo:**
   - URL: http://localhost:8069
   - Create your database via web interface

### Development Setup (Quick)

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials if needed
   ```

2. **Start services:**
   ```bash
   docker compose up -d
   ```

3. **Access Odoo:**
   - URL: http://localhost:8069
   - Create your database via web interface

## Docker Commands

### Production Operations
```bash
# Automated deployment (recommended)
./deploy.sh

# Stop services
docker compose down

# View logs
docker compose logs -f odoo
docker compose logs -f db
```

### Development Operations
```bash
# Quick start
docker compose up -d

# Restart Odoo only
docker compose restart odoo

# Check status
docker compose ps
```

### Maintenance

```bash
# Update containers
docker compose pull
docker compose up -d

# Clean unused resources
docker system prune
```

## Database Access

### Connection Details

- **Host:** localhost
- **Port:** 5432
- **Database:** (from POSTGRES_DB in .env)
- **User:** (from POSTGRES_USER in .env)
- **Password:** (from POSTGRES_PASSWORD in .env)

### Backup & Restore

```bash
# Create backup (replace 'odoo' with your POSTGRES_USER if different)
docker compose exec db pg_dump -U ${POSTGRES_USER:-odoo} ${POSTGRES_DB:-odoo} > backup_$(date +%Y%m%d).sql

# Restore backup
docker compose exec -T db psql -U ${POSTGRES_USER:-odoo} -d ${POSTGRES_DB:-odoo} < backup.sql
```

## Production Considerations

### Security

- Change all passwords in `.env` file:
  - `POSTGRES_PASSWORD` - Database password
  - `ADMIN_PASSWD` - Odoo master password
- Consider using Docker secrets for production
- Enable firewall (ports 8069, 5432)

### Performance

- Worker processes configured in `config/odoo.conf` (3 workers)
- Memory limits set (5GB soft, 6GB hard)
- Resource limits enforced via Docker Compose
- Configure PostgreSQL parameters for your workload
- Use reverse proxy (Nginx/Traefik) for SSL/HTTPS

### Monitoring

```bash
# Resource usage
docker stats

# Container health
docker compose ps
docker compose logs --tail=50 odoo

# Health check status
docker inspect odoo-app --format='{{.State.Health.Status}}'
docker inspect odoo-db --format='{{.State.Health.Status}}'
```

## Troubleshooting

### Common Issues

- **Port conflicts:** Change `ODOO_PORT` in `.env` file
- **Permission errors:** Check file ownership
- **Memory issues:** Adjust resource limits in `docker-compose.yml`
- **Module not found:** Restart Odoo after adding addons
- **Health check failures:** Check container logs and network connectivity

### Reset Environment

```bash
# Stop and remove everything (containers, volumes, networks)
docker compose down -v --remove-orphans

# Clean unused Docker resources
docker system prune -f

# Start fresh installation
./deploy.sh
```

**Note:** The `-v` flag removes all data volumes, completely resetting the database and Odoo data.
