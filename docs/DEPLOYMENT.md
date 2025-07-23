# Deployment Guide

## Overview

This project uses a multicontainer architecture deployed to Azure with the following components:

- **Frontend**: Flutter web app (flame-intro)
- **Backend**: Node.js API server (flame-intro-backend)  
- **Database**: PostgreSQL

## Architecture

```
┌─────────────────┐     HTTP/JSON      ┌─────────────────┐
│   Flutter Game  │ ◄─────────────────► │   Backend API   │
│   (Container 1) │                     │   (Container 2) │
│   Port: 80      │                     │   Port: 8000    │
└─────────────────┘                     └─────────────────┘
                                                 │
                                                 ▼
                                        ┌─────────────────┐
                                        │   PostgreSQL    │
                                        │   (Container 3) │
                                        │   Port: 5432    │
                                        └─────────────────┘
```

## CI/CD Pipeline

### Continuous Integration (.github/workflows/ci.yml)

1. **Frontend Tests**: Flutter analyze, test, and build
2. **Backend Tests**: Node.js test suite
3. **Docker Build**: Build and push both frontend and backend images to Docker Hub
4. **GitHub Pages**: Deploy frontend to GitHub Pages for preview

### Continuous Deployment (.github/workflows/cd.yml)

1. **Database Migration**: Run schema updates on Azure PostgreSQL
2. **Container Deployment**: Deploy multicontainer setup to Azure
3. **Health Checks**: Verify frontend and backend are responding

### Manual Deployment (.github/workflows/deploy-manual.yml)

Allows manual deployment of specific tags to staging or production environments.

## Required Secrets

### GitHub Secrets

Configure these secrets in your GitHub repository settings:

#### Azure Configuration
- `AZURE_CREDENTIALS`: Azure service principal credentials (JSON)
- `AZURE_RESOURCE_GROUP`: Azure resource group name
- `AZURE_DB_HOST`: PostgreSQL server hostname
- `AZURE_LOG_WORKSPACE`: Log Analytics workspace ID

#### Docker Hub
- `DOCKERHUB_USERNAME`: Docker Hub username
- `DOCKERHUB_TOKEN`: Docker Hub access token

#### Database
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Database username  
- `POSTGRES_PASSWORD`: Database password

#### Application URLs
- `API_URL`: Backend API URL (e.g., https://api.example.com)
- `FRONTEND_URL`: Frontend URL (e.g., https://app.example.com)
- `CORS_ORIGIN`: Allowed CORS origins

## Local Development

### Prerequisites
- Docker and Docker Compose
- Node.js 18+
- Flutter SDK
- PostgreSQL client tools

### Setup

1. Clone the repository
2. Copy environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

3. Start services:
   ```bash
   docker-compose up -d
   ```

4. Run migrations:
   ```bash
   ./backend/scripts/migrate.sh
   ```

5. Access the application:
   - Frontend: http://localhost:3000
   - Backend: http://localhost:8000
   - Database: localhost:5432

## Production Deployment

### Azure Setup

1. **Create Azure Resources**:
   ```bash
   # Create resource group
   az group create --name flame-intro-rg --location eastus
   
   # Create PostgreSQL server
   az postgres server create \
     --resource-group flame-intro-rg \
     --name flame-intro-db \
     --admin-user dbadmin \
     --admin-password <secure-password>
   ```

2. **Configure GitHub Secrets**: Add all required secrets to your repository

3. **Deploy**: Push to main branch or use manual deployment workflow

### Manual Deployment

Use the manual deployment workflow for:
- Emergency deployments
- Deploying specific versions
- Testing in staging environment

1. Go to Actions → Manual Deploy to Azure
2. Select environment and tag
3. Run workflow

## Database Migrations

### Automatic Migrations
Migrations run automatically during deployment via CI/CD pipeline.

### Manual Migrations
Run migrations manually using the migration script:

```bash
# Local
./backend/scripts/migrate.sh

# Production (with environment variables)
export DB_HOST=your-azure-db-host
export POSTGRES_USER=your-db-user
export POSTGRES_PASSWORD=your-db-password
export POSTGRES_DB=your-db-name
./backend/scripts/migrate.sh
```

## Monitoring and Health Checks

### Health Endpoints

- **Backend**: `GET /api/health`
- **Database**: Connection check via backend

### Logs

- Azure Container Instances logs available in Azure portal
- Log Analytics workspace configured for centralized logging

## Troubleshooting

### Common Issues

1. **Container startup failures**:
   - Check environment variables are set correctly
   - Verify Docker images exist in Docker Hub
   - Review container logs in Azure portal

2. **Database connection issues**:
   - Ensure PostgreSQL server allows connections
   - Verify firewall rules in Azure
   - Check connection string format

3. **CORS errors**:
   - Verify `CORS_ORIGIN` is set correctly
   - Check frontend is using correct API URL

### Rollback Procedure

1. Use manual deployment workflow
2. Select previous working tag
3. Deploy to production environment

## Security Considerations

- All secrets stored in GitHub Secrets
- Database connections use TLS
- CORS properly configured
- Container images scanned for vulnerabilities
- Regular security updates via Dependabot

## Performance Optimization

- Docker images use multi-stage builds
- Static assets served via CDN-ready setup
- Database queries optimized with indexes
- Container resource limits configured 