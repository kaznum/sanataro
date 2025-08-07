#!/bin/bash

# Simple test script to validate Docker Compose configuration

set -e

echo "Testing Docker Compose configuration for Sanataro..."

# Test 1: Validate docker-compose.yml syntax
echo "✓ Testing docker-compose.yml syntax..."
docker compose config --quiet
echo "  Docker Compose configuration is valid"

# Test 2: Check if required files exist
echo "✓ Testing required files..."
required_files=(
    "Dockerfile"
    "docker-compose.yml"
    "entrypoint.sh"
    "config/database.yml.docker"
    ".dockerignore"
    "docker-dev.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ $file missing"
        exit 1
    fi
done

# Test 3: Check if entrypoint script is executable
echo "✓ Testing entrypoint script permissions..."
if [ -x "entrypoint.sh" ]; then
    echo "  ✓ entrypoint.sh is executable"
else
    echo "  ✗ entrypoint.sh is not executable"
    exit 1
fi

# Test 4: Check if development script is executable
echo "✓ Testing development script permissions..."
if [ -x "docker-dev.sh" ]; then
    echo "  ✓ docker-dev.sh is executable"
else
    echo "  ✗ docker-dev.sh is not executable"
    exit 1
fi

# Test 5: Validate that services are defined correctly
echo "✓ Testing service definitions..."
services=$(docker compose config --services)
expected_services=("db-mysql" "db-postgresql" "redis" "webapp-mysql" "webapp-postgresql")

for service in "${expected_services[@]}"; do
    if echo "$services" | grep -q "^$service$"; then
        echo "  ✓ Service $service is defined"
    else
        echo "  ✗ Service $service is missing"
        exit 1
    fi
done

# Test 6: Check development script usage
echo "✓ Testing development script..."
if ./docker-dev.sh | grep -q "Usage:"; then
    echo "  ✓ Development script shows usage information"
else
    echo "  ✗ Development script doesn't show usage"
    exit 1
fi

echo ""
echo "🎉 All Docker Compose configuration tests passed!"
echo ""
echo "To start developing with Docker:"
echo "  ./docker-dev.sh build           # Build containers"
echo "  ./docker-dev.sh up-mysql        # Start with MySQL"
echo "  ./docker-dev.sh up-postgres     # Start with PostgreSQL"