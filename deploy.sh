#!/bin/bash
set -e

echo "🚀 Starting Odoo 19 Production Deployment..."

# Check prerequisites
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed."; exit 1; }
command -v docker-compose >/dev/null 2>&1 || command -v docker >/dev/null 2>&1 || { echo "❌ Docker Compose is required."; exit 1; }

# Setup environment
if [ ! -f .env ]; then
    echo "📝 Creating .env from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env with production passwords before continuing."
    exit 1
fi

# Pull latest images
echo "📦 Pulling Docker images..."
docker compose pull

# Start services
echo "🔄 Starting services..."
docker compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${ODOO_PORT:-8069} 2>/dev/null || echo "000")
    if [ "$response" = "303" ] || [ "$response" = "200" ]; then
        echo "✅ Odoo is responding!"
        break
    elif [ "$response" = "500" ]; then
        echo "📋 Odoo is running but database needs initialization"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo "❌ Odoo failed to start within $timeout seconds"
    docker compose logs --tail=20 odoo
    exit 1
fi

echo "🎉 Odoo 19 is ready!"
echo "🌐 Access: http://localhost:${ODOO_PORT:-8069}"
if [ "$response" = "500" ]; then
    echo "📝 First time setup: Create your database via the web interface"
else
    echo "📝 Login with your existing database"
fi