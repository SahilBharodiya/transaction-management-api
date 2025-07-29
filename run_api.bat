@echo off
echo Transaction Management API Setup and Run Script
echo ================================================

echo.
echo Checking Python installation...
python --version
if %errorlevel% neq 0 (
    echo Python is not installed or not in PATH
    echo Please install Python 3.7+ from https://python.org
    pause
    exit /b 1
)

echo.
echo Installing required packages...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo Failed to install packages
    pause
    exit /b 1
)

echo.
echo Creating trades directory...
if not exist "trades" mkdir trades

echo.
echo Starting Transaction Management API...
echo The API will be available at: http://localhost:5000
echo.
echo Available endpoints:
echo   GET  /health                    - Health check
echo   POST /api/trades                - Create new trade
echo   GET  /api/trades                - Get all trades
echo   GET  /api/trades/{trade_id}     - Get specific trade
echo   PUT  /api/trades/{trade_id}     - Update trade
echo   DELETE /api/trades/{trade_id}   - Delete trade
echo.
echo Press Ctrl+C to stop the server
echo ================================================
echo.

python app.py
