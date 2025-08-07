#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database to be ready..."

# Function to wait for database
wait_for_db() {
  local adapter=$1
  local max_attempts=30
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    case $adapter in
      "mysql2")
        if command -v mysqladmin >/dev/null 2>&1 && mysqladmin ping -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" --silent >/dev/null 2>&1; then
          echo "MySQL is ready!"
          return 0
        fi
        ;;
      "postgresql")
        if command -v pg_isready >/dev/null 2>&1 && pg_isready -h "$DB_HOST" -U "$DB_USERNAME" -d "$DB_NAME" >/dev/null 2>&1; then
          echo "PostgreSQL is ready!"
          return 0
        fi
        ;;
    esac
    
    echo "Database not ready yet. Attempt $attempt/$max_attempts..."
    sleep 2
    ((attempt++))
  done
  
  echo "Database failed to become ready after $max_attempts attempts"
  exit 1
}

# Wait for the database if environment variables are set
if [ -n "$DB_ADAPTER" ] && [ -n "$DB_HOST" ]; then
  wait_for_db "$DB_ADAPTER"
fi

# Remove a potentially pre-existing server.pid for Rails
if [ -f /app/tmp/pids/server.pid ]; then
  rm /app/tmp/pids/server.pid
fi

# Prepare database if needed
if [ "$1" = "rails" ] && [ "$2" = "server" ]; then
  echo "Preparing database..."
  bundle exec rake db:create db:migrate
  
  # Load seeds if specified
  if [ "$LOAD_SEEDS" = "true" ]; then
    echo "Loading database seeds..."
    bundle exec rake db:seed
  fi
fi

# Execute the container's main command
exec "$@"