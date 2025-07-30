# GitHub Actions Deployment Guide

## Overview

This document describes how to deploy the Transaction Management API using GitHub Actions and GitHub Container Registry.

## GitHub Actions Workflow

The CI/CD pipeline is defined in `.github/workflows/ci-cd.yml` and includes:

### Stages

1. **Test** - Run unit tests with coverage
2. **Security Scan** - Check for vulnerabilities 
3. **Code Quality** - Lint and format checks
4. **Build** - Create Docker image
5. **Deploy Staging** - Deploy to staging environment
6. **Deploy Production** - Deploy to production (manual approval)
7. **Health Check** - Verify deployment health

### Triggers

- **Push to main/master**: Full pipeline with production deployment
- **Push to develop**: Pipeline with staging deployment  
- **Pull Requests**: Test, security, and quality checks only

## Container Registry

### GitHub Container Registry (ghcr.io)

Images are automatically pushed to GitHub Container Registry:

```bash
# Latest image
ghcr.io/USERNAME/transaction-management-api:latest

# Branch-specific images
ghcr.io/USERNAME/transaction-management-api:main-abc123
ghcr.io/USERNAME/transaction-management-api:develop-def456
```

### Authentication

The workflow uses `GITHUB_TOKEN` automatically provided by GitHub Actions:

```yaml
- name: Log in to Container Registry
  uses: docker/login-action@v3
  with:
    registry: ${{ env.REGISTRY }}
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

## Environment Configuration

### Repository Secrets

Configure these in **Settings → Secrets and variables → Actions**:

| Secret | Description | Example |
|--------|-------------|---------|
| `STAGING_DEPLOY_WEBHOOK` | Staging deployment webhook URL | `https://api.staging.example.com/deploy` |
| `PRODUCTION_DEPLOY_WEBHOOK` | Production deployment webhook URL | `https://api.production.example.com/deploy` |

### Repository Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `STAGING_URL` | Staging environment URL | `https://staging.example.com` |
| `PRODUCTION_URL` | Production environment URL | `https://production.example.com` |
| `HEALTH_CHECK_URL` | Health check endpoint | `https://api.production.example.com` |

## Deployment Methods

### 1. Webhook Deployment

The workflow sends HTTP POST requests to configured webhooks:

```json
{
  "image": "ghcr.io/USERNAME/transaction-management-api:abc123"
}
```

Your webhook receiver should:
1. Pull the specified image
2. Stop the current container
3. Start a new container with the updated image

### 2. GitHub Environments

Set up environments for better control:

1. Go to **Settings → Environments**
2. Create `staging` and `production` environments
3. Configure protection rules:
   - **Staging**: Auto-deploy on develop branch
   - **Production**: Require manual approval

### 3. Self-Hosted Runners

For private infrastructure, use self-hosted runners:

```yaml
runs-on: self-hosted
```

## Docker Deployment

### Pull and Run Latest Image

```bash
# Pull latest image
docker pull ghcr.io/USERNAME/transaction-management-api:latest

# Run container
docker run -d \
  --name transaction-api \
  --restart unless-stopped \
  -p 8000:8000 \
  -v /path/to/data:/app/data \
  -e FLASK_ENV=production \
  ghcr.io/USERNAME/transaction-management-api:latest
```

### Docker Compose

```yaml
version: '3.8'
services:
  api:
    image: ghcr.io/USERNAME/transaction-management-api:latest
    ports:
      - "8000:8000"
    volumes:
      - ./data:/app/data
    environment:
      - FLASK_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## Kubernetes Deployment

### Using Existing Manifests

```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/

# Update image to latest
kubectl set image deployment/transaction-api \
  transaction-api=ghcr.io/USERNAME/transaction-management-api:latest
```

### GitOps with ArgoCD

Create ArgoCD application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: transaction-api
spec:
  source:
    repoURL: https://github.com/USERNAME/transaction-management-api
    targetRevision: main
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Cloud Platform Deployments

### AWS ECS

```bash
# Update ECS service
aws ecs update-service \
  --cluster production \
  --service transaction-api \
  --force-new-deployment
```

### Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy transaction-api \
  --image ghcr.io/USERNAME/transaction-management-api:latest \
  --platform managed \
  --region us-central1
```

### Azure Container Instances

```bash
# Deploy to ACI
az container create \
  --resource-group myResourceGroup \
  --name transaction-api \
  --image ghcr.io/USERNAME/transaction-management-api:latest
```

## Monitoring and Health Checks

### Health Check Endpoint

The API provides a health check at `/health`:

```bash
curl -f https://api.production.example.com/health
```

Response:
```json
{
  "status": "healthy",
  "message": "Transaction Management API is running",
  "timestamp": "2025-07-30T10:30:00.123456"
}
```

### GitHub Actions Health Check

The workflow automatically performs health checks:

```yaml
- name: Health check
  run: |
    for i in {1..5}; do
      if curl -f ${{ vars.HEALTH_CHECK_URL }}/health; then
        echo "Health check passed"
        exit 0
      fi
      sleep 10
    done
    exit 1
```

## Rollback Procedures

### Manual Rollback

```bash
# Find previous working image
docker images ghcr.io/USERNAME/transaction-management-api

# Deploy previous version
docker run -d \
  --name transaction-api \
  -p 8000:8000 \
  ghcr.io/USERNAME/transaction-management-api:previous-tag
```

### Kubernetes Rollback

```bash
# Rollback deployment
kubectl rollout undo deployment/transaction-api

# Check rollout status
kubectl rollout status deployment/transaction-api
```

## Troubleshooting

### Common Issues

1. **Image pull errors**:
   ```bash
   # Verify image exists
   docker pull ghcr.io/USERNAME/transaction-management-api:latest
   
   # Check authentication
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

2. **Workflow failures**:
   - Check Actions tab for detailed logs
   - Verify secrets and variables are configured
   - Check branch protection rules

3. **Deployment failures**:
   - Verify webhook endpoints are accessible
   - Check health check URL configuration
   - Review container logs

### Debug Commands

```bash
# Check workflow runs
gh run list --repo USERNAME/transaction-management-api

# View specific run
gh run view RUN_ID --repo USERNAME/transaction-management-api

# Check container logs
docker logs transaction-api

# Test health endpoint
curl -v http://localhost:8000/health
```

## Security Considerations

1. **Registry Access**: Use GitHub's built-in authentication
2. **Secrets Management**: Store sensitive data in GitHub Secrets
3. **Image Scanning**: Enable Dependabot and security advisories
4. **Network Security**: Use HTTPS for all webhook communications
5. **Access Control**: Configure appropriate repository permissions

## Performance Optimization

1. **Build Cache**: Workflow uses GitHub Actions cache for faster builds
2. **Multi-stage Builds**: Dockerfile optimized for smaller images
3. **Parallel Jobs**: Security and quality checks run in parallel
4. **Image Layers**: Optimized layer ordering for better caching
