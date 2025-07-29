"""
Configuration settings for the Transaction Management API
"""

import os

class Config:
    # API Configuration
    DEBUG = True
    HOST = '0.0.0.0'
    PORT = 5000
    
    # Storage Configuration
    TRADES_DIR = 'trades'
    
    # Validation Configuration
    REQUIRED_FIELDS = ['symbol', 'quantity', 'price', 'side']
    VALID_SIDES = ['BUY', 'SELL']
    
    # API Response Configuration
    MAX_TRADES_PER_REQUEST = 1000
    
    # Logging Configuration
    LOG_LEVEL = 'INFO'
    LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False
    HOST = '127.0.0.1'  # More restrictive in production

# Choose configuration based on environment
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

def get_config():
    """Get configuration based on environment variable"""
    env = os.environ.get('FLASK_ENV', 'default')
    return config.get(env, config['default'])
