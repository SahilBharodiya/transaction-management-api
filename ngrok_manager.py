"""
Ngrok integration module for Transaction Management API
Provides programmatic control over ngrok tunnels
"""

import json
import os
import time
import logging
from typing import Optional, Dict, Any
import requests
from pyngrok import ngrok, conf


class NgrokManager:
    """Manages ngrok tunnels for the Transaction Management API"""
    
    def __init__(self, authtoken: Optional[str] = None, region: str = "us"):
        """
        Initialize NgrokManager
        
        Args:
            authtoken: ngrok authentication token
            region: ngrok region (us, eu, ap, au, sa, jp, in)
        """
        self.authtoken = authtoken or os.environ.get("NGROK_AUTHTOKEN")
        self.region = region
        self.tunnel = None
        self.tunnel_url = None
        
        # Configure logging
        self.logger = logging.getLogger(__name__)
        
        # Set up ngrok configuration
        if self.authtoken:
            conf.get_default().auth_token = self.authtoken
            conf.get_default().region = region
    
    def start_tunnel(self, 
                    port: int = 5000, 
                    subdomain: Optional[str] = None,
                    hostname: Optional[str] = None,
                    auth: Optional[str] = None,
                    bind_tls: bool = True) -> str:
        """
        Start ngrok tunnel
        
        Args:
            port: Local port to tunnel
            subdomain: Custom subdomain (requires paid plan)
            hostname: Custom hostname (requires paid plan)
            auth: Basic auth in format "username:password"
            bind_tls: Whether to bind TLS
            
        Returns:
            Public tunnel URL
        """
        try:
            # Stop existing tunnel if any
            self.stop_tunnel()
            
            # Configure tunnel options
            tunnel_options = {
                "bind_tls": bind_tls,
                "inspect": True
            }
            
            if subdomain:
                tunnel_options["subdomain"] = subdomain
            
            if hostname:
                tunnel_options["hostname"] = hostname
                
            if auth:
                tunnel_options["auth"] = auth
            
            # Start tunnel
            self.logger.info(f"Starting ngrok tunnel on port {port}")
            self.tunnel = ngrok.connect(port, **tunnel_options)
            self.tunnel_url = self.tunnel.public_url
            
            self.logger.info(f"Tunnel started: {self.tunnel_url}")
            return self.tunnel_url
            
        except Exception as e:
            self.logger.error(f"Failed to start tunnel: {e}")
            raise
    
    def stop_tunnel(self):
        """Stop the current tunnel"""
        if self.tunnel:
            try:
                ngrok.disconnect(self.tunnel.public_url)
                self.logger.info("Tunnel stopped")
            except Exception as e:
                self.logger.warning(f"Error stopping tunnel: {e}")
            finally:
                self.tunnel = None
                self.tunnel_url = None
    
    def get_tunnel_info(self) -> Optional[Dict[str, Any]]:
        """
        Get current tunnel information
        
        Returns:
            Tunnel information dict or None if no tunnel
        """
        if not self.tunnel:
            return None
            
        return {
            "public_url": self.tunnel.public_url,
            "local_url": f"http://localhost:{self.tunnel.local_port}",
            "name": self.tunnel.name,
            "proto": self.tunnel.proto,
            "config": self.tunnel.config
        }
    
    def get_all_tunnels(self) -> list:
        """
        Get information about all active tunnels
        
        Returns:
            List of tunnel information
        """
        try:
            tunnels = ngrok.get_tunnels()
            return [
                {
                    "public_url": tunnel.public_url,
                    "local_url": f"http://localhost:{tunnel.local_port}",
                    "name": tunnel.name,
                    "proto": tunnel.proto
                }
                for tunnel in tunnels
            ]
        except Exception as e:
            self.logger.error(f"Failed to get tunnels: {e}")
            return []
    
    def test_tunnel(self, endpoint: str = "/health") -> bool:
        """
        Test if the tunnel is working by making a request to an endpoint
        
        Args:
            endpoint: Endpoint to test
            
        Returns:
            True if tunnel is working
        """
        if not self.tunnel_url:
            return False
            
        try:
            url = f"{self.tunnel_url}{endpoint}"
            response = requests.get(url, timeout=10)
            return response.status_code == 200
        except Exception as e:
            self.logger.error(f"Tunnel test failed: {e}")
            return False
    
    def wait_for_tunnel(self, max_wait: int = 30) -> bool:
        """
        Wait for tunnel to be ready
        
        Args:
            max_wait: Maximum time to wait in seconds
            
        Returns:
            True if tunnel is ready
        """
        if not self.tunnel_url:
            return False
            
        start_time = time.time()
        while time.time() - start_time < max_wait:
            if self.test_tunnel():
                return True
            time.sleep(1)
        
        return False
    
    def get_webhook_url(self, path: str = "") -> Optional[str]:
        """
        Get webhook URL for external services
        
        Args:
            path: Additional path to append
            
        Returns:
            Complete webhook URL
        """
        if not self.tunnel_url:
            return None
            
        base_url = self.tunnel_url.rstrip("/")
        path = path.lstrip("/")
        
        if path:
            return f"{base_url}/{path}"
        return base_url
    
    def __enter__(self):
        """Context manager entry"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - cleanup tunnel"""
        self.stop_tunnel()
        ngrok.kill()


# Convenience functions
def start_tunnel_for_api(port: int = 5000, 
                        authtoken: Optional[str] = None,
                        region: str = "us") -> str:
    """
    Quick start function for API tunnel
    
    Args:
        port: Local port
        authtoken: ngrok auth token
        region: ngrok region
        
    Returns:
        Public tunnel URL
    """
    manager = NgrokManager(authtoken=authtoken, region=region)
    return manager.start_tunnel(port=port)


def create_webhook_tunnel(webhook_path: str = "/webhook",
                         port: int = 5000,
                         authtoken: Optional[str] = None) -> str:
    """
    Create a tunnel specifically for webhooks
    
    Args:
        webhook_path: Webhook endpoint path
        port: Local port
        authtoken: ngrok auth token
        
    Returns:
        Complete webhook URL
    """
    manager = NgrokManager(authtoken=authtoken)
    tunnel_url = manager.start_tunnel(port=port)
    return f"{tunnel_url}{webhook_path}"


if __name__ == "__main__":
    # Example usage
    import logging
    
    logging.basicConfig(level=logging.INFO)
    
    # Initialize manager
    manager = NgrokManager()
    
    try:
        # Start tunnel
        url = manager.start_tunnel(port=5000)
        print(f"Tunnel started: {url}")
        
        # Test tunnel
        if manager.wait_for_tunnel():
            print("Tunnel is ready!")
            
            # Get tunnel info
            info = manager.get_tunnel_info()
            print(f"Tunnel info: {json.dumps(info, indent=2)}")
            
            # Get webhook URL
            webhook_url = manager.get_webhook_url("/webhook/github")
            print(f"Webhook URL: {webhook_url}")
            
        else:
            print("Tunnel test failed")
            
    except KeyboardInterrupt:
        print("\nStopping tunnel...")
    finally:
        manager.stop_tunnel()
        ngrok.kill()
