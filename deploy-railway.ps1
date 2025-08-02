# Railway deployment script for Transaction Management API (Windows PowerShell)
# This script helps automate Railway deployment setup

param(
    [Parameter(Position=0)]
    [ValidateSet("quick-deploy", "interactive")]
    [string]$Mode = "interactive"
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Header {
    param([string]$Message)
    Write-Host "[RAILWAY] $Message" -ForegroundColor Blue
}

Write-Header "🚂 Railway Deployment Setup for Transaction Management API"
Write-Host ""

# Check if Railway CLI is installed
$railwayPath = Get-Command railway -ErrorAction SilentlyContinue
if (-not $railwayPath) {
    Write-Warning "Railway CLI not found. Installing Railway CLI..."
    
    # Check if Chocolatey is available
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoPath) {
        Write-Status "Installing Railway CLI via Chocolatey..."
        choco install railway -y
    } else {
        Write-Warning "Chocolatey not found. Please install Railway CLI manually:"
        Write-Warning "1. Visit: https://docs.railway.app/develop/cli#installing-the-cli"
        Write-Warning "2. Download and install Railway CLI"
        Write-Warning "3. Or install Chocolatey and run: choco install railway"
        exit 1
    }
} else {
    Write-Status "Railway CLI is already installed"
}

# Check Railway CLI version
try {
    $railwayVersion = railway --version 2>$null
    Write-Status "Railway CLI version: $railwayVersion"
} catch {
    Write-Status "Railway CLI version: unknown"
}

# Login to Railway
Write-Status "Checking Railway authentication..."
try {
    $whoami = railway whoami 2>$null
    if ($whoami) {
        Write-Status "Already logged into Railway as: $whoami"
    } else {
        throw "Not authenticated"
    }
} catch {
    Write-Warning "Not logged into Railway. Please login:"
    railway login
}

# Function to create new Railway project
function New-RailwayProject {
    Write-Status "Creating new Railway project..."
    
    # Initialize Railway project
    railway init
    
    # Link to GitHub repository (optional)
    $linkGitHub = Read-Host "Do you want to link this to your GitHub repository? (y/n)"
    if ($linkGitHub -eq 'y' -or $linkGitHub -eq 'Y') {
        Write-Status "Linking to GitHub repository..."
        railway connect
    }
}

# Function to deploy to Railway
function Deploy-ToRailway {
    Write-Status "Deploying to Railway..."
    
    # Set environment variables
    Write-Status "Setting environment variables..."
    railway variables set FLASK_ENV=production
    railway variables set FLASK_APP=app.py
    railway variables set PYTHONPATH=.
    
    # Deploy
    Write-Status "Starting deployment..."
    railway up
    
    # Get deployment URL
    Write-Status "Getting deployment URL..."
    try {
        $railwayUrl = railway domain 2>$null
        
        if ($railwayUrl) {
            Write-Host ""
            Write-Status "🎉 Deployment successful!"
            Write-Status "Your API is available at: https://$railwayUrl"
            Write-Status "Health check: https://$railwayUrl/health"
            Write-Status "API endpoints: https://$railwayUrl/api/trades"
            Write-Host ""
        } else {
            Write-Warning "Deployment completed but could not retrieve URL"
            Write-Warning "Check your Railway dashboard: https://railway.app/dashboard"
        }
    } catch {
        Write-Warning "Could not retrieve deployment URL"
        Write-Warning "Check your Railway dashboard: https://railway.app/dashboard"
    }
}

# Function to setup environment variables
function Set-EnvironmentVariables {
    Write-Status "Setting up environment variables..."
    
    # Production environment
    railway variables set FLASK_ENV=production
    railway variables set FLASK_APP=app.py
    railway variables set PYTHONPATH=.
    
    # Optional: Set custom variables
    $setSecretKey = Read-Host "Do you want to set a custom Flask secret key? (y/n)"
    if ($setSecretKey -eq 'y' -or $setSecretKey -eq 'Y') {
        $flaskSecretKey = Read-Host "Enter Flask secret key" -AsSecureString
        $plainSecretKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($flaskSecretKey))
        railway variables set FLASK_SECRET_KEY="$plainSecretKey"
    }
    
    # Optional: Set ngrok token for development
    $setNgrokToken = Read-Host "Do you want to set ngrok auth token for development? (y/n)"
    if ($setNgrokToken -eq 'y' -or $setNgrokToken -eq 'Y') {
        $ngrokAuthToken = Read-Host "Enter ngrok auth token" -AsSecureString
        $plainNgrokToken = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($ngrokAuthToken))
        railway variables set NGROK_AUTHTOKEN="$plainNgrokToken"
    }
    
    Write-Status "Environment variables set successfully"
}

# Function to add database
function Add-Database {
    Write-Status "Adding PostgreSQL database..."
    
    # Add PostgreSQL plugin
    railway add postgresql
    
    Write-Status "PostgreSQL database added successfully"
    Write-Status "Database credentials will be automatically injected as environment variables"
}

# Function to setup custom domain
function Set-CustomDomain {
    $customDomain = Read-Host "Enter your custom domain (e.g., api.yourdomain.com)"
    
    if ($customDomain) {
        Write-Status "Adding custom domain: $customDomain"
        railway domain add $customDomain
        
        Write-Status "Custom domain added. Please configure your DNS:"
        Write-Status "Add a CNAME record pointing $customDomain to your Railway domain"
    }
}

# Function to show Railway dashboard
function Show-Dashboard {
    Write-Status "Opening Railway dashboard..."
    railway open
}

# Function to show menu
function Show-Menu {
    Write-Host ""
    Write-Header "Choose an action:"
    Write-Host "1) Create new Railway project"
    Write-Host "2) Deploy to Railway"
    Write-Host "3) Setup environment variables"
    Write-Host "4) Add PostgreSQL database"
    Write-Host "5) Setup custom domain"
    Write-Host "6) Open Railway dashboard"
    Write-Host "7) Show project status"
    Write-Host "8) View logs"
    Write-Host "9) Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-9)"
    
    switch ($choice) {
        "1" { New-RailwayProject }
        "2" { Deploy-ToRailway }
        "3" { Set-EnvironmentVariables }
        "4" { Add-Database }
        "5" { Set-CustomDomain }
        "6" { Show-Dashboard }
        "7" { 
            Write-Status "Project status:"
            railway status
        }
        "8" {
            Write-Status "Viewing logs..."
            railway logs
        }
        "9" {
            Write-Status "Goodbye!"
            exit 0
        }
        default {
            Write-Error "Invalid choice. Please try again."
            Show-Menu
        }
    }
}

# Quick deploy mode
if ($Mode -eq "quick-deploy") {
    Write-Status "Quick deploy mode"
    
    # Check if already initialized
    if (-not (Test-Path "railway.toml")) {
        New-RailwayProject
    }
    
    Set-EnvironmentVariables
    Deploy-ToRailway
    exit 0
}

# Interactive mode
while ($true) {
    Show-Menu
    Write-Host ""
    $continue = Read-Host "Do you want to perform another action? (y/n)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Status "Goodbye!"
        break
    }
}
