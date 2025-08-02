#!/bin/bash

# Railway startup script for Transaction Management API
# This script properly handles the PORT environment variable

# Get port from environment variable, default to 8000 if not set
PORT=${PORT:-8000}

echo "Starting Transaction Management API on port $PORT"

# Start gunicorn with the correct port
exec gunicorn --bind 0.0.0.0:$PORT app:app \
    --workers 1 \
    --timeout 120 \
    --keep-alive 2 \
    --max-requests 1000 \
    --access-logfile - \
    --error-logfile -
