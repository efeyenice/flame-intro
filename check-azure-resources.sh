#!/bin/bash

# Script to check existing Azure resources for Flame Intro

echo "🔍 Checking Azure resources..."

# Check if logged in
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure. Please run: az login"
    exit 1
fi

echo "✅ Logged into Azure"
echo "📍 Current subscription:"
az account show --query '{name:name, id:id}' --output table

echo ""
echo "🏗️  Resource Groups:"
az group list --query '[].{Name:name, Location:location}' --output table

echo ""
echo "🗄️  PostgreSQL Servers:"
az postgres server list --query '[].{Name:name, ResourceGroup:resourceGroup, Host:fullyQualifiedDomainName, State:userVisibleState}' --output table

echo ""
echo "🌐 Web Apps:"
az webapp list --query '[].{Name:name, ResourceGroup:resourceGroup, DefaultHostName:defaultHostName, State:state}' --output table

echo ""
echo "📊 Container Groups:"
az container list --query '[].{Name:name, ResourceGroup:resourceGroup, State:instanceView.state}' --output table

echo ""
echo "💡 Based on the output above, you can determine:"
echo "   - AZURE_RESOURCE_GROUP: The resource group name"
echo "   - AZURE_DB_HOST: The PostgreSQL server host (fullyQualifiedDomainName)"
echo "   - API_URL: Will be container group URL + :8000"
echo "   - FRONTEND_URL: The web app defaultHostName" 