"""
Quick start script for ngrok integration
Run this to quickly set up and test ngrok with the Transaction Management API
"""

import os
import sys
import subprocess
import time
import requests
from pathlib import Path


def print_status(message):
    print(f"[INFO] {message}")


def print_warning(message):
    print(f"[WARNING] {message}")


def print_error(message):
    print(f"[ERROR] {message}")


def check_requirements():
    """Check if all requirements are met"""
    print_status("Checking requirements...")
    
    # Check Python version
    if sys.version_info < (3, 11):
        print_error("Python 3.11+ is required")
        return False
    
    # Check if ngrok auth token is set
    if not os.environ.get("NGROK_AUTHTOKEN"):
        print_warning("NGROK_AUTHTOKEN environment variable not set")
        print_warning("You can set it by running:")
        print_warning("set NGROK_AUTHTOKEN=your_token_here  # Windows")
        print_warning("export NGROK_AUTHTOKEN=your_token_here  # Linux/macOS")
        return False
    
    # Check if requirements.txt exists
    if not Path("requirements.txt").exists():
        print_error("requirements.txt not found")
        return False
    
    return True


def install_dependencies():
    """Install Python dependencies"""
    print_status("Installing Python dependencies...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"])
        return True
    except subprocess.CalledProcessError as e:
        print_error(f"Failed to install dependencies: {e}")
        return False


def start_flask_app():
    """Start the Flask application"""
    print_status("Starting Flask application...")
    
    env = os.environ.copy()
    env["FLASK_ENV"] = "development"
    env["FLASK_APP"] = "app.py"
    
    try:
        # Start Flask in background
        process = subprocess.Popen(
            [sys.executable, "app.py"],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait for Flask to start
        time.sleep(3)
        
        # Check if Flask is running
        try:
            response = requests.get("http://localhost:5000/health", timeout=5)
            if response.status_code == 200:
                print_status("Flask app is running successfully")
                return process
            else:
                print_error(f"Flask health check failed with status {response.status_code}")
                return None
        except requests.exceptions.RequestException:
            print_error("Flask app is not responding")
            return None
            
    except Exception as e:
        print_error(f"Failed to start Flask app: {e}")
        return None


def start_ngrok_tunnel():
    """Start ngrok tunnel"""
    print_status("Starting ngrok tunnel...")
    
    try:
        # Check if ngrok is installed
        subprocess.check_call(["ngrok", "version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_error("ngrok not found. Please install ngrok from https://ngrok.com/download")
        return None
    
    try:
        # Configure auth token
        authtoken = os.environ.get("NGROK_AUTHTOKEN")
        subprocess.check_call(["ngrok", "config", "add-authtoken", authtoken])
        
        # Start tunnel
        process = subprocess.Popen(
            ["ngrok", "http", "5000", "--log=stdout"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait for tunnel to start
        time.sleep(5)
        
        # Get tunnel URL
        try:
            response = requests.get("http://localhost:4040/api/tunnels", timeout=5)
            if response.status_code == 200:
                tunnels = response.json().get("tunnels", [])
                for tunnel in tunnels:
                    if tunnel.get("proto") == "https":
                        tunnel_url = tunnel["public_url"]
                        print_status(f"🎉 ngrok tunnel is active!")
                        print_status(f"Public URL: {tunnel_url}")
                        print_status(f"Local URL: http://localhost:5000")
                        print_status(f"ngrok Web Interface: http://localhost:4040")
                        print("")
                        print_status("Test your API:")
                        print_status(f"curl {tunnel_url}/health")
                        print_status(f"curl {tunnel_url}/api/trades")
                        print("")
                        return process, tunnel_url
                        
            print_warning("Could not retrieve tunnel URL")
            return process, None
            
        except requests.exceptions.RequestException:
            print_warning("Could not connect to ngrok API")
            return process, None
            
    except Exception as e:
        print_error(f"Failed to start ngrok: {e}")
        return None


def test_tunnel(tunnel_url):
    """Test the tunnel is working"""
    if not tunnel_url:
        return False
        
    print_status("Testing tunnel...")
    
    try:
        # Test health endpoint
        response = requests.get(f"{tunnel_url}/health", timeout=10)
        if response.status_code == 200:
            print_status("✅ Tunnel health check passed")
            
            # Test API endpoint
            response = requests.get(f"{tunnel_url}/api/trades", timeout=10)
            if response.status_code == 200:
                print_status("✅ Tunnel API check passed")
                return True
            else:
                print_warning("API endpoint test failed")
                return False
        else:
            print_warning("Health check failed")
            return False
            
    except requests.exceptions.RequestException as e:
        print_error(f"Tunnel test failed: {e}")
        return False


def main():
    """Main function"""
    print_status("🚀 Quick Start: Transaction Management API with ngrok")
    print("")
    
    # Check requirements
    if not check_requirements():
        print_error("Requirements check failed. Please fix the issues above.")
        return 1
    
    # Install dependencies
    if not install_dependencies():
        print_error("Failed to install dependencies")
        return 1
    
    # Start Flask app
    flask_process = start_flask_app()
    if not flask_process:
        print_error("Failed to start Flask app")
        return 1
    
    # Start ngrok tunnel
    ngrok_result = start_ngrok_tunnel()
    if not ngrok_result:
        print_error("Failed to start ngrok tunnel")
        flask_process.terminate()
        return 1
    
    ngrok_process, tunnel_url = ngrok_result
    
    # Test tunnel
    if tunnel_url and test_tunnel(tunnel_url):
        print_status("🎉 Setup completed successfully!")
        print_status("Your API is now accessible via ngrok tunnel")
        print("")
        print_status("Press Ctrl+C to stop both services")
        
        try:
            # Keep running until interrupted
            while True:
                time.sleep(1)
                # Check if processes are still running
                if flask_process.poll() is not None:
                    print_error("Flask process has stopped")
                    break
                if ngrok_process.poll() is not None:
                    print_error("ngrok process has stopped")
                    break
                    
        except KeyboardInterrupt:
            print_status("\nStopping services...")
        
        # Cleanup
        flask_process.terminate()
        ngrok_process.terminate()
        print_status("Services stopped")
        return 0
    else:
        print_error("Setup failed")
        flask_process.terminate()
        if ngrok_process:
            ngrok_process.terminate()
        return 1


if __name__ == "__main__":
    sys.exit(main())
