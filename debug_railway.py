#!/usr/bin/env python3
"""
Debug script for Railway deployment
Checks environment variables and configuration
"""

import os
import sys

def debug_railway_deployment():
    print("=== Railway Deployment Debug Information ===")
    print()
    
    # Check Python version
    print(f"Python version: {sys.version}")
    print()
    
    # Check environment variables
    print("Environment Variables:")
    env_vars = [
        'PORT', 'FLASK_ENV', 'FLASK_APP', 'PYTHONPATH',
        'RAILWAY_ENVIRONMENT', 'RAILWAY_PROJECT_ID'
    ]
    
    for var in env_vars:
        value = os.environ.get(var, 'NOT SET')
        print(f"  {var}: {value}")
    print()
    
    # Check PORT specifically
    port = os.environ.get('PORT')
    print(f"PORT variable analysis:")
    print(f"  Raw value: '{port}'")
    print(f"  Type: {type(port)}")
    
    if port:
        try:
            port_int = int(port)
            print(f"  Converted to int: {port_int}")
            print(f"  Valid port: {'Yes' if 1 <= port_int <= 65535 else 'No'}")
        except ValueError as e:
            print(f"  Conversion error: {e}")
    else:
        print("  PORT is not set!")
    print()
    
    # Check if required files exist
    print("Required files check:")
    files_to_check = [
        'app.py', 'requirements.txt', 'Procfile',
        'railway.json', 'railway_start.py'
    ]
    
    for file in files_to_check:
        exists = os.path.exists(file)
        print(f"  {file}: {'EXISTS' if exists else 'MISSING'}")
    print()
    
    # Test basic imports
    print("Import tests:")
    try:
        import flask
        print(f"  Flask: OK (version {flask.__version__})")
    except ImportError as e:
        print(f"  Flask: FAILED ({e})")
    
    try:
        import gunicorn
        print(f"  Gunicorn: OK")
    except ImportError as e:
        print(f"  Gunicorn: FAILED ({e})")
    
    try:
        import app
        print(f"  App module: OK")
    except ImportError as e:
        print(f"  App module: FAILED ({e})")
    print()
    
    # Test Flask app creation
    print("Flask app test:")
    try:
        from app import app as flask_app
        print(f"  App creation: OK")
        print(f"  App name: {flask_app.name}")
        
        # Test routes
        with flask_app.test_client() as client:
            response = client.get('/health')
            print(f"  Health endpoint: {response.status_code}")
            
    except Exception as e:
        print(f"  App test: FAILED ({e})")
    
    print()
    print("=== End Debug Information ===")

if __name__ == '__main__':
    debug_railway_deployment()
