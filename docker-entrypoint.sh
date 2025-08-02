#!/bin/bash

# Docker entrypoint script for ngrok integration
set -e

# Function to print colored output
print_status() {
    echo "[INFO] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Function to start Flask app
start_flask() {
    print_status "Starting Flask application..."
    export FLASK_ENV=development
    export FLASK_APP=app.py
    
    if command -v gunicorn &> /dev/null; then
        gunicorn --bind 0.0.0.0:5000 --workers 1 --timeout 120 app:app &
    else
        python app.py &
    fi
    
    FLASK_PID=$!
    print_status "Flask app started with PID: $FLASK_PID"
    
    # Wait for Flask to start
    sleep 3
    
    return $FLASK_PID
}

# Function to start ngrok
start_ngrok() {
    print_status "Starting ngrok tunnel..."
    
    # Check if authtoken is set
    if [ -z "$NGROK_AUTHTOKEN" ]; then
        print_warning "NGROK_AUTHTOKEN environment variable not set"
        print_warning "Using default configuration without authtoken"
        ngrok http 5000 --log=stdout &
    else
        print_status "Using authtoken from environment variable"
        ngrok config add-authtoken $NGROK_AUTHTOKEN
        
        if [ -f "/root/.ngrok2/ngrok.yml" ]; then
            ngrok start --config=/root/.ngrok2/ngrok.yml transaction-api &
        else
            ngrok http 5000 --log=stdout &
        fi
    fi
    
    NGROK_PID=$!
    print_status "ngrok started with PID: $NGROK_PID"
    
    # Wait for ngrok to start
    sleep 5
    
    # Get tunnel URL
    print_status "Getting tunnel information..."
    for i in {1..10}; do
        TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | python3 -c "
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
            break
        fi
        print_status "Waiting for tunnel to be ready... (attempt $i/10)"
        sleep 2
    done
    
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
        
        # Write tunnel URL to file for other processes
        echo $TUNNEL_URL > /tmp/tunnel_url
    else
        print_warning "Could not retrieve tunnel URL"
    fi
    
    return $NGROK_PID
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    jobs -p | xargs -r kill
    exit 0
}

# Set trap for cleanup
trap cleanup SIGTERM SIGINT

# Main execution
case "${1:-start}" in
    "start")
        print_status "Starting Transaction Management API with ngrok..."
        
        # Start Flask app
        start_flask
        FLASK_PID=$!
        
        # Start ngrok
        start_ngrok
        NGROK_PID=$!
        
        print_status "Both services started. Press Ctrl+C to stop."
        
        # Wait for either process to exit
        wait
        ;;
    "flask-only")
        print_status "Starting Flask app only..."
        start_flask
        wait
        ;;
    "ngrok-only")
        print_status "Starting ngrok tunnel only..."
        start_ngrok
        wait
        ;;
    "status")
        print_status "Checking service status..."
        
        # Check Flask
        if curl -f http://localhost:5000/health > /dev/null 2>&1; then
            print_status "Flask app is running"
        else
            print_status "Flask app is not running"
        fi
        
        # Check ngrok
        if curl -f http://localhost:4040/api/tunnels > /dev/null 2>&1; then
            print_status "ngrok is running"
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
        else
            print_status "ngrok is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {start|flask-only|ngrok-only|status}"
        echo "  start       - Start both Flask and ngrok"
        echo "  flask-only  - Start only Flask app"
        echo "  ngrok-only  - Start only ngrok tunnel"
        echo "  status      - Check service status"
        exit 1
        ;;
esac
