# Transaction Management API

[![CI/CD Pipeline](https://github.com/USERNAME/transaction-management-api/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/USERNAME/transaction-management-api/actions/workflows/ci-cd.yml)
[![Coverage](https://codecov.io/gh/USERNAME/transaction-management-api/branch/main/graph/badge.svg)](https://codecov.io/gh/USERNAME/transaction-management-api)

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

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/USERNAME/transaction-management-api.git
   cd transaction-management-api
   ```

2. **Create virtual environment**
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application**
   ```bash
   python app.py
   ```

The API will be available at `http://localhost:5000`

### Docker Development

1. **Build the image**
   ```bash
   docker build -t transaction-management-api .
   ```

2. **Run the container**
   ```bash
   docker run -p 5000:5000 -v $(pwd)/data:/app/data transaction-management-api
   ```

### Pull from GitHub Container Registry

```bash
docker pull ghcr.io/USERNAME/transaction-management-api:latest
docker run -p 5000:5000 ghcr.io/USERNAME/transaction-management-api:latest
```

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

## CI/CD Pipeline

This project uses **GitHub Actions** for continuous integration and deployment:

### Workflow Features
- **✅ Automated Testing**: Runs pytest with coverage reporting
- **🔒 Security Scanning**: Safety and Bandit security checks
- **📏 Code Quality**: Flake8, Black, isort, and Pylint checks
- **🐳 Docker Build**: Multi-platform container builds (amd64/arm64)
- **🚀 Auto Deploy**: Staging and production deployments
- **📊 Coverage Reports**: Automatic coverage reporting to Codecov

### Branches
- **`main`**: Production branch (requires manual approval for deployment)
- **`develop`**: Development branch (auto-deploys to staging)
- **`feature/*`**: Feature branches (run tests only)

### Container Registry
Docker images are automatically built and pushed to:
```
ghcr.io/USERNAME/transaction-management-api:latest
ghcr.io/USERNAME/transaction-management-api:main-<commit-sha>
```

### Environment Variables
Configure these in your GitHub repository settings:

**Secrets:**
- `STAGING_DEPLOY_WEBHOOK` - Staging deployment webhook
- `PRODUCTION_DEPLOY_WEBHOOK` - Production deployment webhook

**Variables:**
- `STAGING_URL` - Staging environment URL
- `PRODUCTION_URL` - Production environment URL
- `HEALTH_CHECK_URL` - Health check endpoint URL

## Migration from GitLab

If you're migrating from GitLab, see the detailed [GitHub Migration Guide](GITHUB_MIGRATION.md).

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`pytest`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Guidelines
- Follow PEP 8 style guidelines (enforced by flake8)
- Format code with Black
- Sort imports with isort
- Write tests for new features
- Maintain test coverage above 70%

## Security

- Dependencies are automatically scanned for vulnerabilities
- Code is analyzed with Bandit for security issues
- All images are built with security best practices
- Regular dependency updates via Dependabot

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
