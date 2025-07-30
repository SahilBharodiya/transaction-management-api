# 🔗 Webhook Setup Guide

This guide explains how to set up webhooks for automated deployment of your Transaction Management API from GitHub.

## 📋 Overview

The webhook system consists of:
1. **GitHub Webhook** - Sends notifications when code is pushed
2. **Webhook Receiver** - Python Flask app that receives notifications
3. **Deployment Script** - Bash script that updates the running container

## 🚀 Quick Setup

### Step 1: Deploy Webhook Receiver

1. **On your server, run the webhook receiver:**
   ```bash
   # Set environment variables
   export WEBHOOK_SECRET="your-secret-key-here"
   export WEBHOOK_PORT="5001"
   export DEPLOYMENT_SCRIPT="./deploy.sh"
   
   # Install dependencies
   pip install flask
   
   # Run webhook receiver
   python webhook-receiver.py
   ```

2. **Or run with Docker:**
   ```bash
   docker run -d \
     --name webhook-receiver \
     -p 5001:5001 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v $(pwd):/app \
     -w /app \
     -e WEBHOOK_SECRET="your-secret-key" \
     -e WEBHOOK_PORT="5001" \
     python:3.11-slim \
     sh -c "pip install flask && python webhook-receiver.py"
   ```

### Step 2: Configure GitHub Webhook

1. **Go to your GitHub repository settings:**
   ```
   https://github.com/SahilBharodiya/transaction-management-api/settings/hooks
   ```

2. **Click "Add webhook"**

3. **Configure webhook:**
   - **Payload URL**: `http://your-server.com:5001/webhook/github`
   - **Content type**: `application/json`
   - **Secret**: `your-secret-key-here` (same as WEBHOOK_SECRET)
   - **Events**: Select "Push events"
   - **Active**: ✅ Checked

### Step 3: Update GitHub Actions Secrets

Add these secrets to your GitHub repository:

```
Settings → Secrets and variables → Actions
```

**Repository Secrets:**
- `PRODUCTION_DEPLOY_WEBHOOK`: `http://your-server.com:5001/webhook/github`
- `STAGING_DEPLOY_WEBHOOK`: `http://your-staging-server.com:5001/webhook/github`

**Repository Variables:**
- `PRODUCTION_URL`: `http://your-server.com:8000`
- `STAGING_URL`: `http://your-staging-server.com:8000`
- `HEALTH_CHECK_URL`: `http://your-server.com:8000`

## 🔧 Detailed Configuration

### Environment Variables

**Webhook Receiver (`webhook-receiver.py`):**
```bash
# Security
WEBHOOK_SECRET=your-secret-key-here          # GitHub webhook secret
ALLOWED_REPOS=SahilBharodiya/transaction-management-api  # Allowed repositories

# Configuration
WEBHOOK_PORT=5001                            # Port for webhook receiver
DEPLOYMENT_SCRIPT=./deploy.sh                # Path to deployment script
FLASK_ENV=production                         # Flask environment
```

**Deployment Script (`deploy.sh`):**
```bash
# Docker Configuration
DOCKER_IMAGE=ghcr.io/sahilbharodiya/transaction-management-api:latest
CONTAINER_NAME=transaction-api
HOST_PORT=8000
CONTAINER_PORT=8000
DATA_DIR=/path/to/data

# Deployment Info (automatically set by webhook)
COMMIT_SHA=abc123...                         # Git commit hash
REPO_NAME=SahilBharodiya/transaction-management-api
```

## 🌐 Cloud Platform Setup

### Option 1: DigitalOcean Droplet

1. **Create droplet and install Docker:**
   ```bash
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   
   # Install dependencies
   sudo apt install -y curl git python3 python3-pip
   ```

2. **Setup webhook:**
   ```bash
   # Clone your repository
   git clone https://github.com/SahilBharodiya/transaction-management-api.git
   cd transaction-management-api
   
   # Make scripts executable
   chmod +x deploy.sh
   chmod +x webhook-receiver.py
   
   # Setup environment
   export WEBHOOK_SECRET="your-secret-key"
   
   # Run webhook receiver
   python3 webhook-receiver.py
   ```

3. **Configure GitHub webhook:**
   - Payload URL: `http://your-droplet-ip:5001/webhook/github`

### Option 2: AWS EC2

1. **Launch EC2 instance and configure security groups:**
   - Allow HTTP (80), HTTPS (443), Custom TCP (5001, 8000)

2. **Setup webhook (same as DigitalOcean)**

3. **Configure GitHub webhook:**
   - Payload URL: `http://your-ec2-public-ip:5001/webhook/github`

### Option 3: Heroku

1. **Create Heroku app for webhook receiver:**
   ```bash
   # Create Procfile
   echo "web: python webhook-receiver.py" > Procfile
   
   # Deploy to Heroku
   heroku create your-webhook-app
   heroku config:set WEBHOOK_SECRET=your-secret-key
   heroku config:set WEBHOOK_PORT=$PORT
   git push heroku main
   ```

2. **Configure GitHub webhook:**
   - Payload URL: `https://your-webhook-app.herokuapp.com/webhook/github`

## 🔒 Security Configuration

### Generate Webhook Secret

```bash
# Generate a random secret
openssl rand -hex 32
```

### Configure Firewall

```bash
# Ubuntu/Debian
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw allow 5001  # Webhook receiver
sudo ufw allow 8000  # API
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=5001/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

## 📊 Testing

### Test Webhook Receiver

```bash
# Check if webhook receiver is running
curl http://localhost:5001/health

# Test manual deployment
curl -X POST http://localhost:5001/webhook/manual \
  -H "Content-Type: application/json" \
  -d '{"image": "ghcr.io/sahilbharodiya/transaction-management-api:latest"}'

# Check deployment status
curl http://localhost:5001/status
```

### Test GitHub Webhook

1. **Make a small change to your repository**
2. **Push to main branch**
3. **Check webhook receiver logs:**
   ```bash
   # If running directly
   # Check terminal output
   
   # If running with Docker
   docker logs webhook-receiver
   ```

## 🔧 Troubleshooting

### Common Issues

1. **Webhook receiver not accessible:**
   ```bash
   # Check if service is running
   ps aux | grep webhook-receiver
   
   # Check port is open
   netstat -tlnp | grep 5001
   
   # Check firewall
   sudo ufw status
   ```

2. **Docker permission errors:**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   newgrp docker
   ```

3. **GitHub webhook delivery failures:**
   - Check GitHub webhook delivery logs
   - Verify payload URL is accessible
   - Check webhook secret matches

### Debug Commands

```bash
# Check webhook receiver logs
tail -f /var/log/webhook-receiver.log

# Test deployment script manually
./deploy.sh

# Check container status
docker ps -a
docker logs transaction-api

# Test API health
curl http://localhost:8000/health
```

## 🚀 Production Recommendations

### 1. Use Process Manager

```bash
# Install PM2
npm install -g pm2

# Create ecosystem file
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'webhook-receiver',
    script: 'webhook-receiver.py',
    interpreter: 'python3',
    env: {
      WEBHOOK_SECRET: 'your-secret-key',
      WEBHOOK_PORT: '5001',
      FLASK_ENV: 'production'
    }
  }]
}
EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

### 2. Use Reverse Proxy

```nginx
# /etc/nginx/sites-available/webhook
server {
    listen 80;
    server_name your-domain.com;
    
    location /webhook/ {
        proxy_pass http://localhost:5001/webhook/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location / {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Enable HTTPS

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

## 📈 Monitoring

### Webhook Logs

```bash
# Add logging to webhook receiver
import logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/webhook-receiver.log'),
        logging.StreamHandler()
    ]
)
```

### Health Check Monitoring

```bash
# Create health check script
cat > health-check.sh << 'EOF'
#!/bin/bash
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "API is healthy"
else
    echo "API is down, restarting..."
    docker restart transaction-api
fi
EOF

# Add to crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/health-check.sh") | crontab -
```

## 🎯 Summary

Your webhook setup provides:
- ✅ Automated deployments on code push
- ✅ Secure webhook verification
- ✅ Health checks and monitoring
- ✅ Rollback capabilities
- ✅ Production-ready configuration

After setup, every push to your main branch will automatically:
1. Trigger GitHub Actions workflow
2. Send webhook to your server
3. Pull latest Docker image
4. Deploy new container
5. Verify deployment health
