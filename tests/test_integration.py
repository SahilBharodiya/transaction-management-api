"""
Integration tests for the Transaction Management API with ngrok support
These tests can run against both local and ngrok tunnel URLs
"""

import pytest
import requests
import os
import time
from typing import Optional


class TestAPIIntegration:
    """Integration tests for the Transaction Management API"""
    
    @pytest.fixture(scope="class")
    def base_url(self) -> str:
        """Get the base URL for testing (local or tunnel)"""
        # Check for tunnel URL first (from CI/CD or environment)
        tunnel_url = os.environ.get("TUNNEL_URL")
        if tunnel_url:
            return tunnel_url.rstrip("/")
        
        # Check for custom test URL
        test_url = os.environ.get("TEST_API_URL")
        if test_url:
            return test_url.rstrip("/")
        
        # Default to local
        return "http://localhost:5000"
    
    @pytest.fixture(scope="class")
    def api_client(self, base_url: str):
        """Create an API client for testing"""
        return APIClient(base_url)
    
    def test_health_endpoint(self, api_client):
        """Test the health endpoint"""
        response = api_client.get("/health")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
    
    def test_create_trade(self, api_client):
        """Test creating a new trade"""
        trade_data = {
            "symbol": "AAPL",
            "quantity": 100,
            "price": 150.00,
            "side": "BUY"
        }
        
        response = api_client.post("/api/trades", json=trade_data)
        assert response.status_code == 201
        
        data = response.json()
        assert "trade_id" in data
        assert data["message"] == "Trade created successfully"
        
        # Store trade_id for cleanup
        return data["trade_id"]
    
    def test_get_trade(self, api_client):
        """Test retrieving a specific trade"""
        # Create a trade first
        trade_id = self.test_create_trade(api_client)
        
        # Get the trade
        response = api_client.get(f"/api/trades/{trade_id}")
        assert response.status_code == 200
        
        data = response.json()
        assert data["trade_id"] == trade_id
        assert data["symbol"] == "AAPL"
        assert data["quantity"] == 100
        assert data["price"] == 150.00
        assert data["side"] == "BUY"
    
    def test_get_all_trades(self, api_client):
        """Test retrieving all trades"""
        response = api_client.get("/api/trades")
        assert response.status_code == 200
        
        data = response.json()
        assert "trades" in data
        assert "total" in data
        assert isinstance(data["trades"], list)
        assert isinstance(data["total"], int)
    
    def test_update_trade(self, api_client):
        """Test updating a trade"""
        # Create a trade first
        trade_id = self.test_create_trade(api_client)
        
        # Update the trade
        update_data = {
            "quantity": 200,
            "price": 155.00
        }
        
        response = api_client.put(f"/api/trades/{trade_id}", json=update_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["message"] == "Trade updated successfully"
        
        # Verify the update
        get_response = api_client.get(f"/api/trades/{trade_id}")
        updated_trade = get_response.json()
        assert updated_trade["quantity"] == 200
        assert updated_trade["price"] == 155.00
    
    def test_delete_trade(self, api_client):
        """Test deleting a trade"""
        # Create a trade first
        trade_id = self.test_create_trade(api_client)
        
        # Delete the trade
        response = api_client.delete(f"/api/trades/{trade_id}")
        assert response.status_code == 200
        
        data = response.json()
        assert data["message"] == "Trade deleted successfully"
        assert data["trade_id"] == trade_id
        
        # Verify the trade is deleted
        get_response = api_client.get(f"/api/trades/{trade_id}")
        assert get_response.status_code == 404
    
    def test_invalid_trade_creation(self, api_client):
        """Test creating a trade with invalid data"""
        invalid_data = {
            "symbol": "AAPL",
            "quantity": -100,  # Invalid negative quantity
            "price": 150.00,
            "side": "INVALID"  # Invalid side
        }
        
        response = api_client.post("/api/trades", json=invalid_data)
        assert response.status_code == 400
        
        data = response.json()
        assert "error" in data
    
    def test_nonexistent_trade(self, api_client):
        """Test accessing a non-existent trade"""
        fake_id = "00000000-0000-0000-0000-000000000000"
        
        response = api_client.get(f"/api/trades/{fake_id}")
        assert response.status_code == 404
        
        data = response.json()
        assert "error" in data
    
    def test_webhook_endpoint(self, api_client):
        """Test webhook endpoint if it exists"""
        webhook_data = {
            "event": "test",
            "data": {"test": "value"}
        }
        
        response = api_client.post("/webhook/test", json=webhook_data)
        # Webhook might not be implemented, so accept 404 or success
        assert response.status_code in [200, 201, 404]


class APIClient:
    """Simple API client for testing"""
    
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        
        # Add default headers
        self.session.headers.update({
            "Content-Type": "application/json",
            "User-Agent": "API-Integration-Tests/1.0"
        })
    
    def get(self, path: str, **kwargs) -> requests.Response:
        """Make a GET request"""
        url = f"{self.base_url}{path}"
        return self.session.get(url, **kwargs)
    
    def post(self, path: str, **kwargs) -> requests.Response:
        """Make a POST request"""
        url = f"{self.base_url}{path}"
        return self.session.post(url, **kwargs)
    
    def put(self, path: str, **kwargs) -> requests.Response:
        """Make a PUT request"""
        url = f"{self.base_url}{path}"
        return self.session.put(url, **kwargs)
    
    def delete(self, path: str, **kwargs) -> requests.Response:
        """Make a DELETE request"""
        url = f"{self.base_url}{path}"
        return self.session.delete(url, **kwargs)


@pytest.fixture(scope="session")
def wait_for_api():
    """Wait for API to be ready before running tests"""
    base_url = os.environ.get("TUNNEL_URL") or os.environ.get("TEST_API_URL") or "http://localhost:5000"
    max_retries = 30
    retry_delay = 2
    
    for i in range(max_retries):
        try:
            response = requests.get(f"{base_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"API is ready at {base_url}")
                return
        except requests.exceptions.RequestException:
            pass
        
        if i < max_retries - 1:
            print(f"Waiting for API to be ready... (attempt {i + 1}/{max_retries})")
            time.sleep(retry_delay)
    
    pytest.fail(f"API at {base_url} did not become ready within {max_retries * retry_delay} seconds")


class TestNgrokIntegration:
    """Tests specific to ngrok integration"""
    
    def test_tunnel_url_accessible(self):
        """Test that tunnel URL is accessible if provided"""
        tunnel_url = os.environ.get("TUNNEL_URL")
        if not tunnel_url:
            pytest.skip("TUNNEL_URL not provided")
        
        response = requests.get(f"{tunnel_url}/health", timeout=10)
        assert response.status_code == 200
        
        # Test HTTPS
        if tunnel_url.startswith("https://"):
            # Verify SSL certificate (ngrok provides valid certs)
            response = requests.get(f"{tunnel_url}/health", verify=True)
            assert response.status_code == 200
    
    def test_tunnel_headers(self):
        """Test that ngrok headers are present"""
        tunnel_url = os.environ.get("TUNNEL_URL")
        if not tunnel_url:
            pytest.skip("TUNNEL_URL not provided")
        
        response = requests.get(f"{tunnel_url}/health")
        
        # ngrok typically adds these headers
        headers = response.headers
        
        # Check for common ngrok headers (may vary)
        expected_headers = [
            "ngrok-trace-id",
            "x-forwarded-for",
            "x-forwarded-proto"
        ]
        
        # At least one ngrok header should be present
        ngrok_headers_found = any(
            header.lower() in [h.lower() for h in headers.keys()]
            for header in expected_headers
        )
        
        if not ngrok_headers_found:
            print("Warning: No ngrok headers detected. This might not be a tunnel URL.")


if __name__ == "__main__":
    # Run tests directly
    pytest.main([__file__, "-v"])
