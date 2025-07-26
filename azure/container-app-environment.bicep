@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Container App Environment')
param environmentName string = 'flame-intro-env-v2'

@description('Log Analytics workspace name')
param logAnalyticsWorkspaceName string = '${replace(environmentName, '-env', '')}-logs'

@description('Virtual Network name')  
param vnetName string = '${replace(environmentName, '-env', '')}-vnet'

@description('Subnet name for Container Apps')
param subnetName string = 'container-apps-subnet'

@description('Whether to create new resources or use existing ones')
param forceNew bool = false

// Create or reference existing Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (forceNew) {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Reference existing Log Analytics Workspace if not creating new
resource existingLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = if (!forceNew) {
  name: logAnalyticsWorkspaceName
}

// Create or reference existing Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = if (forceNew) {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/21'
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

// Reference existing Virtual Network if not creating new
resource existingVnet 'Microsoft.Network/virtualNetworks@2022-07-01' existing = if (!forceNew) {
  name: vnetName
}

// Create Container App Environment with conditional Log Analytics configuration
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: forceNew ? {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      } : {
        customerId: existingLogAnalyticsWorkspace.properties.customerId
        sharedKey: existingLogAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: forceNew ? '${vnet.id}/subnets/${subnetName}' : '${existingVnet.id}/subnets/${subnetName}'
    }
  }
}

// Output important values
output containerAppEnvironmentId string = containerAppEnvironment.id
output containerAppEnvironmentName string = containerAppEnvironment.name
output vnetId string = forceNew ? vnet.id : existingVnet.id
output logAnalyticsWorkspaceId string = forceNew ? logAnalyticsWorkspace.id : existingLogAnalyticsWorkspace.id 