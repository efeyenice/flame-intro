#!/bin/bash

# Add PostgreSQL database to existing Azure setup (Azure for Students compatible)
set -e

# Using your existing configuration with allowed region
RESOURCE_GROUP="rg-flame-intro"
LOCATION="germanywestcentral"  # Using allowed region for Azure for Students
DB_SERVER_NAME="flame-intro-db"
DB_ADMIN_USER="dbadmin"
DB_NAME="brickbreaker"

echo "🗄️  Adding PostgreSQL database to existing Azure setup..."
echo "📍 Using allowed region for Azure for Students: $LOCATION"

# Check if logged in
if ! az account show &>/dev/null; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

echo "📍 Using resource group: $RESOURCE_GROUP"

# Get database password
echo "⚠️  Please enter a secure password for the database admin user ($DB_ADMIN_USER):"
read -s DB_PASSWORD
echo

# Create PostgreSQL Flexible Server in allowed region
echo "🏗️  Creating PostgreSQL Flexible Server: $DB_SERVER_NAME"
echo "🌍 Location: $LOCATION (allowed by Azure for Students policy)"
az postgres flexible-server create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --location "$LOCATION" \
  --admin-user "$DB_ADMIN_USER" \
  --admin-password "$DB_PASSWORD" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 14 \
  --storage-size 32 \
  --public-access 0.0.0.0

# Create database
echo "📊 Creating database: $DB_NAME"
az postgres flexible-server db create \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$DB_SERVER_NAME" \
  --database-name "$DB_NAME"

# Configure firewall rule to allow Azure services
echo "🔓 Configuring firewall rules..."
az postgres flexible-server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Optional: Allow your current IP for direct access
CURRENT_IP=$(curl -s ifconfig.me)
az postgres flexible-server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowCurrentIP" \
  --start-ip-address "$CURRENT_IP" \
  --end-ip-address "$CURRENT_IP"

# Get the connection details
DB_HOST=$(az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --query fullyQualifiedDomainName \
  --output tsv)

echo ""
echo "✅ Database created successfully!"
echo ""
echo "📋 Your GitHub Secrets Values:"
echo "=============================="
echo "AZURE_RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AZURE_DB_HOST: $DB_HOST"
echo "POSTGRES_DB: $DB_NAME"
echo "POSTGRES_USER: $DB_ADMIN_USER"
echo "POSTGRES_PASSWORD: [the password you entered]"
echo "FRONTEND_URL: https://flame-intro-web.azurewebsites.net"
echo "CORS_ORIGIN: https://flame-intro-web.azurewebsites.net"
echo ""
echo "⚠️  Note: Database is in $LOCATION, web app is in westeurope"
echo "    This is fine - they can communicate across regions in Azure"
echo ""
echo "🔗 For API_URL, set to: https://flame-intro-containers.germanywestcentral.azurecontainer.io:8000"
echo ""
echo "🚀 Ready to add these secrets to GitHub!" 