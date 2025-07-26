# Azure Container Apps Deployment Guide

## Overview

This document describes the migration from Azure Container Instances to Azure Container Apps for the Flame Intro Brick Breaker game. This change provides proper container orchestration, networking, and service discovery.

## Architecture

### Before (Container Instances)
- Backend: Individual Azure Container Instance
- Frontend: Azure Web App  
- Database: Azure Database for PostgreSQL
- **Issues**: No container networking, hardcoded URLs, CORS problems

### After (Container Apps)
- Backend: Azure Container App with external ingress
- Frontend: Azure Container App with external ingress
- Database: Azure Database for PostgreSQL (unchanged)
- **Benefits**: Proper networking, service discovery, auto-scaling, better monitoring

## Key Components

### 1. Container App Environment (`azure/container-app-environment.bicep`)
- Creates shared infrastructure for all container apps
- Sets up virtual networking and log analytics
- Provides isolated environment for container communication

### 2. Container Apps (`azure/container-apps.bicep`)
- Defines backend and frontend container apps
- Configures ingress, scaling, and health checks
- Manages secrets and environment variables

### 3. Updated CI/CD Pipeline (`.github/workflows/cd-container-apps.yml`)
- Deploys backend first to get URL
- Builds frontend with correct API URL
- Updates CORS configuration dynamically
- Comprehensive health checks

## Deployment Process

### Step-by-Step Flow

1. **Build Phase (CI Pipeline)**
   - Flutter tests and builds
   - Docker images built and pushed to DockerHub
   - Tags generated for deployment

2. **Infrastructure Deployment**
   - Container App Environment created/updated
   - Virtual network and log analytics configured

3. **Backend Deployment**
   - Backend container app deployed first
   - Database migrations executed
   - Health checks performed
   - Backend URL captured

4. **Frontend Deployment**
   - Frontend rebuilt with backend URL
   - Frontend container app deployed
   - CORS configuration updated

5. **Validation**
   - Health checks for both services
   - API connectivity tests
   - End-to-end validation

## Environment Variables Required

### GitHub Secrets
```bash
AZURE_CREDENTIALS          # Azure service principal credentials
AZURE_RESOURCE_GROUP        # Resource group name
DOCKERHUB_USERNAME         # Docker Hub username
DOCKERHUB_TOKEN            # Docker Hub access token
POSTGRES_USER              # Database username
POSTGRES_PASSWORD          # Database password
POSTGRES_DB                # Database name
AZURE_DB_HOST              # Database host
CORS_ORIGIN                # Initial CORS origin (updated dynamically)
```

## Configuration Features

### Dynamic API URL Resolution
The frontend uses multiple strategies to find the backend:

1. **Runtime Configuration**: JavaScript `window.API_URL`
2. **Compile-time**: `--dart-define` during build
3. **Auto-detection**: Based on container app naming
4. **Fallback**: localhost for development

### Enhanced Error Handling
- Retry logic for all API calls
- Comprehensive logging
- Graceful offline mode

### Health Checks
- Readiness and liveness probes
- Multi-attempt validation
- Service dependency checks

## Container App Configuration

### Backend Container App
```yaml
Resources: 0.5 CPU, 1Gi memory
Scaling: 1-3 replicas based on concurrent requests
Ingress: External HTTPS
Health: /api/health endpoint
Secrets: Database URL, Docker credentials
```

### Frontend Container App
```yaml
Resources: 0.25 CPU, 0.5Gi memory  
Scaling: 1-5 replicas based on concurrent requests
Ingress: External HTTPS
Health: Root endpoint check
Registry: Docker Hub with credentials
```

## Monitoring and Logs

### Log Analytics Integration
- Centralized logging for all containers
- Application insights available
- Performance monitoring included

### Health Check Endpoints
- Backend: `https://backend-url/api/health`
- Frontend: `https://frontend-url/`
- API Test: `https://backend-url/api/leaderboard`

## Deployment Commands

### Manual Deployment
```bash
# Set environment variables
export AZURE_RESOURCE_GROUP="your-resource-group"
export DOCKERHUB_USERNAME="your-username"
export TAG="your-image-tag"

# Run deployment
./azure/deploy.sh
```

### GitHub Actions
Deployment triggers automatically on successful CI pipeline completion.

## Troubleshooting

### Common Issues

1. **Container App Environment Creation Fails**
   - Check Azure provider registration
   - Verify resource group permissions
   - Ensure region availability

2. **Backend Health Check Fails**
   - Check database connectivity
   - Verify environment variables
   - Review container logs

3. **Frontend API Connectivity Issues**
   - Verify backend URL in build logs
   - Check CORS configuration
   - Test API endpoints manually

4. **Scaling Issues**
   - Monitor resource usage
   - Check scaling rules configuration
   - Review container limits

### Debugging Commands

```bash
# Check container app status
az containerapp show --name flame-intro-backend --resource-group $RG

# View logs
az containerapp logs show --name flame-intro-backend --resource-group $RG

# Test endpoints
curl https://your-backend-url/api/health
curl https://your-frontend-url
```

## Migration from Container Instances

### Cleanup Old Resources
1. Delete existing container instances
2. Remove old web app (optional)
3. Keep database and resource group

### DNS Considerations
- Container Apps get new FQDNs
- Update any external DNS records
- Consider custom domains if needed

## Security Considerations

- All secrets stored in Azure Key Vault or GitHub Secrets
- HTTPS enforced for all ingress
- Database connections use TLS
- Container registry authentication required

## Cost Optimization

- Right-sized container resources
- Auto-scaling based on demand
- Shared infrastructure with Container App Environment
- Pay-per-use pricing model

## Next Steps

1. **Custom Domains**: Add custom domain names
2. **SSL Certificates**: Configure custom SSL certificates  
3. **CDN Integration**: Add Azure CDN for frontend
4. **Blue-Green Deployment**: Implement advanced deployment strategies
5. **Monitoring**: Enhanced application insights and alerting 