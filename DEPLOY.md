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
- **Use reverse proxy (Nginx/Traefik/Apache) for SSL/HTTPS and WebSocket support**

### Reverse Proxy Configuration (Production)

Odoo requires two ports to be properly proxied:

- **Port 8069:** Main HTTP/HTTPS traffic
- **Port 8072:** WebSocket/Longpolling for real-time features

Without proper proxy configuration, you'll see websocket errors in logs and lose real-time notifications.

#### Configuration Requirements

Your reverse proxy must:

1. Route HTTP traffic to port 8069
2. Route WebSocket traffic (`/websocket` and `/longpolling`) to port 8072
3. Set proper headers for WebSocket upgrade
4. Handle SSL/TLS termination if using HTTPS

#### Nginx Example

```nginx
upstream odoo {
    server localhost:8069;
}

upstream odoo-longpolling {
    server localhost:8072;
}

# HTTP to HTTPS redirect (optional)
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL Configuration
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy settings
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    # WebSocket/Longpolling
    location /websocket {
        proxy_pass http://odoo-longpolling;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /longpolling {
        proxy_pass http://odoo-longpolling;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Main application
    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 60m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }

    # Gzip
    gzip on;
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
}
```

#### Apache Example

```apache
<VirtualHost *:80>
    ServerName your-domain.com
    Redirect permanent / https://your-domain.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName your-domain.com

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile /path/to/your/certificate.crt
    SSLCertificateKeyFile /path/to/your/private.key
    SSLCertificateChainFile /path/to/chain.crt

    # Proxy settings
    ProxyPreserveHost On
    ProxyRequests Off
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Host "your-domain.com"

    # WebSocket support
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /websocket/(.*) ws://localhost:8072/websocket/$1 [P,L]
    RewriteCond %{HTTP:Upgrade} =websocket [NC]
    RewriteRule /longpolling/(.*) ws://localhost:8072/longpolling/$1 [P,L]

    # WebSocket proxy
    ProxyPass /websocket http://localhost:8072/websocket upgrade=websocket
    ProxyPassReverse /websocket http://localhost:8072/websocket

    ProxyPass /longpolling http://localhost:8072/longpolling upgrade=websocket
    ProxyPassReverse /longpolling http://localhost:8072/longpolling

    # Main application
    ProxyPass / http://localhost:8069/
    ProxyPassReverse / http://localhost:8069/

    # Logs
    ErrorLog ${APACHE_LOG_DIR}/odoo_error.log
    CustomLog ${APACHE_LOG_DIR}/odoo_access.log combined
</VirtualHost>
```

#### Traefik Example (Docker Labels)

```yaml
services:
  odoo:
    # ... existing configuration ...
    labels:
      - "traefik.enable=true"
      # HTTP Router
      - "traefik.http.routers.odoo.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.odoo.entrypoints=websecure"
      - "traefik.http.routers.odoo.tls=true"
      - "traefik.http.routers.odoo.tls.certresolver=letsencrypt"
      - "traefik.http.services.odoo.loadbalancer.server.port=8069"

      # WebSocket Router
      - "traefik.http.routers.odoo-ws.rule=Host(`your-domain.com`) && (PathPrefix(`/websocket`) || PathPrefix(`/longpolling`))"
      - "traefik.http.routers.odoo-ws.entrypoints=websecure"
      - "traefik.http.routers.odoo-ws.tls=true"
      - "traefik.http.services.odoo-ws.loadbalancer.server.port=8072"
```

#### Kubernetes Ingress Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: odoo-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "720"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "720"
    # WebSocket support
    nginx.ingress.kubernetes.io/upstream-hash-by: "$binary_remote_addr"
spec:
  tls:
    - hosts:
        - your-domain.com
      secretName: odoo-tls
  rules:
    - host: your-domain.com
      http:
        paths:
          # WebSocket paths to port 8072
          - path: /websocket
            pathType: Prefix
            backend:
              service:
                name: odoo-longpolling-service
                port:
                  number: 8072
          - path: /longpolling
            pathType: Prefix
            backend:
              service:
                name: odoo-longpolling-service
                port:
                  number: 8072
          # Main application to port 8069
          - path: /
            pathType: Prefix
            backend:
              service:
                name: odoo-service
                port:
                  number: 8069
---
apiVersion: v1
kind: Service
metadata:
  name: odoo-service
spec:
  ports:
    - port: 8069
      targetPort: 8069
  selector:
    app: odoo
---
apiVersion: v1
kind: Service
metadata:
  name: odoo-longpolling-service
spec:
  ports:
    - port: 8072
      targetPort: 8072
  selector:
    app: odoo
```

#### Cloud Provider Load Balancers

**AWS Application Load Balancer:**

- Create target groups for both ports 8069 and 8072
- Configure path-based routing: `/websocket/*` and `/longpolling/*` to port 8072
- All other traffic to port 8069
- Enable sticky sessions for WebSocket connections
- Configure health checks for both target groups

**Google Cloud Load Balancer:**

- Use URL Maps to route WebSocket paths to backend service on port 8072
- Configure backend services for both ports
- Enable connection draining
- Set appropriate timeout values (720s recommended)

**Azure Application Gateway:**

- Create backend pools for both ports
- Configure path-based rules for WebSocket endpoints
- Enable WebSocket protocol support
- Set request timeout to 720 seconds

#### Testing WebSocket Connection

After configuring your reverse proxy, verify WebSocket connectivity:

```bash
# Test WebSocket connection (requires wscat: npm install -g wscat)
wscat -c wss://your-domain.com/websocket

# Or using curl
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  https://your-domain.com/websocket

# Check Odoo logs for successful WebSocket connections
docker compose logs -f odoo | grep -i "websocket\|longpolling"
```

Expected log output when working correctly:

```
INFO ? odoo.service.server: Evented Service (longpolling) running on 0.0.0.0:8072
INFO ? odoo.addons.bus.models.bus: Bus.loop listen imbus on db postgres
```

#### Common Proxy Issues

1. **502 Bad Gateway on WebSocket:**

   - Ensure port 8072 is accessible to proxy
   - Check WebSocket upgrade headers are set
   - Verify timeout settings (should be 720s or higher)

2. **WebSocket connects but disconnects immediately:**

   - Enable proxy buffering
   - Check firewall rules between proxy and Odoo
   - Verify proxy_mode is set to True in odoo.conf

3. **Real-time features not working:**

   - Confirm `/websocket` and `/longpolling` routes are proxied to port 8072
   - Check browser console for WebSocket errors
   - Verify SSL certificates if using HTTPS

4. **High CPU usage:**
   - Enable HTTP/2 in proxy
   - Configure proper keep-alive settings
   - Enable gzip compression for static assets

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
