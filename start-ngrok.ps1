# Ngrok setup and start script for Transaction Management API (Windows PowerShell)
# This script installs ngrok (if not present) and starts the tunnel

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "status")]
    [string]$Action = "start"
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

Write-Status "🚀 Setting up ngrok for Transaction Management API..."

# Check if ngrok is installed
$ngrokPath = Get-Command ngrok -ErrorAction SilentlyContinue
if (-not $ngrokPath) {
    Write-Status "ngrok not found. Installing ngrok..."
    
    # Check if Chocolatey is available
    $chocoPath = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoPath) {
        Write-Status "Installing ngrok via Chocolatey..."
        choco install ngrok -y
    } else {
        Write-Warning "Chocolatey not found. Please install ngrok manually:"
        Write-Warning "1. Download from: https://ngrok.com/download"
        Write-Warning "2. Extract to a folder in your PATH"
        Write-Warning "3. Or install Chocolatey and run: choco install ngrok"
        exit 1
    }
} else {
    Write-Status "ngrok is already installed"
}

# Check if authtoken is configured
$ngrokConfigPath = "$env:USERPROFILE\.ngrok2\ngrok.yml"
if (-not (Test-Path $ngrokConfigPath) -and -not $env:NGROK_AUTHTOKEN) {
    Write-Warning "ngrok authtoken not configured!"
    Write-Warning "Please run: ngrok config add-authtoken YOUR_TOKEN"
    Write-Warning "Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken"
    
    # Check if ngrok.yml exists in current directory
    if (Test-Path "ngrok.yml") {
        Write-Warning "Found ngrok.yml in current directory. Make sure to add your authtoken!"
    }
}

# Function to start Flask app
function Start-FlaskApp {
    Write-Status "Starting Flask application..."
    
    # Check if virtual environment exists
    if (Test-Path "venv\Scripts\Activate.ps1") {
        Write-Status "Activating virtual environment..."
        & "venv\Scripts\Activate.ps1"
    } elseif (Test-Path ".venv\Scripts\Activate.ps1") {
        Write-Status "Activating virtual environment..."
        & ".venv\Scripts\Activate.ps1"
    }
    
    # Install dependencies if requirements.txt exists
    if (Test-Path "requirements.txt") {
        Write-Status "Installing dependencies..."
        pip install -r requirements.txt
    }
    
    # Set environment variables
    $env:FLASK_ENV = "development"
    $env:FLASK_APP = "app.py"
    
    # Start Flask app
    $gunicornPath = Get-Command gunicorn -ErrorAction SilentlyContinue
    if ($gunicornPath) {
        Write-Status "Starting with gunicorn..."
        $flaskProcess = Start-Process -FilePath "gunicorn" -ArgumentList "--bind", "0.0.0.0:5000", "--workers", "1", "--timeout", "120", "app:app" -PassThru -NoNewWindow
    } else {
        Write-Status "Starting with Flask development server..."
        $flaskProcess = Start-Process -FilePath "python" -ArgumentList "app.py" -PassThru -NoNewWindow
    }
    
    $flaskProcess.Id | Out-File -FilePath "flask.pid" -Encoding ASCII
    Write-Status "Flask app started with PID: $($flaskProcess.Id)"
    
    # Wait for Flask to start
    Start-Sleep -Seconds 3
    
    # Test if Flask is running
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 5
        Write-Status "Flask app is running and healthy"
    } catch {
        Write-Warning "Flask app health check failed, but continuing..."
    }
    
    return $flaskProcess
}

# Function to start ngrok tunnel
function Start-NgrokTunnel {
    Write-Status "Starting ngrok tunnel..."
    
    # Use custom config if exists
    if (Test-Path "ngrok.yml") {
        Write-Status "Using custom ngrok.yml configuration"
        $ngrokProcess = Start-Process -FilePath "ngrok" -ArgumentList "start", "--config=ngrok.yml", "transaction-api" -PassThru -NoNewWindow
    } else {
        Write-Status "Using default configuration"
        $ngrokProcess = Start-Process -FilePath "ngrok" -ArgumentList "http", "5000", "--log=stdout" -PassThru -NoNewWindow
    }
    
    $ngrokProcess.Id | Out-File -FilePath "ngrok.pid" -Encoding ASCII
    Write-Status "ngrok started with PID: $($ngrokProcess.Id)"
    
    # Wait for ngrok to start
    Start-Sleep -Seconds 3
    
    # Get tunnel URL
    Write-Status "Getting tunnel information..."
    try {
        $tunnelsResponse = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 10
        $httpsUrl = $tunnelsResponse.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1 -ExpandProperty public_url
        
        if ($httpsUrl) {
            Write-Host ""
            Write-Status "🎉 ngrok tunnel is active!"
            Write-Status "Public URL: $httpsUrl"
            Write-Status "Local URL: http://localhost:5000"
            Write-Status "ngrok Web Interface: http://localhost:4040"
            Write-Host ""
            Write-Status "Test your API:"
            Write-Status "curl $httpsUrl/health"
            Write-Status "curl $httpsUrl/api/trades"
            Write-Host ""
        } else {
            Write-Warning "Could not retrieve HTTPS tunnel URL. Check ngrok logs."
        }
    } catch {
        Write-Warning "Could not retrieve tunnel URL. Check ngrok logs."
    }
    
    return $ngrokProcess
}

# Function to cleanup processes
function Stop-Services {
    Write-Status "Cleaning up..."
    
    if (Test-Path "ngrok.pid") {
        $ngrokPid = Get-Content "ngrok.pid"
        try {
            Stop-Process -Id $ngrokPid -Force -ErrorAction SilentlyContinue
            Remove-Item "ngrok.pid" -Force
            Write-Status "Stopped ngrok (PID: $ngrokPid)"
        } catch {
            Write-Warning "Could not stop ngrok process"
        }
    }
    
    if (Test-Path "flask.pid") {
        $flaskPid = Get-Content "flask.pid"
        try {
            Stop-Process -Id $flaskPid -Force -ErrorAction SilentlyContinue
            Remove-Item "flask.pid" -Force
            Write-Status "Stopped Flask app (PID: $flaskPid)"
        } catch {
            Write-Warning "Could not stop Flask process"
        }
    }
}

# Function to check service status
function Get-ServiceStatus {
    $flaskRunning = $false
    $ngrokRunning = $false
    
    if (Test-Path "flask.pid") {
        $flaskPid = Get-Content "flask.pid"
        try {
            $process = Get-Process -Id $flaskPid -ErrorAction SilentlyContinue
            if ($process) {
                $flaskRunning = $true
            }
        } catch {}
    }
    
    if (Test-Path "ngrok.pid") {
        $ngrokPid = Get-Content "ngrok.pid"
        try {
            $process = Get-Process -Id $ngrokPid -ErrorAction SilentlyContinue
            if ($process) {
                $ngrokRunning = $true
            }
        } catch {}
    }
    
    if ($flaskRunning -and $ngrokRunning) {
        Write-Status "Services are running"
        try {
            $tunnelsResponse = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 5
            $httpsUrl = $tunnelsResponse.tunnels | Where-Object { $_.proto -eq "https" } | Select-Object -First 1 -ExpandProperty public_url
            if ($httpsUrl) {
                Write-Status "Tunnel URL: $httpsUrl"
            }
        } catch {
            Write-Warning "Could not retrieve tunnel information"
        }
    } else {
        Write-Status "Services are not running"
    }
}

# Main execution
switch ($Action) {
    "start" {
        try {
            $flaskProcess = Start-FlaskApp
            $ngrokProcess = Start-NgrokTunnel
            
            Write-Status "Press Ctrl+C to stop both Flask and ngrok"
            Write-Status "Or run: .\start-ngrok.ps1 stop"
            
            # Keep script running
            while ($true) {
                Start-Sleep -Seconds 1
                if ($flaskProcess.HasExited -or $ngrokProcess.HasExited) {
                    Write-Warning "One of the services has stopped unexpectedly"
                    break
                }
            }
        } finally {
            Stop-Services
        }
    }
    "stop" {
        Stop-Services
        Write-Status "Services stopped"
    }
    "status" {
        Get-ServiceStatus
    }
}
