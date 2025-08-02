#!/usr/bin/env python3
"""
Railway startup script for Transaction Management API
Handles PORT environment variable properly and starts gunicorn
"""

import os
import subprocess
import sys

def main():
    # Get port from environment variable, default to 8000
    port = os.environ.get('PORT', '8000')
    
    print(f"Starting Transaction Management API on port {port}")
    
    # Validate port
    try:
        port_int = int(port)
        if port_int < 1 or port_int > 65535:
            raise ValueError(f"Port {port} is not in valid range 1-65535")
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)
    
    # Build gunicorn command
    cmd = [
        'gunicorn',
        '--bind', f'0.0.0.0:{port}',
        'app:app',
        '--workers', '1',
        '--timeout', '120',
        '--keep-alive', '2',
        '--max-requests', '1000',
        '--access-logfile', '-',
        '--error-logfile', '-',
        '--log-level', 'info'
    ]
    
    print(f"Executing: {' '.join(cmd)}")
    
    # Start gunicorn
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error starting gunicorn: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("Shutting down...")
        sys.exit(0)

if __name__ == '__main__':
    main()
