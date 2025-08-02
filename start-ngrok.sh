#!/bin/bash

# Ngrok setup and start script for Transaction Management API
# This script installs ngrok (if not present) and starts the tunnel

set -e

echo "🚀 Setting up ngrok for Transaction Management API..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    print_status "ngrok not found. Installing ngrok..."
    
    # Install ngrok based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
        sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
        sudo tee /etc/apt/sources.list.d/ngrok.list && \
        sudo apt update && sudo apt install ngrok
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install ngrok/ngrok/ngrok
        else
            print_error "Homebrew not found. Please install ngrok manually from https://ngrok.com/download"
            exit 1
        fi
    else
        print_error "Unsupported OS. Please install ngrok manually from https://ngrok.com/download"
        exit 1
    fi
else
    print_status "ngrok is already installed"
fi

# Check if authtoken is configured
if [ ! -f "$HOME/.ngrok2/ngrok.yml" ] && [ -z "$NGROK_AUTHTOKEN" ]; then
    print_warning "ngrok authtoken not configured!"
    print_warning "Please run: ngrok config add-authtoken YOUR_TOKEN"
    print_warning "Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken"
    
    # Check if ngrok.yml exists in current directory
    if [ -f "ngrok.yml" ]; then
        print_warning "Found ngrok.yml in current directory. Make sure to add your authtoken!"
    fi
fi

# Function to start Flask app in background
start_flask_app() {
    print_status "Starting Flask application..."
    
    # Check if virtual environment exists
    if [ -d "venv" ]; then
        print_status "Activating virtual environment..."
        source venv/bin/activate
    elif [ -d ".venv" ]; then
        print_status "Activating virtual environment..."
        source .venv/bin/activate
    fi
    
    # Install dependencies if requirements.txt exists
    if [ -f "requirements.txt" ]; then
        print_status "Installing dependencies..."
        pip install -r requirements.txt
    fi
    
    # Start Flask app
    export FLASK_ENV=development
    export FLASK_APP=app.py
    
    if command -v gunicorn &> /dev/null; then
        print_status "Starting with gunicorn..."
        gunicorn --bind 0.0.0.0:5000 --workers 1 --timeout 120 app:app &
    else
        print_status "Starting with Flask development server..."
        python app.py &
    fi
    
    FLASK_PID=$!
    echo $FLASK_PID > flask.pid
    print_status "Flask app started with PID: $FLASK_PID"
    
    # Wait for Flask to start
    sleep 3
    
    # Test if Flask is running
    if curl -f http://localhost:5000/health > /dev/null 2>&1; then
        print_status "Flask app is running and healthy"
    else
        print_warning "Flask app health check failed, but continuing..."
    fi
}

# Function to start ngrok tunnel
start_ngrok_tunnel() {
    print_status "Starting ngrok tunnel..."
    
    # Use custom config if exists
    if [ -f "ngrok.yml" ]; then
        print_status "Using custom ngrok.yml configuration"
        ngrok start --config=ngrok.yml transaction-api &
    else
        print_status "Using default configuration"
        ngrok http 5000 --log=stdout &
    fi
    
    NGROK_PID=$!
    echo $NGROK_PID > ngrok.pid
    print_status "ngrok started with PID: $NGROK_PID"
    
    # Wait for ngrok to start
    sleep 3
    
    # Get tunnel URL
    print_status "Getting tunnel information..."
    TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('proto') == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
" 2>/dev/null)
    
    if [ -n "$TUNNEL_URL" ]; then
        echo ""
        print_status "🎉 ngrok tunnel is active!"
        print_status "Public URL: $TUNNEL_URL"
        print_status "Local URL: http://localhost:5000"
        print_status "ngrok Web Interface: http://localhost:4040"
        echo ""
        print_status "Test your API:"
        print_status "curl $TUNNEL_URL/health"
        print_status "curl $TUNNEL_URL/api/trades"
        echo ""
    else
        print_warning "Could not retrieve tunnel URL. Check ngrok logs."
    fi
}

# Function to cleanup on exit
cleanup() {
    print_status "Cleaning up..."
    
    if [ -f "ngrok.pid" ]; then
        NGROK_PID=$(cat ngrok.pid)
        kill $NGROK_PID 2>/dev/null || true
        rm ngrok.pid
        print_status "Stopped ngrok (PID: $NGROK_PID)"
    fi
    
    if [ -f "flask.pid" ]; then
        FLASK_PID=$(cat flask.pid)
        kill $FLASK_PID 2>/dev/null || true
        rm flask.pid
        print_status "Stopped Flask app (PID: $FLASK_PID)"
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Main execution
case "${1:-start}" in
    "start")
        start_flask_app
        start_ngrok_tunnel
        
        print_status "Press Ctrl+C to stop both Flask and ngrok"
        wait
        ;;
    "stop")
        cleanup
        print_status "Services stopped"
        ;;
    "status")
        if [ -f "flask.pid" ] && [ -f "ngrok.pid" ]; then
            print_status "Services are running"
            if command -v curl &> /dev/null; then
                TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tunnels = data.get('tunnels', [])
    for tunnel in tunnels:
        if tunnel.get('proto') == 'https':
            print(tunnel['public_url'])
            break
except:
    pass
" 2>/dev/null)
                if [ -n "$TUNNEL_URL" ]; then
                    print_status "Tunnel URL: $TUNNEL_URL"
                fi
            fi
        else
            print_status "Services are not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        echo "  start  - Start Flask app and ngrok tunnel"
        echo "  stop   - Stop both services"
        echo "  status - Check service status"
        exit 1
        ;;
esac
