@description('Location for all resources')
param location string = resourceGroup().location

@description('Container App Environment ID')
param containerAppEnvironmentId string

@description('Backend container image')
param backendImage string

@description('Frontend container image')
param frontendImage string

@description('Database connection string')
@secure()
param databaseUrl string

@description('CORS origin for backend')
param corsOrigin string

@description('API URL for frontend')
param apiUrl string

@description('Docker Hub username')
param dockerHubUsername string

@description('Docker Hub password')
@secure()
param dockerHubPassword string

// Create Backend Container App
resource backendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'flame-intro-backend'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: 'index.docker.io'
          username: dockerHubUsername
          passwordSecretRef: 'dockerhub-password'
        }
      ]
      secrets: [
        {
          name: 'dockerhub-password'
          value: dockerHubPassword
        }
        {
          name: 'database-url'
          value: databaseUrl
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'backend'
          image: backendImage
          env: [
            {
              name: 'DATABASE_URL'
              secretRef: 'database-url'
            }
            {
              name: 'PORT'
              value: '8000'
            }
            {
              name: 'CORS_ORIGIN'
              value: corsOrigin
            }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/api/health'
                port: 8000
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
            {
              type: 'Liveness'
              httpGet: {
                path: '/api/health'
                port: 8000
              }
              initialDelaySeconds: 30
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

// Create Frontend Container App
resource frontendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'flame-intro-frontend'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironmentId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        allowInsecure: false
      }
      registries: [
        {
          server: 'index.docker.io'
          username: dockerHubUsername
          passwordSecretRef: 'dockerhub-password'
        }
      ]
      secrets: [
        {
          name: 'dockerhub-password'
          value: dockerHubPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: frontendImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/'
                port: 80
              }
              initialDelaySeconds: 5
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    backendApp
  ]
}

// Output important values
output backendFqdn string = backendApp.properties.configuration.ingress.fqdn
output frontendFqdn string = frontendApp.properties.configuration.ingress.fqdn
output backendUrl string = 'https://${backendApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}' 