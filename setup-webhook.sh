#!/bin/bash

# Webhook Setup Script for Transaction Management API
# This script helps you set up webhooks for automated deployment

set -e

echo "🔗 Webhook Setup for Transaction Management API"
echo "==============================================="

# Function to prompt for input
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    local secret="$4"
    
    if [ "$secret" = "true" ]; then
        read -s -p "$prompt: " input
        echo
    else
        if [ -n "$default" ]; then
            read -p "$prompt [$default]: " input
            if [ -z "$input" ]; then
                input="$default"
            fi
        else
            read -p "$prompt: " input
            while [ -z "$input" ]; do
                echo "This field is required."
                read -p "$prompt: " input
            done
        fi
    fi
    
    eval "$var_name='$input'"
}

# Get configuration
echo
echo "📝 Webhook Configuration"
echo "------------------------"

prompt_input "Server domain/IP" SERVER_DOMAIN "localhost"
prompt_input "Webhook secret (32+ characters)" WEBHOOK_SECRET "" "true"
prompt_input "API port" API_PORT "8000"
prompt_input "Webhook port" WEBHOOK_PORT "5001"

echo
echo "🔍 Configuration Summary"
echo "------------------------"
echo "Server: $SERVER_DOMAIN"
echo "API Port: $API_PORT"
echo "Webhook Port: $WEBHOOK_PORT"
echo "Webhook Secret: [HIDDEN]"

read -p "Continue with setup? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Setup cancelled."
    exit 0
fi

echo
echo "🚀 Setting up webhook environment..."

# Create .env file
cat > .env << EOF
# Webhook Configuration
WEBHOOK_SECRET=$WEBHOOK_SECRET
WEBHOOK_PORT=$WEBHOOK_PORT
API_PORT=$API_PORT
SERVER_DOMAIN=$SERVER_DOMAIN

# Docker Configuration
DOCKER_IMAGE=ghcr.io/sahilbharodiya/transaction-management-api:latest
CONTAINER_NAME=transaction-api
DATA_DIR=./data
EOF

echo "✅ Created .env file"

# Make scripts executable
chmod +x deploy.sh
chmod +x webhook-receiver.py
echo "✅ Made scripts executable"

# Create data directory
mkdir -p data
echo "✅ Created data directory"

# Generate systemd service (optional)
if command -v systemctl &> /dev/null; then
    read -p "Create systemd service for webhook receiver? (y/n): " create_service
    if [ "$create_service" = "y" ]; then
        sudo tee /etc/systemd/system/webhook-receiver.service > /dev/null << EOF
[Unit]
Description=Transaction API Webhook Receiver
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
Environment=WEBHOOK_SECRET=$WEBHOOK_SECRET
Environment=WEBHOOK_PORT=$WEBHOOK_PORT
ExecStart=/usr/bin/python3 $(pwd)/webhook-receiver.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        sudo systemctl daemon-reload
        sudo systemctl enable webhook-receiver
        echo "✅ Created systemd service"
    fi
fi

echo
echo "🎉 Webhook setup completed!"
echo "=========================="
echo
echo "📋 Next Steps:"
echo "1. Start the webhook receiver:"
echo "   python3 webhook-receiver.py"
echo "   # OR with Docker Compose:"
echo "   docker-compose -f docker-compose.webhook.yml up -d"
echo
echo "2. Configure GitHub webhook:"
echo "   - Go to: https://github.com/SahilBharodiya/transaction-management-api/settings/hooks"
echo "   - Payload URL: http://$SERVER_DOMAIN:$WEBHOOK_PORT/webhook/github"
echo "   - Content type: application/json"
echo "   - Secret: [your webhook secret]"
echo "   - Events: Push events"
echo
echo "3. Update GitHub repository secrets:"
echo "   - PRODUCTION_DEPLOY_WEBHOOK: http://$SERVER_DOMAIN:$WEBHOOK_PORT/webhook/github"
echo "   - STAGING_DEPLOY_WEBHOOK: http://$SERVER_DOMAIN:$WEBHOOK_PORT/webhook/github"
echo
echo "4. Update GitHub repository variables:"
echo "   - PRODUCTION_URL: http://$SERVER_DOMAIN:$API_PORT"
echo "   - HEALTH_CHECK_URL: http://$SERVER_DOMAIN:$API_PORT"
echo
echo "🔧 Test Commands:"
echo "# Test webhook receiver"
echo "curl http://$SERVER_DOMAIN:$WEBHOOK_PORT/health"
echo
echo "# Test manual deployment"
echo "curl -X POST http://$SERVER_DOMAIN:$WEBHOOK_PORT/webhook/manual \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"image\": \"ghcr.io/sahilbharodiya/transaction-management-api:latest\"}'"
echo
echo "📚 Documentation:"
echo "- Detailed setup: WEBHOOK_SETUP.md"
echo "- Deployment guide: GITHUB_DEPLOYMENT.md"
echo
echo "🎯 Your webhook system is ready for automated deployments!"
