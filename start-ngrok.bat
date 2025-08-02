@echo off
REM Simple batch script to start ngrok tunnel for Transaction Management API
REM Usage: start-ngrok.bat [start|stop|status]

setlocal enabledelayedexpansion

REM Check for action parameter
set ACTION=%1
if "%ACTION%"=="" set ACTION=start

echo [INFO] Setting up ngrok for Transaction Management API...

REM Check if ngrok auth token is set
if "%NGROK_AUTHTOKEN%"=="" (
    echo [WARNING] NGROK_AUTHTOKEN environment variable not set!
    echo [WARNING] Please set it by running:
    echo [WARNING] set NGROK_AUTHTOKEN=your_ngrok_authtoken_here
    echo [WARNING] Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken
    pause
    exit /b 1
)

REM Check if ngrok is installed
ngrok version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] ngrok not found. Please install ngrok:
    echo [ERROR] 1. Download from: https://ngrok.com/download
    echo [ERROR] 2. Extract to a folder in your PATH
    echo [ERROR] 3. Or install via Chocolatey: choco install ngrok
    pause
    exit /b 1
)

if "%ACTION%"=="start" goto START
if "%ACTION%"=="stop" goto STOP
if "%ACTION%"=="status" goto STATUS

echo Usage: %0 [start^|stop^|status]
echo   start  - Start Flask app and ngrok tunnel
echo   stop   - Stop both services
echo   status - Check service status
exit /b 1

:START
echo [INFO] Starting Flask application...

REM Check if virtual environment exists
if exist "venv\Scripts\activate.bat" (
    echo [INFO] Activating virtual environment...
    call venv\Scripts\activate.bat
) else if exist ".venv\Scripts\activate.bat" (
    echo [INFO] Activating virtual environment...
    call .venv\Scripts\activate.bat
)

REM Install dependencies if requirements.txt exists
if exist "requirements.txt" (
    echo [INFO] Installing dependencies...
    pip install -r requirements.txt
)

REM Set environment variables
set FLASK_ENV=development
set FLASK_APP=app.py

REM Start Flask app in background
echo [INFO] Starting Flask with Python...
start /b python app.py

REM Wait for Flask to start
timeout /t 3 /nobreak >nul

REM Test if Flask is running
curl -f http://localhost:5000/health >nul 2>&1
if errorlevel 1 (
    echo [WARNING] Flask app health check failed, but continuing...
) else (
    echo [INFO] Flask app is running and healthy
)

REM Configure ngrok auth token
echo [INFO] Configuring ngrok auth token...
ngrok config add-authtoken %NGROK_AUTHTOKEN%

REM Start ngrok tunnel
echo [INFO] Starting ngrok tunnel...
if exist "ngrok.yml" (
    echo [INFO] Using custom ngrok.yml configuration
    start /b ngrok start --config=ngrok.yml transaction-api
) else (
    echo [INFO] Using default configuration
    start /b ngrok http 5000 --log=stdout
)

REM Wait for ngrok to start
timeout /t 5 /nobreak >nul

REM Get tunnel URL
echo [INFO] Getting tunnel information...
for /f "delims=" %%i in ('curl -s http://localhost:4040/api/tunnels ^| python -c "import sys,json;data=json.load(sys.stdin);tunnels=data.get('tunnels',[]);[print(t['public_url']) for t in tunnels if t.get('proto')=='https'][:1]"') do set TUNNEL_URL=%%i

if not "%TUNNEL_URL%"=="" (
    echo.
    echo [INFO] 🎉 ngrok tunnel is active!
    echo [INFO] Public URL: %TUNNEL_URL%
    echo [INFO] Local URL: http://localhost:5000
    echo [INFO] ngrok Web Interface: http://localhost:4040
    echo.
    echo [INFO] Test your API:
    echo [INFO] curl %TUNNEL_URL%/health
    echo [INFO] curl %TUNNEL_URL%/api/trades
    echo.
    echo [INFO] Press any key to stop both Flask and ngrok
    pause >nul
    
    REM Stop services
    taskkill /f /im ngrok.exe >nul 2>&1
    taskkill /f /im python.exe >nul 2>&1
    echo [INFO] Services stopped
) else (
    echo [WARNING] Could not retrieve tunnel URL. Check ngrok logs.
    echo [INFO] Press any key to stop services
    pause >nul
    taskkill /f /im ngrok.exe >nul 2>&1
    taskkill /f /im python.exe >nul 2>&1
)

goto END

:STOP
echo [INFO] Stopping services...
taskkill /f /im ngrok.exe >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
echo [INFO] Services stopped
goto END

:STATUS
echo [INFO] Checking service status...

REM Check Flask
curl -f http://localhost:5000/health >nul 2>&1
if errorlevel 1 (
    echo [INFO] Flask app is not running
) else (
    echo [INFO] Flask app is running
)

REM Check ngrok
curl -f http://localhost:4040/api/tunnels >nul 2>&1
if errorlevel 1 (
    echo [INFO] ngrok is not running
) else (
    echo [INFO] ngrok is running
    for /f "delims=" %%i in ('curl -s http://localhost:4040/api/tunnels ^| python -c "import sys,json;data=json.load(sys.stdin);tunnels=data.get('tunnels',[]);[print(t['public_url']) for t in tunnels if t.get('proto')=='https'][:1]"') do set TUNNEL_URL=%%i
    if not "!TUNNEL_URL!"=="" (
        echo [INFO] Tunnel URL: !TUNNEL_URL!
    )
)

:END
endlocal
