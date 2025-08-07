#!/bin/bash

# Docker Compose Demo Script for Sanataro
# This script demonstrates the Docker setup without actually starting the containers

echo "🐳 Sanataro Docker Compose Setup Demo"
echo "======================================"
echo ""

echo "📋 Available Services:"
echo "----------------------"
docker compose config --services | while read service; do
    echo "  • $service"
done
echo ""

echo "🔧 Service Configuration Summary:"
echo "--------------------------------"
echo "MySQL Configuration:"
DB_ADAPTER=mysql2 DB_HOST=db-mysql DB_NAME=sanataro_development DB_USERNAME=sanataro DB_PASSWORD=sanataro_password erb config/database.yml.docker | grep -A 6 "development:"
echo ""

echo "PostgreSQL Configuration:"  
DB_ADAPTER=postgresql DB_HOST=db-postgresql DB_NAME=sanataro_development DB_USERNAME=sanataro DB_PASSWORD=sanataro_password erb config/database.yml.docker | grep -A 6 "development:"
echo ""

echo "🚀 Quick Start Commands:"
echo "-----------------------"
echo "1. Build containers:      ./docker-dev.sh build"
echo "2. Start with MySQL:      ./docker-dev.sh up-mysql"
echo "3. Start with PostgreSQL: ./docker-dev.sh up-postgres"
echo "4. Open development shell: ./docker-dev.sh shell-mysql"
echo "5. Open Rails console:    ./docker-dev.sh console-postgres"
echo "6. Run tests:             ./docker-dev.sh test-mysql"
echo "7. View logs:             ./docker-dev.sh logs"
echo "8. Stop services:         ./docker-dev.sh down"
echo "9. Clean up:              ./docker-dev.sh clean"
echo ""

echo "🌐 Access URLs:"
echo "--------------"
echo "MySQL webapp:       http://localhost:3000"
echo "PostgreSQL webapp:   http://localhost:3001"
echo "MySQL database:      localhost:3306"
echo "PostgreSQL database: localhost:5432"
echo "Redis cache:         localhost:6379"
echo ""

echo "💡 Advanced Usage:"
echo "------------------"
echo "Manual Docker Compose commands:"
echo "• docker compose up db-mysql redis webapp-mysql"
echo "• docker compose exec webapp-mysql bundle exec rails console"
echo "• docker compose logs -f webapp-postgresql"
echo ""

echo "Environment customization:"
echo "• Copy .env.example to .env and customize settings"
echo "• Set LOAD_SEEDS=true to automatically load demo data"
echo ""

echo "✅ Docker Compose setup is ready for development!"
echo ""
echo "Note: This demo script shows the configuration without starting containers."
echo "Use the commands above to actually start the development environment."