# Transaction Management API Setup and Run Script
Write-Host "Transaction Management API Setup and Run Script" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host ""
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.7+ from https://python.org" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Installing required packages..." -ForegroundColor Yellow
try {
    pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        throw "pip install failed"
    }
    Write-Host "Packages installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to install packages" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Creating trades directory..." -ForegroundColor Yellow
if (!(Test-Path "trades")) {
    New-Item -ItemType Directory -Name "trades"
    Write-Host "Created trades directory" -ForegroundColor Green
} else {
    Write-Host "Trades directory already exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Starting Transaction Management API..." -ForegroundColor Yellow
Write-Host "The API will be available at: http://localhost:5000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available endpoints:" -ForegroundColor White
Write-Host "  GET  /health                    - Health check" -ForegroundColor Gray
Write-Host "  POST /api/trades                - Create new trade" -ForegroundColor Gray
Write-Host "  GET  /api/trades                - Get all trades" -ForegroundColor Gray
Write-Host "  GET  /api/trades/{trade_id}     - Get specific trade" -ForegroundColor Gray
Write-Host "  PUT  /api/trades/{trade_id}     - Update trade" -ForegroundColor Gray
Write-Host "  DELETE /api/trades/{trade_id}   - Delete trade" -ForegroundColor Gray
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

python app.py
