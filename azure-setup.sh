#!/bin/bash

# Azure Resource Setup Script for Flame Intro
# Run this script to create all required Azure resources

set -e

# Configuration (modify these values)
RESOURCE_GROUP="flame-intro-rg"
LOCATION="eastus"
DB_SERVER_NAME="flame-intro-db"
DB_ADMIN_USER="dbadmin"
DB_NAME="brickbreaker"
WEBAPP_NAME="flame-intro-app"
CONTAINER_GROUP_NAME="flame-intro-containers"

echo "🔧 Setting up Azure resources for Flame Intro..."

# Check if user is logged in
if ! az account show &>/dev/null; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

echo "📍 Current subscription:"
az account show --output table

read -p "Continue with this subscription? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please set the correct subscription: az account set --subscription <subscription-id>"
    exit 1
fi

# Create resource group
echo "🏗️  Creating resource group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# Create PostgreSQL server
echo "🗄️  Creating PostgreSQL server: $DB_SERVER_NAME"
echo "⚠️  Please enter a secure password for the database admin user:"
read -s DB_PASSWORD

az postgres server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --location "$LOCATION" \
  --admin-user "$DB_ADMIN_USER" \
  --admin-password "$DB_PASSWORD" \
  --sku-name GP_Gen5_2 \
  --version 11

# Create database
echo "📊 Creating database: $DB_NAME"
az postgres db create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$DB_SERVER_NAME" \
  --name "$DB_NAME"

# Configure firewall rule to allow Azure services
echo "🔓 Configuring firewall rules..."
az postgres server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$DB_SERVER_NAME" \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Optional: Allow your current IP for direct access
CURRENT_IP=$(curl -s ifconfig.me)
az postgres server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$DB_SERVER_NAME" \
  --name "AllowCurrentIP" \
  --start-ip-address "$CURRENT_IP" \
  --end-ip-address "$CURRENT_IP"

# Create App Service Plan (for frontend)
echo "🌐 Creating App Service Plan..."
az appservice plan create \
  --name "${WEBAPP_NAME}-plan" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --is-linux \
  --sku B1

# Create Web App (for frontend)
echo "📱 Creating Web App: $WEBAPP_NAME"
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "${WEBAPP_NAME}-plan" \
  --name "$WEBAPP_NAME" \
  --deployment-container-image-name nginx

# Create Log Analytics Workspace (optional)
echo "📊 Creating Log Analytics Workspace..."
WORKSPACE_NAME="${RESOURCE_GROUP}-logs"
az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$WORKSPACE_NAME" \
  --location "$LOCATION"

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$WORKSPACE_NAME" \
  --query customerId \
  --output tsv)

echo ""
echo "✅ Azure resources created successfully!"
echo ""
echo "📋 GitHub Secrets Configuration:"
echo "================================"
echo "AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AZURE_DB_HOST: ${DB_SERVER_NAME}.postgres.database.azure.com"
echo "AZURE_LOG_WORKSPACE: $WORKSPACE_ID"
echo "POSTGRES_DB: $DB_NAME"
echo "POSTGRES_USER: $DB_ADMIN_USER"
echo "POSTGRES_PASSWORD: [the password you entered]"
echo ""
echo "🌐 URLs (update after first deployment):"
echo "API_URL: https://${CONTAINER_GROUP_NAME}.${LOCATION}.azurecontainer.io:8000"
echo "FRONTEND_URL: https://${WEBAPP_NAME}.azurewebsites.net"
echo "CORS_ORIGIN: https://${WEBAPP_NAME}.azurewebsites.net"
echo ""
echo "⚠️  Remember to:"
echo "1. Add all these values as GitHub Secrets"
echo "2. Create service principal for GitHub Actions"
echo "3. Configure Docker Hub credentials"
echo ""
echo "🚀 Ready for deployment!" 