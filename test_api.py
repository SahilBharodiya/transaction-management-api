#!/usr/bin/env python3
"""
Test script for Transaction Management API
Run this script while the API server is running to test all endpoints
"""

import requests
import json
import time

# API base URL
BASE_URL = "http://localhost:5000"

def test_health_check():
    """Test the health check endpoint"""
    print("=" * 50)
    print("Testing Health Check")
    print("=" * 50)
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_create_trade():
    """Test creating a new trade"""
    print("\n" + "=" * 50)
    print("Testing Create Trade")
    print("=" * 50)
    
    trade_data = {
        "symbol": "AAPL",
        "quantity": 100,
        "price": 150.25,
        "side": "BUY",
        "trader_id": "trader_001",
        "account": "ACC123"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/trades", json=trade_data)
        print(f"Status Code: {response.status_code}")
        response_data = response.json()
        print(f"Response: {json.dumps(response_data, indent=2)}")
        
        if response.status_code == 201:
            return response_data.get('trade_id')
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def test_get_trade(trade_id):
    """Test getting a trade by ID"""
    print("\n" + "=" * 50)
    print(f"Testing Get Trade by ID: {trade_id}")
    print("=" * 50)
    
    try:
        response = requests.get(f"{BASE_URL}/api/trades/{trade_id}")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_get_all_trades():
    """Test getting all trades"""
    print("\n" + "=" * 50)
    print("Testing Get All Trades")
    print("=" * 50)
    
    try:
        response = requests.get(f"{BASE_URL}/api/trades")
        print(f"Status Code: {response.status_code}")
        response_data = response.json()
        print(f"Response: {json.dumps(response_data, indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_update_trade(trade_id):
    """Test updating a trade"""
    print("\n" + "=" * 50)
    print(f"Testing Update Trade: {trade_id}")
    print("=" * 50)
    
    updated_data = {
        "symbol": "AAPL",
        "quantity": 150,  # Changed quantity
        "price": 152.50,  # Changed price
        "side": "BUY",
        "trader_id": "trader_001",
        "account": "ACC123",
        "notes": "Updated trade"  # Added new field
    }
    
    try:
        response = requests.put(f"{BASE_URL}/api/trades/{trade_id}", json=updated_data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_create_multiple_trades():
    """Test creating multiple trades"""
    print("\n" + "=" * 50)
    print("Testing Create Multiple Trades")
    print("=" * 50)
    
    trades = [
        {
            "symbol": "GOOGL",
            "quantity": 50,
            "price": 2750.00,
            "side": "BUY",
            "trader_id": "trader_002"
        },
        {
            "symbol": "MSFT",
            "quantity": 75,
            "price": 300.50,
            "side": "SELL",
            "trader_id": "trader_003"
        },
        {
            "symbol": "TSLA",
            "quantity": 25,
            "price": 250.75,
            "side": "BUY",
            "trader_id": "trader_001"
        }
    ]
    
    created_ids = []
    for i, trade in enumerate(trades, 1):
        try:
            response = requests.post(f"{BASE_URL}/api/trades", json=trade)
            print(f"Trade {i} - Status Code: {response.status_code}")
            if response.status_code == 201:
                trade_id = response.json().get('trade_id')
                created_ids.append(trade_id)
                print(f"Trade {i} - Created with ID: {trade_id}")
            else:
                print(f"Trade {i} - Failed: {response.json()}")
        except Exception as e:
            print(f"Trade {i} - Error: {e}")
    
    return created_ids

def test_delete_trade(trade_id):
    """Test deleting a trade"""
    print("\n" + "=" * 50)
    print(f"Testing Delete Trade: {trade_id}")
    print("=" * 50)
    
    try:
        response = requests.delete(f"{BASE_URL}/api/trades/{trade_id}")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_error_cases():
    """Test various error cases"""
    print("\n" + "=" * 50)
    print("Testing Error Cases")
    print("=" * 50)
    
    # Test creating trade with missing required fields
    print("\n--- Testing missing required fields ---")
    invalid_trade = {"symbol": "AAPL"}  # Missing quantity, price, side
    try:
        response = requests.post(f"{BASE_URL}/api/trades", json=invalid_trade)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")
    
    # Test getting non-existent trade
    print("\n--- Testing non-existent trade ---")
    try:
        response = requests.get(f"{BASE_URL}/api/trades/non-existent-id")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")
    
    # Test invalid JSON
    print("\n--- Testing invalid JSON ---")
    try:
        response = requests.post(f"{BASE_URL}/api/trades", 
                               data="invalid json", 
                               headers={'Content-Type': 'application/json'})
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
    except Exception as e:
        print(f"Error: {e}")

def main():
    """Run all tests"""
    print("Transaction Management API Test Suite")
    print("=" * 60)
    print("Make sure the API server is running on http://localhost:5000")
    print("=" * 60)
    
    # Test health check first
    if not test_health_check():
        print("\nAPI is not responding. Make sure the server is running.")
        return
    
    # Test creating a trade
    trade_id = test_create_trade()
    if not trade_id:
        print("Failed to create trade. Stopping tests.")
        return
    
    # Test getting the trade
    test_get_trade(trade_id)
    
    # Test updating the trade
    test_update_trade(trade_id)
    
    # Test getting the updated trade
    test_get_trade(trade_id)
    
    # Create multiple trades
    additional_ids = test_create_multiple_trades()
    
    # Test getting all trades
    test_get_all_trades()
    
    # Test error cases
    test_error_cases()
    
    # Clean up - delete some trades
    if additional_ids:
        print("\n" + "=" * 50)
        print("Cleaning up - Deleting some test trades")
        print("=" * 50)
        for trade_id_to_delete in additional_ids[:2]:  # Delete first 2
            test_delete_trade(trade_id_to_delete)
    
    # Final check - get all trades
    test_get_all_trades()
    
    print("\n" + "=" * 60)
    print("Test Suite Completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
