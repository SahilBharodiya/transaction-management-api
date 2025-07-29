from flask import Flask, request, jsonify
import json
import os
import uuid
from datetime import datetime
from pathlib import Path

app = Flask(__name__)

# Directory to store trade JSON files
TRADES_DIR = "trades"
Path(TRADES_DIR).mkdir(exist_ok=True)

class TradeManager:
    @staticmethod
    def save_trade(trade_data):
        """Save trade data to a JSON file"""
        trade_id = trade_data.get('trade_id')
        if not trade_id:
            trade_id = str(uuid.uuid4())
            trade_data['trade_id'] = trade_id
        
        # Add timestamp if not present
        if 'timestamp' not in trade_data:
            trade_data['timestamp'] = datetime.now().isoformat()
        
        file_path = os.path.join(TRADES_DIR, f"{trade_id}.json")
        with open(file_path, 'w') as f:
            json.dump(trade_data, f, indent=2)
        
        return trade_id
    
    @staticmethod
    def get_trade(trade_id):
        """Get trade data by trade ID"""
        file_path = os.path.join(TRADES_DIR, f"{trade_id}.json")
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                return json.load(f)
        return None
    
    @staticmethod
    def get_all_trades():
        """Get all trades"""
        trades = []
        if os.path.exists(TRADES_DIR):
            for filename in os.listdir(TRADES_DIR):
                if filename.endswith('.json'):
                    file_path = os.path.join(TRADES_DIR, filename)
                    with open(file_path, 'r') as f:
                        trades.append(json.load(f))
        return trades

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "message": "Transaction Management API is running",
        "timestamp": datetime.now().isoformat()
    }), 200

@app.route('/api/trades', methods=['POST'])
def create_trade():
    """Push/Create a new trade"""
    try:
        trade_data = request.get_json()
        
        if not trade_data:
            return jsonify({
                "error": "No JSON data provided",
                "message": "Request body must contain valid JSON"
            }), 400
        
        # Validate required fields (you can customize these)
        required_fields = ['symbol', 'quantity', 'price', 'side']
        missing_fields = [field for field in required_fields if field not in trade_data]
        
        if missing_fields:
            return jsonify({
                "error": "Missing required fields",
                "missing_fields": missing_fields,
                "required_fields": required_fields
            }), 400
        
        trade_id = TradeManager.save_trade(trade_data)
        
        return jsonify({
            "message": "Trade created successfully",
            "trade_id": trade_id,
            "trade_data": trade_data
        }), 201
        
    except json.JSONDecodeError:
        return jsonify({
            "error": "Invalid JSON format",
            "message": "Request body must contain valid JSON"
        }), 400
    except Exception as e:
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/api/trades/<trade_id>', methods=['GET'])
def get_trade(trade_id):
    """Get trade by trade ID"""
    try:
        trade_data = TradeManager.get_trade(trade_id)
        
        if trade_data:
            return jsonify({
                "message": "Trade found",
                "trade_data": trade_data
            }), 200
        else:
            return jsonify({
                "error": "Trade not found",
                "message": f"No trade found with ID: {trade_id}"
            }), 404
            
    except Exception as e:
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/api/trades', methods=['GET'])
def get_all_trades():
    """Fetch all trades"""
    try:
        trades = TradeManager.get_all_trades()
        
        return jsonify({
            "message": f"Retrieved {len(trades)} trades",
            "count": len(trades),
            "trades": trades
        }), 200
        
    except Exception as e:
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/api/trades/<trade_id>', methods=['PUT'])
def update_trade(trade_id):
    """Update an existing trade"""
    try:
        # Check if trade exists
        existing_trade = TradeManager.get_trade(trade_id)
        if not existing_trade:
            return jsonify({
                "error": "Trade not found",
                "message": f"No trade found with ID: {trade_id}"
            }), 404
        
        trade_data = request.get_json()
        if not trade_data:
            return jsonify({
                "error": "No JSON data provided",
                "message": "Request body must contain valid JSON"
            }), 400
        
        # Preserve the original trade_id and add update timestamp
        trade_data['trade_id'] = trade_id
        trade_data['updated_timestamp'] = datetime.now().isoformat()
        
        TradeManager.save_trade(trade_data)
        
        return jsonify({
            "message": "Trade updated successfully",
            "trade_id": trade_id,
            "trade_data": trade_data
        }), 200
        
    except json.JSONDecodeError:
        return jsonify({
            "error": "Invalid JSON format",
            "message": "Request body must contain valid JSON"
        }), 400
    except Exception as e:
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.route('/api/trades/<trade_id>', methods=['DELETE'])
def delete_trade(trade_id):
    """Delete a trade"""
    try:
        file_path = os.path.join(TRADES_DIR, f"{trade_id}.json")
        
        if os.path.exists(file_path):
            os.remove(file_path)
            return jsonify({
                "message": "Trade deleted successfully",
                "trade_id": trade_id
            }), 200
        else:
            return jsonify({
                "error": "Trade not found",
                "message": f"No trade found with ID: {trade_id}"
            }), 404
            
    except Exception as e:
        return jsonify({
            "error": "Internal server error",
            "message": str(e)
        }), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Endpoint not found",
        "message": "The requested endpoint does not exist"
    }), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({
        "error": "Method not allowed",
        "message": "The request method is not allowed for this endpoint"
    }), 405

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
