"""
Unit tests for Transaction Management API
"""

import pytest
import json
import tempfile
import os
from unittest.mock import patch, mock_open
from app import app, TradeManager

@pytest.fixture
def client():
    """Create a test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def sample_trade():
    """Sample trade data for testing"""
    return {
        "symbol": "AAPL",
        "quantity": 100,
        "price": 150.25,
        "side": "BUY",
        "trader_id": "test_trader",
        "account": "TEST_ACC"
    }

class TestHealthCheck:
    """Test health check endpoint"""
    
    def test_health_check(self, client):
        """Test health check returns 200"""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert data['message'] == 'Transaction Management API is running'

class TestTradeCreation:
    """Test trade creation endpoints"""
    
    def test_create_trade_success(self, client, sample_trade):
        """Test successful trade creation"""
        with patch('app.TradeManager.save_trade') as mock_save:
            mock_save.return_value = 'test-trade-id'
            
            response = client.post('/api/trades', 
                                 data=json.dumps(sample_trade),
                                 content_type='application/json')
            
            assert response.status_code == 201
            data = json.loads(response.data)
            assert data['message'] == 'Trade created successfully'
            assert data['trade_id'] == 'test-trade-id'
    
    def test_create_trade_missing_fields(self, client):
        """Test trade creation with missing required fields"""
        incomplete_trade = {"symbol": "AAPL"}
        
        response = client.post('/api/trades',
                             data=json.dumps(incomplete_trade),
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['error'] == 'Missing required fields'
        assert 'missing_fields' in data
    
    def test_create_trade_invalid_json(self, client):
        """Test trade creation with invalid JSON"""
        response = client.post('/api/trades',
                             data='invalid json',
                             content_type='application/json')
        
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data

class TestTradeRetrieval:
    """Test trade retrieval endpoints"""
    
    def test_get_trade_success(self, client):
        """Test successful trade retrieval"""
        test_trade = {
            "trade_id": "test-id",
            "symbol": "AAPL",
            "quantity": 100,
            "price": 150.25,
            "side": "BUY"
        }
        
        with patch('app.TradeManager.get_trade') as mock_get:
            mock_get.return_value = test_trade
            
            response = client.get('/api/trades/test-id')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['message'] == 'Trade found'
            assert data['trade_data'] == test_trade
    
    def test_get_trade_not_found(self, client):
        """Test trade retrieval when trade doesn't exist"""
        with patch('app.TradeManager.get_trade') as mock_get:
            mock_get.return_value = None
            
            response = client.get('/api/trades/nonexistent-id')
            
            assert response.status_code == 404
            data = json.loads(response.data)
            assert data['error'] == 'Trade not found'
    
    def test_get_all_trades(self, client):
        """Test retrieving all trades"""
        test_trades = [
            {"trade_id": "1", "symbol": "AAPL"},
            {"trade_id": "2", "symbol": "GOOGL"}
        ]
        
        with patch('app.TradeManager.get_all_trades') as mock_get_all:
            mock_get_all.return_value = test_trades
            
            response = client.get('/api/trades')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['count'] == 2
            assert data['trades'] == test_trades

class TestTradeManager:
    """Test TradeManager class methods"""
    
    @patch('builtins.open', new_callable=mock_open)
    @patch('os.path.join')
    @patch('json.dump')
    def test_save_trade(self, mock_json_dump, mock_path_join, mock_file):
        """Test trade saving functionality"""
        mock_path_join.return_value = '/fake/path/trade.json'
        
        trade_data = {"symbol": "AAPL", "quantity": 100}
        trade_id = TradeManager.save_trade(trade_data)
        
        assert trade_id is not None
        assert 'trade_id' in trade_data
        assert 'timestamp' in trade_data
        mock_file.assert_called_once()
        mock_json_dump.assert_called_once()
    
    @patch('builtins.open', new_callable=mock_open, read_data='{"trade_id": "test"}')
    @patch('os.path.exists')
    @patch('json.load')
    def test_get_trade(self, mock_json_load, mock_exists, mock_file):
        """Test trade retrieval functionality"""
        mock_exists.return_value = True
        mock_json_load.return_value = {"trade_id": "test"}
        
        result = TradeManager.get_trade("test")
        
        assert result == {"trade_id": "test"}
        mock_file.assert_called_once()
        mock_json_load.assert_called_once()
    
    @patch('os.path.exists')
    def test_get_trade_not_exists(self, mock_exists):
        """Test trade retrieval when file doesn't exist"""
        mock_exists.return_value = False
        
        result = TradeManager.get_trade("nonexistent")
        
        assert result is None

class TestTradeUpdate:
    """Test trade update endpoints"""
    
    def test_update_trade_success(self, client, sample_trade):
        """Test successful trade update"""
        with patch('app.TradeManager.get_trade') as mock_get, \
             patch('app.TradeManager.save_trade') as mock_save:
            
            mock_get.return_value = sample_trade
            mock_save.return_value = 'test-id'
            
            update_data = {"quantity": 200, "price": 160.00}
            
            response = client.put('/api/trades/test-id',
                                data=json.dumps(update_data),
                                content_type='application/json')
            
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['message'] == 'Trade updated successfully'
    
    def test_update_nonexistent_trade(self, client):
        """Test updating a trade that doesn't exist"""
        with patch('app.TradeManager.get_trade') as mock_get:
            mock_get.return_value = None
            
            update_data = {"quantity": 200}
            
            response = client.put('/api/trades/nonexistent-id',
                                data=json.dumps(update_data),
                                content_type='application/json')
            
            assert response.status_code == 404
            data = json.loads(response.data)
            assert data['error'] == 'Trade not found'

class TestTradeDelete:
    """Test trade deletion endpoints"""
    
    @patch('os.remove')
    @patch('os.path.exists')
    def test_delete_trade_success(self, mock_exists, mock_remove, client):
        """Test successful trade deletion"""
        mock_exists.return_value = True
        
        response = client.delete('/api/trades/test-id')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['message'] == 'Trade deleted successfully'
        mock_remove.assert_called_once()
    
    @patch('os.path.exists')
    def test_delete_nonexistent_trade(self, mock_exists, client):
        """Test deleting a trade that doesn't exist"""
        mock_exists.return_value = False
        
        response = client.delete('/api/trades/nonexistent-id')
        
        assert response.status_code == 404
        data = json.loads(response.data)
        assert data['error'] == 'Trade not found'
