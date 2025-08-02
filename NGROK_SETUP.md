# Ngrok Integration Guide

This guide explains how to set up and use ngrok with the Transaction Management API to expose your local development server to the internet.

## Table of Contents

- [What is ngrok?](#what-is-ngrok)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Options](#configuration-options)
- [Usage Methods](#usage-methods)
- [Docker Integration](#docker-integration)
- [CI/CD Integration](#cicd-integration)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## What is ngrok?

ngrok is a unified ingress platform that puts your services online, assigns them a public URL, and handles ingress. It's particularly useful for:

- **Webhook Development**: Receive webhooks from external services
- **API Testing**: Share your local API with team members or external services
- **Mobile Development**: Test your API from mobile devices
- **Debugging**: Inspect HTTP traffic in real-time

## Prerequisites

1. **ngrok Account**: Sign up at [https://ngrok.com](https://ngrok.com)
2. **Auth Token**: Get your auth token from [https://dashboard.ngrok.com/get-started/your-authtoken](https://dashboard.ngrok.com/get-started/your-authtoken)
3. **Python Environment**: Python 3.11+ with required dependencies

## Quick Start

### Method 1: Using PowerShell Script (Windows)

```powershell
# 1. Set your ngrok auth token (replace with your actual token)
$env:NGROK_AUTHTOKEN = "your_ngrok_authtoken_here"

# 2. Run the setup script
.\start-ngrok.ps1 start
```

### Method 2: Using Bash Script (Linux/macOS/WSL)

```bash
# 1. Set your ngrok auth token
export NGROK_AUTHTOKEN="your_ngrok_authtoken_here"

# 2. Make script executable and run
chmod +x start-ngrok.sh
./start-ngrok.sh start
```

### Method 3: Manual Setup

```bash
# 1. Install ngrok
# Windows (Chocolatey): choco install ngrok
# macOS (Homebrew): brew install ngrok/ngrok/ngrok
# Linux: Follow instructions at https://ngrok.com/download

# 2. Configure auth token
ngrok config add-authtoken your_ngrok_authtoken_here

# 3. Start your Flask app
python app.py

# 4. In another terminal, start ngrok
ngrok http 5000
```

## Configuration Options

### Basic Configuration (`ngrok.yml`)

The project includes a comprehensive `ngrok.yml` configuration file:

```yaml
version: "2"
authtoken: YOUR_NGROK_AUTHTOKEN_HERE

tunnels:
  transaction-api:
    proto: http
    addr: localhost:5000
    schemes: [http, https]
    bind_tls: true
    inspect: true

region: us
log_level: info
```

### Advanced Configuration Options

```yaml
tunnels:
  transaction-api:
    proto: http
    addr: localhost:5000
    schemes: [https]
    hostname: my-custom-domain.ngrok.io  # Custom domain (paid plans)
    subdomain: my-api                    # Custom subdomain (paid plans)
    auth: "username:password"            # Basic authentication
    bind_tls: true
    inspect: true
    
    # Request/Response modification
    request_headers:
      add:
        - "X-Ngrok-Tunnel: transaction-api"
        - "X-Forwarded-Host: my-api.ngrok.io"
    
    # Webhook verification
    verify_webhook:
      provider: "github"
      secret: "your-webhook-secret"
```

## Usage Methods

### 1. Script-based Usage

#### Windows PowerShell

```powershell
# Start both Flask and ngrok
.\start-ngrok.ps1 start

# Stop services
.\start-ngrok.ps1 stop

# Check status
.\start-ngrok.ps1 status
```

#### Bash (Linux/macOS/WSL)

```bash
# Start both Flask and ngrok
./start-ngrok.sh start

# Stop services
./start-ngrok.sh stop

# Check status
./start-ngrok.sh status
```

### 2. Programmatic Usage (Python)

```python
from ngrok_manager import NgrokManager

# Initialize manager
manager = NgrokManager(authtoken="your_token")

# Start tunnel
tunnel_url = manager.start_tunnel(port=5000)
print(f"API available at: {tunnel_url}")

# Get webhook URL
webhook_url = manager.get_webhook_url("/webhook/github")
print(f"GitHub webhook URL: {webhook_url}")

# Test tunnel
if manager.test_tunnel("/health"):
    print("Tunnel is working!")

# Cleanup
manager.stop_tunnel()
```

### 3. Context Manager Usage

```python
from ngrok_manager import NgrokManager

with NgrokManager(authtoken="your_token") as manager:
    tunnel_url = manager.start_tunnel(port=5000)
    print(f"Tunnel active: {tunnel_url}")
    
    # Your code here
    input("Press Enter to stop tunnel...")
    
# Tunnel automatically stopped
```

## Docker Integration

### Build and Run with Docker

```bash
# Build the ngrok-enabled image
docker build -f Dockerfile.ngrok -t transaction-api-ngrok .

# Run with environment variables
docker run -d \
  -p 5000:5000 \
  -p 4040:4040 \
  -e NGROK_AUTHTOKEN=your_token_here \
  --name api-ngrok \
  transaction-api-ngrok
```

### Using Docker Compose

```bash
# Set environment variables
export NGROK_AUTHTOKEN=your_token_here

# Start services
docker-compose -f docker-compose.ngrok.yml up -d transaction-api-ngrok

# View logs
docker-compose -f docker-compose.ngrok.yml logs -f transaction-api-ngrok

# Stop services
docker-compose -f docker-compose.ngrok.yml down
```

### Multiple Profile Setup

```bash
# Start basic API only
docker-compose -f docker-compose.ngrok.yml up transaction-api

# Start with ngrok
docker-compose -f docker-compose.ngrok.yml up transaction-api-ngrok

# Start with database
docker-compose -f docker-compose.ngrok.yml --profile with-db up

# Start with cache
docker-compose -f docker-compose.ngrok.yml --profile with-cache up

# Start with proxy
docker-compose -f docker-compose.ngrok.yml --profile with-proxy up
```

## CI/CD Integration

The project includes GitHub Actions workflow integration for ngrok tunnels in development/testing environments.

### Environment Variables for CI/CD

Set these secrets in your GitHub repository:

```
NGROK_AUTHTOKEN=your_ngrok_authtoken
STAGING_DEPLOY_WEBHOOK=your_staging_webhook_url
PRODUCTION_DEPLOY_WEBHOOK=your_production_webhook_url
```

### Testing with ngrok in CI/CD

```yaml
- name: Start ngrok tunnel for testing
  run: |
    ngrok authtoken ${{ secrets.NGROK_AUTHTOKEN }}
    ngrok http 5000 --log=stdout &
    sleep 5
    
- name: Run integration tests
  run: |
    TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
    pytest tests/integration/ --tunnel-url=$TUNNEL_URL
```

## Security Considerations

### 1. Auth Token Protection

- **Never commit** your ngrok auth token to version control
- Use environment variables or secret management
- Rotate tokens regularly

### 2. Basic Authentication

```yaml
tunnels:
  secure-api:
    proto: http
    addr: localhost:5000
    auth: "username:secure_password"
```

### 3. Custom Domain Verification

```yaml
tunnels:
  verified-api:
    proto: http
    addr: localhost:5000
    hostname: api.yourdomain.com
    verify_webhook:
      provider: "github"
      secret: "your-webhook-secret"
```

### 4. IP Whitelisting (Enterprise)

```yaml
tunnels:
  restricted-api:
    proto: http
    addr: localhost:5000
    cidr_allow:
      - "192.168.1.0/24"
      - "10.0.0.0/8"
```

## Testing Your Setup

### 1. Health Check

```bash
# Local health check
curl http://localhost:5000/health

# Tunnel health check (replace URL)
curl https://your-tunnel-url.ngrok.io/health
```

### 2. API Endpoints

```bash
# Get all trades
curl https://your-tunnel-url.ngrok.io/api/trades

# Create a trade
curl -X POST https://your-tunnel-url.ngrok.io/api/trades \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "quantity": 100,
    "price": 150.00,
    "side": "BUY"
  }'
```

### 3. Webhook Testing

```bash
# Test webhook endpoint
curl -X POST https://your-tunnel-url.ngrok.io/webhook/github \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: push" \
  -d '{"test": "data"}'
```

## Monitoring and Debugging

### 1. ngrok Web Interface

Access the web interface at: `http://localhost:4040`

Features:
- Real-time request inspection
- Replay requests
- Traffic statistics
- Configuration details

### 2. API Monitoring

```python
# Monitor API with tunnel
import requests
import time

def monitor_api(tunnel_url):
    while True:
        try:
            response = requests.get(f"{tunnel_url}/health")
            print(f"Health check: {response.status_code}")
        except Exception as e:
            print(f"Error: {e}")
        time.sleep(30)

monitor_api("https://your-tunnel-url.ngrok.io")
```

### 3. Log Analysis

```bash
# View ngrok logs
docker-compose -f docker-compose.ngrok.yml logs ngrok

# View API logs
docker-compose -f docker-compose.ngrok.yml logs transaction-api-ngrok

# Follow logs in real-time
docker-compose -f docker-compose.ngrok.yml logs -f
```

## Troubleshooting

### Common Issues

#### 1. "ngrok not found"

**Solution:**
```bash
# Install ngrok
# Windows: choco install ngrok
# macOS: brew install ngrok/ngrok/ngrok
# Linux: Download from https://ngrok.com/download
```

#### 2. "Authentication required"

**Solution:**
```bash
# Set auth token
ngrok config add-authtoken your_token_here

# Or set environment variable
export NGROK_AUTHTOKEN=your_token_here
```

#### 3. "Tunnel connection failed"

**Solutions:**
- Check internet connection
- Verify auth token is correct
- Try different region: `ngrok http 5000 --region=eu`
- Check firewall settings

#### 4. "Port already in use"

**Solutions:**
```bash
# Find process using port 5000
lsof -i :5000  # macOS/Linux
netstat -ano | findstr :5000  # Windows

# Kill process
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows
```

#### 5. "Flask app not responding"

**Solutions:**
- Ensure Flask is bound to `0.0.0.0:5000`
- Check Flask logs for errors
- Verify health endpoint: `curl http://localhost:5000/health`

### Getting Help

1. **ngrok Status**: [https://status.ngrok.com](https://status.ngrok.com)
2. **ngrok Documentation**: [https://ngrok.com/docs](https://ngrok.com/docs)
3. **Community Support**: [https://discuss.ngrok.com](https://discuss.ngrok.com)
4. **GitHub Issues**: Create an issue in this repository

## Advanced Features

### 1. Multiple Tunnels

```yaml
tunnels:
  api:
    proto: http
    addr: localhost:5000
  
  admin:
    proto: http
    addr: localhost:5001
    subdomain: admin
  
  websocket:
    proto: http
    addr: localhost:8080
```

### 2. TCP Tunnels

```yaml
tunnels:
  database:
    proto: tcp
    addr: localhost:5432
```

### 3. File Server

```yaml
tunnels:
  files:
    proto: http
    addr: file:///path/to/files
```

### 4. Load Balancing

```yaml
tunnels:
  api-lb:
    proto: http
    addr: localhost:5000
    load_balancer:
      - addr: localhost:5001
      - addr: localhost:5002
```

## Best Practices

1. **Development Workflow**
   - Use ngrok for webhook development
   - Test with real external services
   - Monitor traffic with web interface

2. **Security**
   - Use HTTPS tunnels in production
   - Implement basic auth for sensitive endpoints
   - Monitor tunnel access logs

3. **Performance**
   - Use regional endpoints close to your users
   - Monitor latency with ngrok web interface
   - Consider ngrok Edge for production workloads

4. **Team Collaboration**
   - Share tunnel URLs for quick demos
   - Use custom subdomains for consistent URLs
   - Document tunnel configurations in your project

---

For more information, visit the [official ngrok documentation](https://ngrok.com/docs).
