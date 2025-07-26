#!/bin/bash

# Azure Container Apps Deployment Script
set -e

# Configuration
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP}"
LOCATION="${AZURE_LOCATION:-francecentral}"
ENVIRONMENT_NAME="flame-intro-env"
BACKEND_IMAGE="${DOCKERHUB_USERNAME}/flame-intro-backend:${TAG}"
FRONTEND_IMAGE="${DOCKERHUB_USERNAME}/flame-intro:${TAG}"

# Database configuration
DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${AZURE_DB_HOST}:5432/${POSTGRES_DB}"

echo "🚀 Starting Azure Container Apps deployment..."
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Backend Image: $BACKEND_IMAGE"
echo "Frontend Image: $FRONTEND_IMAGE"

# Step 1: Deploy Container App Environment
echo "📦 Deploying Container App Environment..."
ENVIRONMENT_DEPLOYMENT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file azure/container-app-environment.bicep \
  --parameters \
    location="$LOCATION" \
    environmentName="$ENVIRONMENT_NAME" \
  --query 'properties.outputs' \
  --output json)

ENVIRONMENT_ID=$(echo "$ENVIRONMENT_DEPLOYMENT" | jq -r '.containerAppEnvironmentId.value')
echo "✅ Environment created: $ENVIRONMENT_ID"

# Step 2: Deploy Container Apps
echo "🔧 Deploying Container Apps..."
APPS_DEPLOYMENT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file azure/container-apps.bicep \
  --parameters \
    location="$LOCATION" \
    containerAppEnvironmentId="$ENVIRONMENT_ID" \
    backendImage="$BACKEND_IMAGE" \
    frontendImage="$FRONTEND_IMAGE" \
    databaseUrl="$DATABASE_URL" \
    corsOrigin="*" \
    apiUrl="TBD" \
    dockerHubUsername="$DOCKERHUB_USERNAME" \
    dockerHubPassword="$DOCKERHUB_PASSWORD" \
  --query 'properties.outputs' \
  --output json)

BACKEND_URL=$(echo "$APPS_DEPLOYMENT" | jq -r '.backendUrl.value')
FRONTEND_URL=$(echo "$APPS_DEPLOYMENT" | jq -r '.frontendUrl.value')

echo "✅ Backend deployed at: $BACKEND_URL"
echo "✅ Frontend deployed at: $FRONTEND_URL"

# Step 3: Update frontend with correct API URL (requires rebuild)
echo "🔄 Frontend needs rebuild with correct API URL..."
echo "Backend URL for frontend configuration: $BACKEND_URL"

# Step 4: Health checks
echo "🔍 Running health checks..."
sleep 30

# Check backend health
echo "Checking backend health..."
if curl -f "$BACKEND_URL/api/health" > /dev/null 2>&1; then
  echo "✅ Backend health check passed"
else
  echo "❌ Backend health check failed"
  exit 1
fi

# Check frontend
echo "Checking frontend..."
if curl -f "$FRONTEND_URL" > /dev/null 2>&1; then
  echo "✅ Frontend health check passed"
else
  echo "❌ Frontend health check failed"
  exit 1
fi

echo "🎉 Deployment completed successfully!"
echo "Frontend URL: $FRONTEND_URL"
echo "Backend URL: $BACKEND_URL"

# Save URLs for CI/CD pipeline
echo "BACKEND_URL=$BACKEND_URL" >> deployment-outputs.env
echo "FRONTEND_URL=$FRONTEND_URL" >> deployment-outputs.env 