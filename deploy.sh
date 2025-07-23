#!/bin/bash

# Azure Multicontainer Deployment Script for Flame Intro
set -e

# Check if required environment variables are set
required_vars=(
    "AZURE_RESOURCE_GROUP"
    "DOCKERHUB_USERNAME" 
    "TAG"
    "POSTGRES_DB"
    "POSTGRES_USER"
    "POSTGRES_PASSWORD"
    "CORS_ORIGIN"
    "API_URL"
)

echo "🔍 Checking required environment variables..."
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set"
        exit 1
    fi
done
echo "✅ All required environment variables are set"

# Deploy the multicontainer setup to Azure
echo "🚀 Deploying multicontainer setup to Azure..."

# Create Azure Container Group with docker-compose
az container create \
    --resource-group "$AZURE_RESOURCE_GROUP" \
    --name "flame-intro-app" \
    --file docker-compose.prod.yml \
    --environment-variables \
        DOCKERHUB_USERNAME="$DOCKERHUB_USERNAME" \
        TAG="$TAG" \
        POSTGRES_DB="$POSTGRES_DB" \
        POSTGRES_USER="$POSTGRES_USER" \
        POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        CORS_ORIGIN="$CORS_ORIGIN" \
        API_URL="$API_URL" \
    --log-analytics-workspace "$AZURE_LOG_WORKSPACE" || echo "⚠️  Container group might already exist"

echo "✅ Deployment completed!"

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 60

# Health checks
echo "🏥 Running health checks..."

# Check backend health
if curl -f "$API_URL/api/health" 2>/dev/null; then
    echo "✅ Backend health check passed"
else
    echo "❌ Backend health check failed"
fi

# Check frontend
if curl -f "$FRONTEND_URL" 2>/dev/null; then
    echo "✅ Frontend health check passed"
else
    echo "❌ Frontend health check failed"
fi

echo "🎉 Deployment process completed!"
echo "🌐 Frontend URL: $FRONTEND_URL"
echo "🔗 Backend API URL: $API_URL" 