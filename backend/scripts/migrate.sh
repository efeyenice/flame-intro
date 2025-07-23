#!/bin/bash

# Database Migration Script for Flame Intro Backend
set -e

# Default values
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${POSTGRES_DB:-brickbreaker}
DB_USER=${POSTGRES_USER:-user}
DB_PASSWORD=${POSTGRES_PASSWORD:-pass}

echo "🔄 Running database migrations..."
echo "📍 Database: $DB_HOST:$DB_PORT/$DB_NAME"

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER"; do
    echo "Database is not ready, waiting..."
    sleep 2
done

echo "✅ Database is ready!"

# Run migrations
echo "🏗️  Applying database schema..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$(dirname "$0")/../database/schema.sql"

echo "✅ Database migrations completed successfully!"

# Optional: Seed data (uncomment if you have seed data)
# echo "🌱 Seeding initial data..."
# PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$(dirname "$0")/../database/seed.sql"

echo "🎉 All database operations completed!" 