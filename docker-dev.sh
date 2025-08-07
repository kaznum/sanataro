#!/bin/bash

# Docker Compose Development Helper Script for Sanataro

set -e

MYSQL_SERVICE="webapp-mysql"
POSTGRES_SERVICE="webapp-postgresql"

show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  up-mysql       Start application with MySQL database"
    echo "  up-postgres    Start application with PostgreSQL database"
    echo "  down           Stop all services"
    echo "  build          Build/rebuild containers"
    echo "  logs           Show logs for all services"
    echo "  logs-mysql     Show logs for MySQL webapp"
    echo "  logs-postgres  Show logs for PostgreSQL webapp"
    echo "  shell-mysql    Open shell in MySQL webapp container"
    echo "  shell-postgres Open shell in PostgreSQL webapp container"
    echo "  console-mysql  Open Rails console in MySQL webapp"
    echo "  console-postgres Open Rails console in PostgreSQL webapp"
    echo "  test-mysql     Run tests with MySQL"
    echo "  test-postgres  Run tests with PostgreSQL"
    echo "  clean          Remove all containers and volumes"
    echo ""
    echo "Examples:"
    echo "  $0 up-mysql              # Start with MySQL"
    echo "  $0 up-postgres           # Start with PostgreSQL"
    echo "  $0 shell-mysql           # Open shell in MySQL container"
    echo "  $0 console-postgres      # Rails console with PostgreSQL"
}

case "$1" in
    up-mysql)
        echo "Starting Sanataro with MySQL..."
        docker compose up db-mysql redis $MYSQL_SERVICE
        ;;
    up-postgres)
        echo "Starting Sanataro with PostgreSQL..."
        docker compose up db-postgresql redis $POSTGRES_SERVICE
        ;;
    down)
        echo "Stopping all services..."
        docker compose down
        ;;
    build)
        echo "Building containers..."
        docker compose build
        ;;
    logs)
        docker compose logs -f
        ;;
    logs-mysql)
        docker compose logs -f $MYSQL_SERVICE
        ;;
    logs-postgres)
        docker compose logs -f $POSTGRES_SERVICE
        ;;
    shell-mysql)
        docker compose exec $MYSQL_SERVICE bash
        ;;
    shell-postgres)
        docker compose exec $POSTGRES_SERVICE bash
        ;;
    console-mysql)
        docker compose exec $MYSQL_SERVICE bundle exec rails console
        ;;
    console-postgres)
        docker compose exec $POSTGRES_SERVICE bundle exec rails console
        ;;
    test-mysql)
        docker compose exec $MYSQL_SERVICE bundle exec rspec
        ;;
    test-postgres)
        docker compose exec $POSTGRES_SERVICE bundle exec rspec
        ;;
    clean)
        echo "Removing all containers and volumes..."
        docker compose down -v --remove-orphans
        docker system prune -f
        ;;
    *)
        show_usage
        ;;
esac