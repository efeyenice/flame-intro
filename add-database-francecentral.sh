#!/bin/bash

# Add PostgreSQL database using France Central (Azure for Students compatible)
set -e

# Configuration - trying France Central
RESOURCE_GROUP="rg-flame-intro"
LOCATION="francecentral"  # Different allowed region
DB_SERVER_NAME="flame-intro-db"
DB_ADMIN_USER="dbadmin"
DB_NAME="brickbreaker"

echo "🗄️  Setting up PostgreSQL database for Azure for Students..."
echo "🌍 Trying France Central region for PostgreSQL..."

# Check if logged in
if ! az account show &>/dev/null; then
    echo "❌ Please login to Azure first: az login"
    exit 1
fi

# Get database password
echo "⚠️  Please enter a secure password for the database admin user ($DB_ADMIN_USER):"
read -s DB_PASSWORD
echo

# Create PostgreSQL Flexible Server
echo "🏗️  Creating PostgreSQL Flexible Server: $DB_SERVER_NAME"
echo "🌍 Location: $LOCATION"
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

# Configure firewall rules
echo "🔓 Configuring firewall rules..."
az postgres flexible-server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Get current IP and allow it
CURRENT_IP=$(curl -s ifconfig.me)
az postgres flexible-server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowCurrentIP" \
  --start-ip-address "$CURRENT_IP" \
  --end-ip-address "$CURRENT_IP"

# Get connection details
DB_HOST=$(az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DB_SERVER_NAME" \
  --query fullyQualifiedDomainName \
  --output tsv)

echo ""
echo "🎉 Database setup completed successfully!"
echo ""
echo "📋 GitHub Secrets to Add:"
echo "========================="
echo ""
echo "1. AZURE_RESOURCE_GROUP"
echo "   Value: $RESOURCE_GROUP"
echo ""
echo "2. AZURE_DB_HOST"
echo "   Value: $DB_HOST"
echo ""
echo "3. POSTGRES_DB"
echo "   Value: $DB_NAME"
echo ""
echo "4. POSTGRES_USER"
echo "   Value: $DB_ADMIN_USER"
echo ""
echo "5. POSTGRES_PASSWORD"
echo "   Value: [the password you just entered]"
echo ""
echo "6. API_URL"
echo "   Value: https://flame-intro-containers.francecentral.azurecontainer.io:8000"
echo ""
echo "7. FRONTEND_URL"
echo "   Value: https://flame-intro-web.azurewebsites.net"
echo ""
echo "8. CORS_ORIGIN"
echo "   Value: https://flame-intro-web.azurewebsites.net"
echo ""
echo "🚀 Next steps:"
echo "1. Add all 8 secrets above to your GitHub repository"
echo "2. Push to main branch or use Manual Deploy workflow"
echo "3. Monitor deployment in GitHub Actions"
echo ""
echo "✅ Ready for deployment!" 