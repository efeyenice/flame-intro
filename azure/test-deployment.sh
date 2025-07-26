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
    echo "📝 Continuing with syntax validation only..."
    SKIP_WHAT_IF=true
else
    echo "✅ Resource group exists"
    SKIP_WHAT_IF=false
fi

# Test 1: Validate Bicep template syntax
echo "🔍 Testing Bicep template syntax..."
if az bicep build --file azure/container-app-environment.bicep --stdout >/dev/null 2>&1; then
    echo "✅ Bicep template syntax is valid"
else
    echo "❌ Bicep template has syntax errors"
    echo "🔧 Running syntax check with full output:"
    az bicep build --file azure/container-app-environment.bicep --stdout
    exit 1
fi

# Test 2: What-if deployment (dry run) - only if resource group exists
if [ "$SKIP_WHAT_IF" = "false" ]; then
    echo "🎯 Running what-if deployment analysis..."
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file azure/container-app-environment.bicep \
        --parameters \
            location="$LOCATION" \
            environmentName="$ENVIRONMENT_NAME" \
            forceNew=false \
        --result-format FullResourcePayloads

    echo "✅ What-if analysis completed"

    # Test 3: Check for existing resources
    echo "🔍 Checking for existing resources..."

    ENVIRONMENT_EXISTS=$(az containerapp env list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?name=='$ENVIRONMENT_NAME'].name" \
        --output tsv 2>/dev/null || echo "")

    WORKSPACE_EXISTS=$(az monitor log-analytics workspace list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?name=='flame-intro-v2-logs'].name" \
        --output tsv 2>/dev/null || echo "")

    VNET_EXISTS=$(az network vnet list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?name=='flame-intro-v2-vnet'].name" \
        --output tsv 2>/dev/null || echo "")

    echo "📊 Existing resources status:"
    echo "  Environment: ${ENVIRONMENT_EXISTS:-'Not found'}"
    echo "  Log Analytics: ${WORKSPACE_EXISTS:-'Not found'}"
    echo "  Virtual Network: ${VNET_EXISTS:-'Not found'}"

    # Determine deployment strategy
    if [ -n "$WORKSPACE_EXISTS" ] && [ -n "$VNET_EXISTS" ]; then
        FORCE_NEW="false"
        echo "✅ Will reference existing infrastructure (forceNew=false)"
    else
        FORCE_NEW="true"
        echo "📦 Will create new infrastructure (forceNew=true)"
    fi
else
    FORCE_NEW="true"
    echo "⏭️  Skipping what-if analysis and resource checks (no resource group)"
fi

echo ""
echo "🎯 Deployment test completed successfully!"
echo "💡 To run actual deployment:"
echo "   # First ensure resource group exists:"
echo "   az group create --name $RESOURCE_GROUP --location $LOCATION"
echo ""
echo "   # Then deploy the environment:"
echo "   az deployment group create \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --template-file azure/container-app-environment.bicep \\"
echo "     --parameters location=$LOCATION environmentName=$ENVIRONMENT_NAME forceNew=$FORCE_NEW" 