# Railway Deployment Guide

This guide explains how to deploy your Transaction Management API to Railway.com, a modern platform for deploying applications with excellent GitHub integration.

## Table of Contents

- [What is Railway?](#what-is-railway)
- [Prerequisites](#prerequisites)
- [Quick Deployment](#quick-deployment)
- [Manual Deployment](#manual-deployment)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [Custom Domains](#custom-domains)
- [CI/CD Integration](#cicd-integration)
- [Monitoring and Logs](#monitoring-and-logs)
- [Troubleshooting](#troubleshooting)

## What is Railway?

Railway is a deployment platform designed to streamline the software development life-cycle, starting with instant deployments and effortless scale to more complex needs. Key features:

- **Instant Deployments**: Deploy from GitHub with zero configuration
- **Built-in CI/CD**: Automatic deployments on git push
- **Database Management**: One-click PostgreSQL, MySQL, Redis, and more
- **Environment Management**: Separate staging and production environments
- **Custom Domains**: Easy custom domain setup with SSL
- **Real-time Logs**: Live application logs and metrics

## Prerequisites

1. **Railway Account**: Sign up at [https://railway.app](https://railway.app)
2. **GitHub Repository**: Your code should be in a GitHub repository
3. **Railway CLI** (optional): For command-line deployments

## Quick Deployment

### Method 1: One-Click GitHub Deploy

1. **Connect GitHub Repository**:
   - Visit [Railway Dashboard](https://railway.app/dashboard)
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository: `SahilBharodiya/transaction-management-api`

2. **Automatic Configuration**:
   - Railway automatically detects this is a Python Flask app
   - Uses the `Procfile` and `railway.json` for configuration
   - Starts deployment immediately

3. **Access Your App**:
   - Get your URL from the Railway dashboard
   - Test: `https://your-app.railway.app/health`

### Method 2: Using Deployment Scripts

#### PowerShell (Windows)
```powershell
# Quick deploy
.\deploy-railway.ps1 quick-deploy

# Interactive setup
.\deploy-railway.ps1 interactive
```

#### Bash (Linux/macOS/WSL)
```bash
# Make script executable
chmod +x deploy-railway.sh

# Quick deploy
./deploy-railway.sh quick-deploy

# Interactive setup
./deploy-railway.sh
```

### Method 3: Railway CLI

```bash
# Install Railway CLI
curl -fsSL https://railway.app/install.sh | sh  # Linux/macOS
# or
choco install railway  # Windows with Chocolatey

# Login to Railway
railway login

# Initialize project
railway init

# Deploy
railway up
```

## Manual Deployment

### Step 1: Create Railway Project

1. **Login to Railway**: Visit [railway.app](https://railway.app) and sign in
2. **New Project**: Click "New Project" in your dashboard
3. **Deploy from GitHub**: Select "Deploy from GitHub repo"
4. **Repository Selection**: Choose `SahilBharodiya/transaction-management-api`
5. **Branch Selection**: Select the branch to deploy (usually `main` or `develop`)

### Step 2: Configure Environment Variables

In your Railway project dashboard:

1. **Go to Variables tab**
2. **Add these variables**:

#### Required Variables
```
FLASK_ENV=production
FLASK_APP=app.py
PYTHONPATH=.
```

#### Optional Variables
```
FLASK_SECRET_KEY=your-secret-key-here
LOG_LEVEL=INFO
NGROK_AUTHTOKEN=your-ngrok-token  # For development/testing
```

### Step 3: Deploy

1. **Trigger Deployment**: Railway automatically deploys on git push
2. **Manual Deploy**: Click "Deploy" in the Railway dashboard
3. **Monitor Progress**: Watch the build logs in real-time

### Step 4: Access Your Application

1. **Get URL**: Find your app URL in the Railway dashboard
2. **Test Endpoints**:
   ```bash
   # Health check
   curl https://your-app.railway.app/health
   
   # API endpoints
   curl https://your-app.railway.app/api/trades
   ```

## Environment Variables

### Production Configuration

Set these variables in your Railway dashboard:

```bash
# Core Flask Configuration
FLASK_ENV=production
FLASK_APP=app.py
PYTHONPATH=.
PORT=$PORT  # Railway sets this automatically

# Security
FLASK_SECRET_KEY=your-very-secure-secret-key-here

# Logging
LOG_LEVEL=INFO

# Optional: API Configuration
API_DEBUG=false
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=100
```

### Development/Staging Configuration

For a staging environment:

```bash
# Core Configuration
FLASK_ENV=development
FLASK_APP=app.py
PYTHONPATH=.

# Development Tools
NGROK_AUTHTOKEN=your-ngrok-token-for-testing
API_DEBUG=true

# Logging
LOG_LEVEL=DEBUG
```

### Using Railway CLI for Variables

```bash
# Set individual variables
railway variables set FLASK_ENV=production
railway variables set FLASK_SECRET_KEY=your-secret-key

# Set multiple variables from file
railway variables set --from-file .env.production
```

## Database Setup

### Add PostgreSQL Database

#### Using Railway Dashboard

1. **Add Plugin**: Go to your project → "Add Plugin" → "PostgreSQL"
2. **Automatic Configuration**: Railway automatically injects database credentials
3. **Environment Variables**: Access via `DATABASE_URL` or individual variables:
   - `PGHOST`
   - `PGPORT`
   - `PGDATABASE`
   - `PGUSER`
   - `PGPASSWORD`

#### Using Railway CLI

```bash
# Add PostgreSQL
railway add postgresql

# View database info
railway variables
```

### Update Application for Database

If you want to use PostgreSQL instead of JSON files, update your `app.py`:

```python
import os
import psycopg2
from urllib.parse import urlparse

# Database configuration
DATABASE_URL = os.environ.get('DATABASE_URL')

if DATABASE_URL:
    # Parse database URL
    url = urlparse(DATABASE_URL)
    
    # Database connection
    conn = psycopg2.connect(
        database=url.path[1:],
        user=url.username,
        password=url.password,
        host=url.hostname,
        port=url.port
    )
    
    # Use database for trades storage
    # ... implement database operations
else:
    # Fallback to JSON file storage
    # ... existing JSON file operations
```

## Custom Domains

### Setup Custom Domain

#### Using Railway Dashboard

1. **Domains Tab**: Go to your project → "Domains"
2. **Add Domain**: Click "Add Domain"
3. **Enter Domain**: Type your domain (e.g., `api.yourdomain.com`)
4. **DNS Configuration**: Add CNAME record pointing to Railway

#### Using Railway CLI

```bash
# Add custom domain
railway domain add api.yourdomain.com

# List domains
railway domain list

# Remove domain
railway domain remove api.yourdomain.com
```

### DNS Configuration

Add a CNAME record in your DNS provider:

```
Type: CNAME
Name: api (or your subdomain)
Value: your-project.railway.app
TTL: 300 (or your preference)
```

### SSL Certificate

Railway automatically provides SSL certificates for custom domains via Let's Encrypt.

## CI/CD Integration

### GitHub Actions Integration

The project includes GitHub Actions workflows that support Railway deployment:

#### Environment Setup

Set these secrets in your GitHub repository:

1. **Go to Repository Settings** → "Secrets and variables" → "Actions"
2. **Add Repository Secrets**:
   ```
   RAILWAY_TOKEN=your-railway-token
   ```

3. **Add Repository Variables**:
   ```
   RAILWAY_STAGING_URL=https://your-staging-app.railway.app
   RAILWAY_PRODUCTION_URL=https://your-production-app.railway.app
   ```

#### Get Railway Token

```bash
# Login to Railway CLI
railway login

# Get token (Railway v3+)
railway auth

# Or check your token in Railway dashboard → Account → Tokens
```

#### Deployment Workflow

The CI/CD pipeline automatically:

1. **On `develop` branch**: Deploys to Railway staging environment
2. **On `main` branch**: Deploys to Railway production environment
3. **Health Checks**: Automatically tests deployed applications
4. **Rollback**: Keeps previous versions for easy rollback

### Manual CI/CD Trigger

```bash
# Deploy specific branch
git push origin develop  # Triggers staging deployment
git push origin main     # Triggers production deployment

# Or manually trigger in GitHub Actions tab
```

## Monitoring and Logs

### Application Logs

#### Railway Dashboard

1. **Logs Tab**: Go to your project → "Logs"
2. **Real-time Logs**: View live application logs
3. **Filter Logs**: Filter by service, time, or search terms

#### Railway CLI

```bash
# View logs
railway logs

# Follow logs in real-time
railway logs --follow

# Filter logs
railway logs --filter "ERROR"
```

### Application Metrics

Railway provides built-in metrics:

1. **Metrics Tab**: Go to your project → "Metrics"
2. **Available Metrics**:
   - CPU usage
   - Memory usage
   - Network traffic
   - Response times
   - Request count

### Health Monitoring

Set up health check monitoring:

```bash
# Test health endpoint
curl https://your-app.railway.app/health

# Automated monitoring (add to cron or monitoring service)
#!/bin/bash
URL="https://your-app.railway.app/health"
if curl -f $URL; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    # Send alert
fi
```

## Scaling and Performance

### Vertical Scaling

Railway automatically handles scaling based on your plan:

1. **Hobby Plan**: 512MB RAM, 1 vCPU
2. **Pro Plan**: Up to 32GB RAM, 32 vCPUs
3. **Team Plan**: Enterprise-grade resources

### Horizontal Scaling

```bash
# Scale instances (Pro plan and above)
railway scale --replicas 3
```

### Performance Optimization

1. **Gunicorn Configuration**: Already optimized in `Procfile`
   ```
   web: gunicorn --bind 0.0.0.0:$PORT app:app --workers 1 --timeout 120
   ```

2. **Environment Variables**:
   ```bash
   # Optimize for production
   FLASK_ENV=production
   PYTHONOPTIMIZE=1
   ```

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Problem**: "Build failed" or "No Procfile found"

**Solution**:
```bash
# Ensure Procfile exists and is correct
cat Procfile
# Should contain: web: gunicorn --bind 0.0.0.0:$PORT app:app

# Check requirements.txt
cat requirements.txt
# Should include gunicorn
```

#### 2. Application Not Starting

**Problem**: "Application error" or "Service unavailable"

**Solutions**:
```bash
# Check logs
railway logs

# Verify environment variables
railway variables

# Test locally first
python app.py
```

#### 3. Database Connection Issues

**Problem**: "Database connection failed"

**Solutions**:
```bash
# Check database status
railway status

# Verify DATABASE_URL
railway variables | grep DATABASE

# Test database connection
railway run python -c "import psycopg2; print('DB OK')"
```

#### 4. Port Binding Issues

**Problem**: "Port already in use" or "Cannot bind to port"

**Solution**:
```python
# Ensure app.py uses PORT environment variable
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(debug=False, host="0.0.0.0", port=port)
```

#### 5. Environment Variable Issues

**Problem**: Variables not being recognized

**Solutions**:
```bash
# List all variables
railway variables

# Set missing variables
railway variables set FLASK_ENV=production

# Check variable format (no spaces around =)
railway variables set KEY=value  # ✅ Correct
railway variables set KEY = value  # ❌ Incorrect
```

### Getting Help

1. **Railway Documentation**: [docs.railway.app](https://docs.railway.app)
2. **Railway Discord**: [discord.gg/railway](https://discord.gg/railway)
3. **Railway GitHub**: [github.com/railwayapp](https://github.com/railwayapp)
4. **Support**: [help.railway.app](https://help.railway.app)

## Cost Optimization

### Hobby Plan ($5/month)

- Perfect for development and small projects
- 512MB RAM, 1 vCPU
- $5 monthly credit included

### Pro Plan ($20/month)

- Production workloads
- Higher resource limits
- Custom domains included
- Priority support

### Usage Monitoring

```bash
# Check current usage
railway status

# View billing information
railway billing
```

## Best Practices

### 1. Environment Management

- Use separate Railway projects for staging and production
- Set appropriate environment variables for each environment
- Use Railway's environment feature for better organization

### 2. Security

```bash
# Always use environment variables for secrets
railway variables set FLASK_SECRET_KEY=your-secure-key

# Never commit secrets to git
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
```

### 3. Database Management

- Use Railway's PostgreSQL plugin for production
- Regular database backups (available in Pro plan)
- Monitor database performance

### 4. Monitoring

- Set up health checks
- Monitor application logs
- Use Railway's metrics for performance insights

### 5. Deployment

- Use CI/CD for automated deployments
- Test in staging before production
- Keep deployment scripts in version control

---

## Quick Reference Commands

```bash
# Installation
curl -fsSL https://railway.app/install.sh | sh

# Authentication
railway login

# Project Management
railway init                    # Initialize project
railway link                    # Link to existing project
railway status                  # Show project status

# Deployment
railway up                      # Deploy current directory
railway up --detach            # Deploy without following logs

# Environment Variables
railway variables               # List all variables
railway variables set KEY=value # Set variable
railway variables unset KEY     # Remove variable

# Services
railway add postgresql          # Add PostgreSQL database
railway add redis              # Add Redis cache

# Domains
railway domain                  # List domains
railway domain add example.com  # Add custom domain

# Logs and Monitoring
railway logs                    # View logs
railway logs --follow          # Follow logs in real-time

# Environment Management
railway environment             # List environments
railway environment staging     # Switch to staging
railway environment production  # Switch to production
```

For more detailed information, visit the [Railway Documentation](https://docs.railway.app).
