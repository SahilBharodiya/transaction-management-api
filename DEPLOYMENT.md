# GitLab CI/CD Configuration Guide

## Required GitLab Variables

Configure these variables in your GitLab project under Settings → CI/CD → Variables:

### Registry Variables (Automatically provided by GitLab)
- `CI_REGISTRY` - GitLab Container Registry URL
- `CI_REGISTRY_USER` - Registry username 
- `CI_REGISTRY_PASSWORD` - Registry password
- `CI_REGISTRY_IMAGE` - Full image name with registry URL

### Deployment Variables (Set these manually)

#### Staging Environment
- `STAGING_DEPLOY_WEBHOOK` - Webhook URL for staging deployment
- `STAGING_URL` - URL of staging environment
- `HEALTH_CHECK_URL` - Base URL for health checks in staging

#### Production Environment  
- `PRODUCTION_DEPLOY_WEBHOOK` - Webhook URL for production deployment
- `PRODUCTION_URL` - URL of production environment
- `HEALTH_CHECK_URL` - Base URL for health checks in production

## Setting up the Pipeline

1. **Fork/Clone the repository** to your GitLab instance

2. **Configure Container Registry**
   - Go to Project Settings → General → Visibility
   - Enable Container Registry

3. **Set Environment Variables**
   - Go to Project Settings → CI/CD → Variables
   - Add the variables listed above

4. **Configure Deployment Webhooks**
   - Set up webhooks in your deployment platform (Docker Swarm, Kubernetes, etc.)
   - Add webhook URLs to GitLab variables

## Pipeline Stages

### 1. Test Stage
- **test**: Runs unit tests with pytest, generates coverage reports
- **security_scan**: Runs safety and bandit security scans
- **code_quality**: Runs flake8, black, isort, and pylint code quality checks

### 2. Build Stage
- **build**: Builds Docker image and pushes to GitLab Container Registry
- Only runs on `main` and `develop` branches

### 3. Deploy Stage
- **deploy_staging**: Deploys to staging environment (automatic on `develop`)
- **deploy_production**: Deploys to production (manual approval on `main`)
- **health_check**: Verifies deployment health after production deploy

## Branch Strategy

- **main**: Production branch
  - Triggers production deployment (manual)
  - Requires manual approval for production deploy

- **develop**: Staging branch  
  - Triggers automatic staging deployment
  - Used for integration testing

- **feature branches**: Development branches
  - Run tests and quality checks only
  - No deployment triggered

## Local Development

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

2. **Run tests**:
   ```bash
   pytest tests/ --cov=app
   ```

3. **Run quality checks**:
   ```bash
   flake8 app.py
   black --check app.py
   isort --check-only app.py
   ```

4. **Run with Docker**:
   ```bash
   docker-compose up --build
   ```

## Production Deployment

### Using Docker Swarm
```bash
docker service create \
  --name transaction-api \
  --publish 5000:5000 \
  --replicas 3 \
  $CI_REGISTRY_IMAGE:latest
```

### Using Kubernetes
```bash
kubectl apply -f k8s/deployment.yaml
```

## Monitoring and Health Checks

The application includes:
- Health check endpoint: `/health`
- Docker health checks in Dockerfile
- Kubernetes liveness and readiness probes
- Automated health verification in CI/CD

## Security Considerations

- Non-root user in Docker container
- Security scanning in CI/CD pipeline
- Rate limiting via Nginx reverse proxy
- Environment variable based configuration
- Secret management via GitLab CI/CD variables

## Scaling

The application is designed to be stateless and can be scaled horizontally:
- Multiple replicas in Kubernetes
- Load balancing via Nginx or cloud load balancers
- Persistent volume for trade data storage
- Health checks for automatic failover
