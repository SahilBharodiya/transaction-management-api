"""
Production-ready Flask application with Gunicorn WSGI server
"""

import os
from app import app

if __name__ == "__main__":
    # Use Gunicorn in production, Flask dev server otherwise
    if os.environ.get('FLASK_ENV') == 'production':
        # This will be handled by Gunicorn
        pass
    else:
        app.run(debug=True, host='0.0.0.0', port=5000)
