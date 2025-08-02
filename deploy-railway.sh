#!/bin/bash

# Railway deployment script for Transaction Management API
# This script helps automate Railway deployment setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}[RAILWAY]${NC} $1"
}

print_header "🚂 Railway Deployment Setup for Transaction Management API"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    print_warning "Railway CLI not found. Installing Railway CLI..."
    
    # Install Railway CLI based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://railway.app/install.sh | sh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install railway
        else
            curl -fsSL https://railway.app/install.sh | sh
        fi
    else
        print_error "Unsupported OS. Please install Railway CLI manually:"
        print_error "Visit: https://docs.railway.app/develop/cli#installing-the-cli"
        exit 1
    fi
else
    print_status "Railway CLI is already installed"
fi

# Check Railway CLI version
RAILWAY_VERSION=$(railway --version 2>/dev/null || echo "unknown")
print_status "Railway CLI version: $RAILWAY_VERSION"

# Login to Railway
print_status "Checking Railway authentication..."
if ! railway whoami &> /dev/null; then
    print_warning "Not logged into Railway. Please login:"
    railway login
else
    print_status "Already logged into Railway as: $(railway whoami)"
fi

# Function to create new Railway project
create_railway_project() {
    print_status "Creating new Railway project..."
    
    # Initialize Railway project
    railway init
    
    # Link to GitHub repository (optional)
    read -p "Do you want to link this to your GitHub repository? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Linking to GitHub repository..."
        railway connect
    fi
}

# Function to deploy to Railway
deploy_to_railway() {
    print_status "Deploying to Railway..."
    
    # Set environment variables
    print_status "Setting environment variables..."
    railway variables set FLASK_ENV=production
    railway variables set FLASK_APP=app.py
    railway variables set PYTHONPATH=.
    
    # Deploy
    print_status "Starting deployment..."
    railway up
    
    # Get deployment URL
    print_status "Getting deployment URL..."
    RAILWAY_URL=$(railway domain 2>/dev/null || echo "")
    
    if [ -n "$RAILWAY_URL" ]; then
        echo ""
        print_status "🎉 Deployment successful!"
        print_status "Your API is available at: https://$RAILWAY_URL"
        print_status "Health check: https://$RAILWAY_URL/health"
        print_status "API endpoints: https://$RAILWAY_URL/api/trades"
        echo ""
    else
        print_warning "Deployment completed but could not retrieve URL"
        print_warning "Check your Railway dashboard: https://railway.app/dashboard"
    fi
}

# Function to setup environment variables
setup_environment_variables() {
    print_status "Setting up environment variables..."
    
    # Production environment
    railway variables set FLASK_ENV=production
    railway variables set FLASK_APP=app.py
    railway variables set PYTHONPATH=.
    
    # Optional: Set custom variables
    read -p "Do you want to set a custom Flask secret key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Flask secret key: " -s FLASK_SECRET_KEY
        echo
        railway variables set FLASK_SECRET_KEY="$FLASK_SECRET_KEY"
    fi
    
    # Optional: Set ngrok token for development
    read -p "Do you want to set ngrok auth token for development? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter ngrok auth token: " -s NGROK_AUTHTOKEN
        echo
        railway variables set NGROK_AUTHTOKEN="$NGROK_AUTHTOKEN"
    fi
    
    print_status "Environment variables set successfully"
}

# Function to add database
add_database() {
    print_status "Adding PostgreSQL database..."
    
    # Add PostgreSQL plugin
    railway add postgresql
    
    print_status "PostgreSQL database added successfully"
    print_status "Database credentials will be automatically injected as environment variables"
}

# Function to setup custom domain
setup_custom_domain() {
    read -p "Enter your custom domain (e.g., api.yourdomain.com): " CUSTOM_DOMAIN
    
    if [ -n "$CUSTOM_DOMAIN" ]; then
        print_status "Adding custom domain: $CUSTOM_DOMAIN"
        railway domain add "$CUSTOM_DOMAIN"
        
        print_status "Custom domain added. Please configure your DNS:"
        print_status "Add a CNAME record pointing $CUSTOM_DOMAIN to your Railway domain"
    fi
}

# Function to show Railway dashboard
show_dashboard() {
    print_status "Opening Railway dashboard..."
    railway open
}

# Main menu
show_menu() {
    echo ""
    print_header "Choose an action:"
    echo "1) Create new Railway project"
    echo "2) Deploy to Railway"
    echo "3) Setup environment variables"
    echo "4) Add PostgreSQL database"
    echo "5) Setup custom domain"
    echo "6) Open Railway dashboard"
    echo "7) Show project status"
    echo "8) View logs"
    echo "9) Exit"
    echo ""
    read -p "Enter your choice (1-9): " choice
    
    case $choice in
        1)
            create_railway_project
            ;;
        2)
            deploy_to_railway
            ;;
        3)
            setup_environment_variables
            ;;
        4)
            add_database
            ;;
        5)
            setup_custom_domain
            ;;
        6)
            show_dashboard
            ;;
        7)
            print_status "Project status:"
            railway status
            ;;
        8)
            print_status "Viewing logs..."
            railway logs
            ;;
        9)
            print_status "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please try again."
            show_menu
            ;;
    esac
}

# Quick deploy option
if [ "$1" = "quick-deploy" ]; then
    print_status "Quick deploy mode"
    
    # Check if already initialized
    if [ ! -f "railway.toml" ]; then
        create_railway_project
    fi
    
    setup_environment_variables
    deploy_to_railway
    exit 0
fi

# Show menu for interactive mode
while true; do
    show_menu
    echo ""
    read -p "Do you want to perform another action? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Goodbye!"
        break
    fi
done
