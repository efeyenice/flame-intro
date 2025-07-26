#!/bin/bash

# Test script for Azure deployment
set -euo pipefail

echo "🧪 Testing Azure Container App Environment deployment..."

# Configuration
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-flame-intro-rg}"
LOCATION="${AZURE_LOCATION:-francecentral}"
ENVIRONMENT_NAME="flame-intro-env-v2"

echo "📋 Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION" 
echo "  Environment Name: $ENVIRONMENT_NAME"

# Check Azure CLI login
echo "🔐 Checking Azure CLI authentication..."
if ! az account show >/dev/null 2>&1; then
    echo "❌ Please login to Azure CLI first: az login"
    exit 1
fi
echo "✅ Azure CLI authenticated"

# Check if resource group exists
echo "🔍 Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" >/dev/null 2>&1; then
    echo "⚠️  Resource group '$RESOURCE_GROUP' does not exist."
    echo "💡 To create it, run: az group create --name $RESOURCE_GROUP --location $LOCATION"
    SKIP_RESOURCE_CHECKS=true
else
    echo "✅ Resource group exists"
    SKIP_RESOURCE_CHECKS=false
fi

# Test 1: Check Container Apps environment (the main test)
echo "🔍 Testing Container Apps environment deployment approach..."
if az containerapp env show -g "$RESOURCE_GROUP" -n "$ENVIRONMENT_NAME" >/dev/null 2>&1; then
    echo "✅ Container Apps environment already exists – deployment would skip infrastructure creation"
    ENVIRONMENT_EXISTS=true
else
    echo "📦 Container Apps environment does not exist – deployment would create new infrastructure"
    ENVIRONMENT_EXISTS=false
fi

# Test 2: Check supporting resources (only if resource group exists)
if [ "$SKIP_RESOURCE_CHECKS" = "false" ]; then
    echo "🔍 Checking supporting infrastructure..."

    WORKSPACE_EXISTS=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name flame-intro-v2-logs \
        --query name \
        --output tsv 2>/dev/null || echo "")

    echo "📊 Supporting infrastructure status:"
    echo "  Log Analytics workspace: ${WORKSPACE_EXISTS:-'Not found'}"
    echo "  Virtual Network: Skipped (using Container Apps managed networking)"

    if [ "$ENVIRONMENT_EXISTS" = "false" ]; then
        if [ -n "$WORKSPACE_EXISTS" ]; then
            echo "✅ Log Analytics workspace exists – deployment would reuse existing workspace"
        else
            echo "📦 Missing workspace – deployment would create new Log Analytics workspace"
        fi
    fi
else
    echo "⏭️  Skipping supporting infrastructure checks (no resource group)"
fi

# Test 3: Validate that we can get workspace details (if they exist)
if [ "$SKIP_RESOURCE_CHECKS" = "false" ] && [ -n "${WORKSPACE_EXISTS:-}" ]; then
    echo "🔍 Testing workspace credentials retrieval..."
    if az monitor log-analytics workspace get-shared-keys \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name flame-intro-v2-logs \
        --query primarySharedKey \
        --output tsv >/dev/null 2>&1; then
        echo "✅ Can retrieve workspace credentials"
    else
        echo "⚠️  Cannot retrieve workspace credentials – may need permissions"
    fi
fi

echo ""
echo "🎯 Deployment test completed successfully!"
echo ""
echo "💡 Deployment strategy summary:"
if [ "$ENVIRONMENT_EXISTS" = "true" ]; then
    echo "   ✅ Environment exists → Skip infrastructure creation"
else
    echo "   📦 Environment missing → Create simplified infrastructure (Log Analytics + Container Apps Environment)"
fi
echo ""
echo "💡 Network architecture:"
echo "   🌐 Using Container Apps managed networking (no custom VNet)"
echo "   🔓 Public ingress for game access (perfect for this project)"
echo "   📊 Centralized logging via Log Analytics workspace"
echo ""
echo "💡 To run actual deployment:"
echo "   # The CI/CD pipeline will automatically:"
echo "   1. Check if Container Apps environment exists"
echo "   2. Create infrastructure only if needed (Log Analytics + Environment)"
echo "   3. Deploy container apps with public access"
echo ""
echo "   # For manual deployment, ensure resource group exists first:"
echo "   az group create --name $RESOURCE_GROUP --location $LOCATION" 