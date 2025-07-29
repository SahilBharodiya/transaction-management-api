"""
Example client for Transaction Management API
This demonstrates how to use the API programmatically
"""

import requests
import json
from datetime import datetime
import uuid

class TransactionAPIClient:
    """Client for interacting with the Transaction Management API"""
    
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({'Content-Type': 'application/json'})
    
    def health_check(self):
        """Check if the API is healthy"""
        try:
            response = self.session.get(f"{self.base_url}/health")
            return response.status_code == 200, response.json()
        except Exception as e:
            return False, {"error": str(e)}
    
    def create_trade(self, symbol, quantity, price, side, **kwargs):
        """Create a new trade"""
        trade_data = {
            "symbol": symbol,
            "quantity": quantity,
            "price": price,
            "side": side.upper(),
            **kwargs
        }
        
        try:
            response = self.session.post(f"{self.base_url}/api/trades", 
                                       json=trade_data)
            return response.status_code == 201, response.json()
        except Exception as e:
            return False, {"error": str(e)}
    
    def get_trade(self, trade_id):
        """Get a trade by ID"""
        try:
            response = self.session.get(f"{self.base_url}/api/trades/{trade_id}")
            return response.status_code == 200, response.json()
        except Exception as e:
            return False, {"error": str(e)}
    
    def get_all_trades(self):
        """Get all trades"""
        try:
            response = self.session.get(f"{self.base_url}/api/trades")
            return response.status_code == 200, response.json()
        except Exception as e:
            return False, {"error": str(e)}
    
    def update_trade(self, trade_id, **updates):
        """Update an existing trade"""
        try:
            response = self.session.put(f"{self.base_url}/api/trades/{trade_id}", 
                                      json=updates)
            return response.status_code == 200, response.json()
        except Exception as e:
            return False, {"error": str(e)}
    
    def delete_trade(self, trade_id):
        """Delete a trade"""
        try:
            response = self.session.delete(f"{self.base_url}/api/trades/{trade_id}")
            return response.status_code == 200, response.json()
        except Exception as e:
            return False, {"error": str(e)}

def example_usage():
    """Demonstrate API usage"""
    # Initialize client
    client = TransactionAPIClient()
    
    print("Transaction Management API Client Example")
    print("=" * 50)
    
    # Check API health
    success, result = client.health_check()
    if success:
        print("✓ API is healthy")
    else:
        print("✗ API is not responding")
        return
    
    # Create some example trades
    trades_to_create = [
        {
            "symbol": "AAPL",
            "quantity": 100,
            "price": 150.25,
            "side": "BUY",
            "trader_id": "john_doe",
            "account": "ACC001"
        },
        {
            "symbol": "GOOGL",
            "quantity": 50,
            "price": 2750.00,
            "side": "BUY",
            "trader_id": "jane_smith",
            "account": "ACC002"
        },
        {
            "symbol": "MSFT",
            "quantity": 75,
            "price": 300.50,
            "side": "SELL",
            "trader_id": "bob_johnson",
            "account": "ACC003"
        }
    ]
    
    created_trade_ids = []
    
    print("\nCreating trades...")
    for trade in trades_to_create:
        success, result = client.create_trade(**trade)
        if success:
            trade_id = result['trade_id']
            created_trade_ids.append(trade_id)
            print(f"✓ Created trade {trade['symbol']}: {trade_id[:8]}...")
        else:
            print(f"✗ Failed to create trade {trade['symbol']}: {result}")
    
    # Get individual trades
    print("\nRetrieving individual trades...")
    for trade_id in created_trade_ids:
        success, result = client.get_trade(trade_id)
        if success:
            trade_data = result['trade_data']
            print(f"✓ Retrieved {trade_data['symbol']}: {trade_data['quantity']} @ ${trade_data['price']}")
        else:
            print(f"✗ Failed to retrieve trade {trade_id[:8]}...")
    
    # Get all trades
    print("\nRetrieving all trades...")
    success, result = client.get_all_trades()
    if success:
        trades = result['trades']
        print(f"✓ Retrieved {len(trades)} total trades")
        
        # Show summary
        for trade in trades:
            print(f"  - {trade['symbol']}: {trade['side']} {trade['quantity']} @ ${trade['price']}")
    else:
        print("✗ Failed to retrieve all trades")
    
    # Update a trade
    if created_trade_ids:
        print("\nUpdating a trade...")
        trade_id = created_trade_ids[0]
        updates = {
            "quantity": 125,  # Increase quantity
            "price": 151.00,  # Update price
            "notes": "Updated via API client"
        }
        
        success, result = client.update_trade(trade_id, **updates)
        if success:
            print(f"✓ Updated trade {trade_id[:8]}...")
            
            # Verify the update
            success, result = client.get_trade(trade_id)
            if success:
                trade_data = result['trade_data']
                print(f"  New quantity: {trade_data['quantity']}")
                print(f"  New price: ${trade_data['price']}")
        else:
            print(f"✗ Failed to update trade: {result}")
    
    # Clean up - delete a trade
    if len(created_trade_ids) > 1:
        print("\nDeleting a trade...")
        trade_id = created_trade_ids[-1]  # Delete the last one
        success, result = client.delete_trade(trade_id)
        if success:
            print(f"✓ Deleted trade {trade_id[:8]}...")
        else:
            print(f"✗ Failed to delete trade: {result}")
    
    # Final count
    print("\nFinal trade count...")
    success, result = client.get_all_trades()
    if success:
        count = result['count']
        print(f"✓ {count} trades remaining in system")
    
    print("\nExample completed!")

if __name__ == "__main__":
    example_usage()
