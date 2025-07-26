# Azure Deployment Fix

## Problem

The Azure Container Apps deployment pipeline was failing with a cryptic error:

```
ERROR: The content for this response was already consumed
```

This error occurred during the `az deployment group create` step and masked the real underlying ARM deployment validation errors.

## Root Cause

1. **Resource naming conflicts**: The Bicep template had hardcoded resource names that could conflict with existing resources:
   - `logAnalyticsWorkspaceName = 'flame-intro-logs'` (hardcoded)
   - `vnetName = 'flame-intro-vnet-v2'` (hardcoded)
   - But `environmentName = 'flame-intro-env-v2'` (parameterized)

2. **ARM validation failures**: When the deployment tried to create resources that already existed, ARM returned 409 Conflict or 400 BadRequest errors that Azure CLI v2.73+ masks as the generic "content consumed" error.

3. **Error masking**: The `--no-wait` flag and lack of proper error handling meant the real ARM validation errors were hidden.

4. **Bicep conditional resource syntax**: The original attempt at conditional resource creation had syntax errors with union types and function calls.

## Solution

### 1. Made Bicep Template Idempotent

**File**: `azure/container-app-environment.bicep`

- **Parameterized all resource names**: Now all names derive consistently from `environmentName`
- **Added conditional resource creation**: Uses `forceNew` parameter to either create new resources or reference existing ones
- **Fixed conditional syntax**: Proper handling of conditional resource references without union type issues
- **Proper resource referencing**: Direct conditional logic in the Container App Environment configuration

Key changes:
```bicep
param forceNew bool = false

// Create or reference existing resources
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (forceNew) { ... }
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!forceNew) { ... }

// Use conditional logic directly in configuration
logAnalyticsConfiguration: forceNew ? {
  customerId: logAnalyticsWorkspace.properties.customerId
  sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
} : {
  customerId: existingLogAnalyticsWorkspace.properties.customerId
  sharedKey: existingLogAnalyticsWorkspace.listKeys().primarySharedKey
}
```

### 2. Improved CI/CD Pipeline

**File**: `.github/workflows/cd-container-apps.yml`

- **Added fail-fast error handling**: `set -euo pipefail` in all script blocks
- **Removed error-masking `--no-wait`**: Let deployments complete synchronously with proper error reporting
- **Smart resource detection**: Check for existing resources and set `forceNew` parameter accordingly
- **Better error visibility**: Added `--output table` for clearer command output

Key improvements:
```bash
# Check for existing infrastructure
WORKSPACE_EXISTS=$(az monitor log-analytics workspace list ...)
VNET_EXISTS=$(az network vnet list ...)

# Determine deployment strategy
if [ -n "$WORKSPACE_EXISTS" ] && [ -n "$VNET_EXISTS" ]; then
  FORCE_NEW="false"  # Reference existing
else
  FORCE_NEW="true"   # Create new
fi
```

### 3. Added Testing and Validation

**File**: `azure/test-deployment.sh`

- **Bicep syntax validation**: `az bicep build` to catch template errors early
- **Resource group validation**: Check if target resource group exists before attempting what-if
- **Graceful error handling**: Skip what-if analysis if resource group doesn't exist
- **Clear guidance**: Provides exact commands needed to set up and deploy
- **Resource existence checks**: Detect existing resources before deployment

## Benefits

1. **No more cryptic errors**: Real ARM validation errors are now visible
2. **Idempotent deployments**: Can run multiple times without conflicts
3. **Resource reuse**: Efficiently reuses existing infrastructure when appropriate
4. **Better debugging**: Clear error messages and status reporting
5. **Fail-fast behavior**: Pipeline stops immediately on first error
6. **Proper syntax**: Bicep template compiles without errors or warnings about union types

## Usage

### For CI/CD
The pipeline now automatically:
1. Detects existing resources
2. Chooses the appropriate deployment strategy
3. Provides clear error messages if something fails

### For local testing
```bash
# Test the deployment before running CI/CD
./azure/test-deployment.sh

# If resource group doesn't exist, create it first
az group create --name flame-intro-rg --location francecentral

# Run actual deployment if test passes
az deployment group create \
  --resource-group flame-intro-rg \
  --template-file azure/container-app-environment.bicep \
  --parameters location=francecentral environmentName=flame-intro-env-v2 forceNew=false
```

## Resource Naming Convention

With the fix, resources are now named consistently:

- Environment: `flame-intro-env-v2`
- Log Analytics: `flame-intro-v2-logs` 
- Virtual Network: `flame-intro-v2-vnet`
- Subnet: `container-apps-subnet`

This ensures no naming conflicts and makes resource management predictable.

## Validation

✅ **Bicep syntax**: Template compiles without errors  
✅ **Error handling**: Real errors are visible, not masked  
✅ **Idempotency**: Multiple deployments work correctly  
✅ **Resource detection**: Automatically handles existing vs new resources  
✅ **Testing**: Local validation before CI/CD execution 