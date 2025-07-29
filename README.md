# Transaction Management API

A RESTful API for managing financial trades built with Python Flask. This API allows you to create, retrieve, update, and delete trade records stored as JSON files.

## Features

- **Create Trade**: Push new trade data to the system
- **Get Trade by ID**: Retrieve specific trade using trade ID
- **Get All Trades**: Fetch all stored trades
- **Update Trade**: Modify existing trade data
- **Delete Trade**: Remove trade from the system
- **Health Check**: Monitor API status

## API Endpoints

### Health Check
- **GET** `/health` - Check if the API is running

### Trade Management
- **POST** `/api/trades` - Create a new trade
- **GET** `/api/trades` - Get all trades
- **GET** `/api/trades/{trade_id}` - Get trade by ID
- **PUT** `/api/trades/{trade_id}` - Update existing trade
- **DELETE** `/api/trades/{trade_id}` - Delete trade

## Installation and Setup

1. **Clone or navigate to the project directory**
   ```bash
   cd transaction-management-api
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**
   ```bash
   python app.py
   ```

The API will be available at `http://localhost:5000`

## API Usage Examples

### 1. Health Check
```bash
curl -X GET http://localhost:5000/health
```

**Response:**
```json
{
  "status": "healthy",
  "message": "Transaction Management API is running",
  "timestamp": "2025-07-29T10:30:00.123456"
}
```

### 2. Create a New Trade (Push Trade JSON)
```bash
curl -X POST http://localhost:5000/api/trades \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "quantity": 100,
    "price": 150.25,
    "side": "BUY",
    "trader_id": "trader_001",
    "account": "ACC123"
  }'
```

**Response:**
```json
{
  "message": "Trade created successfully",
  "trade_id": "123e4567-e89b-12d3-a456-426614174000",
  "trade_data": {
    "symbol": "AAPL",
    "quantity": 100,
    "price": 150.25,
    "side": "BUY",
    "trader_id": "trader_001",
    "account": "ACC123",
    "trade_id": "123e4567-e89b-12d3-a456-426614174000",
    "timestamp": "2025-07-29T10:30:00.123456"
  }
}
```

### 3. Get Trade by ID
```bash
curl -X GET http://localhost:5000/api/trades/123e4567-e89b-12d3-a456-426614174000
```

**Response:**
```json
{
  "message": "Trade found",
  "trade_data": {
    "symbol": "AAPL",
    "quantity": 100,
    "price": 150.25,
    "side": "BUY",
    "trader_id": "trader_001",
    "account": "ACC123",
    "trade_id": "123e4567-e89b-12d3-a456-426614174000",
    "timestamp": "2025-07-29T10:30:00.123456"
  }
}
```

### 4. Get All Trades
```bash
curl -X GET http://localhost:5000/api/trades
```

**Response:**
```json
{
  "message": "Retrieved 1 trades",
  "count": 1,
  "trades": [
    {
      "symbol": "AAPL",
      "quantity": 100,
      "price": 150.25,
      "side": "BUY",
      "trader_id": "trader_001",
      "account": "ACC123",
      "trade_id": "123e4567-e89b-12d3-a456-426614174000",
      "timestamp": "2025-07-29T10:30:00.123456"
    }
  ]
}
```

### 5. Update Trade
```bash
curl -X PUT http://localhost:5000/api/trades/123e4567-e89b-12d3-a456-426614174000 \
  -H "Content-Type: application/json" \
  -d '{
    "symbol": "AAPL",
    "quantity": 150,
    "price": 152.50,
    "side": "BUY",
    "trader_id": "trader_001",
    "account": "ACC123"
  }'
```

### 6. Delete Trade
```bash
curl -X DELETE http://localhost:5000/api/trades/123e4567-e89b-12d3-a456-426614174000
```

## Data Model

### Trade Object Structure
```json
{
  "trade_id": "string (UUID)",
  "symbol": "string (required)",
  "quantity": "number (required)",
  "price": "number (required)",
  "side": "string (required) - BUY/SELL",
  "trader_id": "string (optional)",
  "account": "string (optional)",
  "timestamp": "string (ISO format)",
  "updated_timestamp": "string (ISO format, added on updates)"
}
```

### Required Fields for Creating Trades
- `symbol`: Trading symbol (e.g., "AAPL", "GOOGL")
- `quantity`: Number of shares/units
- `price`: Price per unit
- `side`: Trade direction ("BUY" or "SELL")

## Error Responses

### 400 Bad Request
```json
{
  "error": "Missing required fields",
  "missing_fields": ["symbol"],
  "required_fields": ["symbol", "quantity", "price", "side"]
}
```

### 404 Not Found
```json
{
  "error": "Trade not found",
  "message": "No trade found with ID: invalid-id"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal server error",
  "message": "Error details here"
}
```

## File Storage

Trades are stored as individual JSON files in the `trades/` directory. Each file is named with the trade ID (e.g., `123e4567-e89b-12d3-a456-426614174000.json`).

## Development

To run in development mode with debug enabled:
```bash
python app.py
```

The API will automatically reload when you make changes to the code.

## Testing

You can use tools like:
- **curl** (as shown in examples above)
- **Postman** 
- **httpie**
- **Python requests library**

Example using Python requests:
```python
import requests
import json

# Create a trade
trade_data = {
    "symbol": "TSLA",
    "quantity": 50,
    "price": 250.75,
    "side": "BUY"
}

response = requests.post('http://localhost:5000/api/trades', 
                        json=trade_data)
print(response.json())

# Get the trade
trade_id = response.json()['trade_id']
response = requests.get(f'http://localhost:5000/api/trades/{trade_id}')
print(response.json())
```
