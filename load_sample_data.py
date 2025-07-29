"""
Data loader script to populate the Transaction Management API with sample data
"""

import json
import requests
import sys
from pathlib import Path

def load_sample_data(api_url="http://localhost:5000", sample_file="sample_trades.json"):
    """Load sample trades into the API"""
    
    # Check if API is running
    try:
        response = requests.get(f"{api_url}/health")
        if response.status_code != 200:
            print(f"❌ API health check failed: {response.status_code}")
            return False
    except requests.ConnectionError:
        print("❌ Cannot connect to API. Make sure the server is running at", api_url)
        return False
    
    print(f"✅ API is healthy at {api_url}")
    
    # Load sample data
    sample_file_path = Path(sample_file)
    if not sample_file_path.exists():
        print(f"❌ Sample file not found: {sample_file}")
        return False
    
    try:
        with open(sample_file_path, 'r') as f:
            sample_trades = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON in sample file: {e}")
        return False
    
    print(f"📂 Loaded {len(sample_trades)} sample trades from {sample_file}")
    
    # Create trades via API
    created_trades = []
    failed_trades = []
    
    for i, trade in enumerate(sample_trades, 1):
        try:
            response = requests.post(f"{api_url}/api/trades", json=trade)
            if response.status_code == 201:
                result = response.json()
                trade_id = result['trade_id']
                created_trades.append(trade_id)
                print(f"✅ Trade {i}/{len(sample_trades)}: {trade['symbol']} - ID: {trade_id[:8]}...")
            else:
                failed_trades.append((i, trade['symbol'], response.json()))
                print(f"❌ Trade {i}/{len(sample_trades)}: {trade['symbol']} - Failed: {response.json().get('error', 'Unknown error')}")
        except Exception as e:
            failed_trades.append((i, trade['symbol'], str(e)))
            print(f"❌ Trade {i}/{len(sample_trades)}: {trade['symbol']} - Error: {e}")
    
    # Summary
    print("\n" + "="*50)
    print("SUMMARY")
    print("="*50)
    print(f"✅ Successfully created: {len(created_trades)} trades")
    print(f"❌ Failed to create: {len(failed_trades)} trades")
    
    if failed_trades:
        print("\nFailed trades:")
        for trade_num, symbol, error in failed_trades:
            print(f"  - Trade {trade_num} ({symbol}): {error}")
    
    if created_trades:
        print(f"\nCreated trade IDs:")
        for trade_id in created_trades:
            print(f"  - {trade_id}")
    
    # Verify by getting all trades
    try:
        response = requests.get(f"{api_url}/api/trades")
        if response.status_code == 200:
            result = response.json()
            total_trades = result['count']
            print(f"\n📊 Total trades in system: {total_trades}")
        else:
            print(f"\n❌ Failed to verify total trades: {response.json()}")
    except Exception as e:
        print(f"\n❌ Error verifying trades: {e}")
    
    return len(failed_trades) == 0

def clear_all_trades(api_url="http://localhost:5000"):
    """Clear all trades from the API (for testing purposes)"""
    print("🗑️  Clearing all trades...")
    
    try:
        # Get all trades first
        response = requests.get(f"{api_url}/api/trades")
        if response.status_code != 200:
            print("❌ Failed to get trades list")
            return False
        
        trades = response.json()['trades']
        if not trades:
            print("ℹ️  No trades to clear")
            return True
        
        # Delete each trade
        deleted_count = 0
        for trade in trades:
            trade_id = trade['trade_id']
            try:
                delete_response = requests.delete(f"{api_url}/api/trades/{trade_id}")
                if delete_response.status_code == 200:
                    deleted_count += 1
                    print(f"✅ Deleted trade: {trade['symbol']} ({trade_id[:8]}...)")
                else:
                    print(f"❌ Failed to delete trade {trade_id[:8]}...")
            except Exception as e:
                print(f"❌ Error deleting trade {trade_id[:8]}...: {e}")
        
        print(f"🗑️  Deleted {deleted_count}/{len(trades)} trades")
        return deleted_count == len(trades)
        
    except Exception as e:
        print(f"❌ Error clearing trades: {e}")
        return False

def main():
    """Main function"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Load sample data into Transaction Management API')
    parser.add_argument('--url', default='http://localhost:5000', help='API base URL')
    parser.add_argument('--file', default='sample_trades.json', help='Sample data file')
    parser.add_argument('--clear', action='store_true', help='Clear all existing trades first')
    
    args = parser.parse_args()
    
    print("Transaction Management API Data Loader")
    print("="*40)
    
    if args.clear:
        if clear_all_trades(args.url):
            print("✅ All trades cleared successfully\n")
        else:
            print("❌ Failed to clear all trades\n")
    
    success = load_sample_data(args.url, args.file)
    
    if success:
        print("\n🎉 Data loading completed successfully!")
        print(f"\nYou can now test the API:")
        print(f"  curl {args.url}/api/trades")
        print(f"  curl {args.url}/health")
    else:
        print("\n💥 Data loading failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
