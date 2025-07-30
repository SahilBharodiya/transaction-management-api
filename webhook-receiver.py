#!/usr/bin/env python3
"""
GitHub Webhook Receiver for Transaction Management API
This script receives deployment notifications from GitHub Actions
and triggers deployments on your server.
"""

from flask import Flask, request, jsonify
import subprocess
import os
import logging
import hmac
import hashlib
import json

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
WEBHOOK_SECRET = "30bX0Quc4serAZ23WEo85nEVCSt_KhWX3k53N2m6c1FzNNmF"

# Use PowerShell script on Windows, bash script on Unix
import platform
if platform.system() == 'Windows':
    DEPLOYMENT_SCRIPT = os.environ.get('DEPLOYMENT_SCRIPT', './deploy.ps1')
else:
    DEPLOYMENT_SCRIPT = os.environ.get('DEPLOYMENT_SCRIPT', './deploy.sh')

ALLOWED_REPOS = os.environ.get('ALLOWED_REPOS', 'SahilBharodiya/transaction-management-api').split(',')

def verify_github_signature(payload_body, signature_header, secret):
    """Verify the GitHub webhook signature for security."""
    if not signature_header:
        return False
    
    hash_object = hmac.new(
        secret.encode('utf-8'),
        msg=payload_body,
        digestmod=hashlib.sha256
    )
    expected_signature = "sha256=" + hash_object.hexdigest()
    
    return hmac.compare_digest(expected_signature, signature_header)

@app.route('/webhook/github', methods=['POST'])
def github_webhook():
    """Handle GitHub webhook for deployment."""
    try:
        # Get the signature
        signature = request.headers.get('X-Hub-Signature-256', '')
        
        # Verify signature if secret is configured
        if WEBHOOK_SECRET:
            if not verify_github_signature(request.data, signature, WEBHOOK_SECRET):
                logger.warning("Invalid webhook signature")
                return jsonify({'error': 'Invalid signature'}), 401
        
        # Get the payload
        payload = request.get_json()
        
        if not payload:
            return jsonify({'error': 'No JSON payload'}), 400
        
        # Check if it's from an allowed repository
        repo_name = payload.get('repository', {}).get('full_name', '')
        if repo_name not in ALLOWED_REPOS:
            logger.warning(f"Webhook from unauthorized repo: {repo_name}")
            return jsonify({'error': 'Unauthorized repository'}), 403
        
        # Check if it's a push to main/master branch
        ref = payload.get('ref', '')
        if ref not in ['refs/heads/main', 'refs/heads/master']:
            logger.info(f"Ignoring push to branch: {ref}")
            return jsonify({'message': 'Deployment skipped - not main/master branch'}), 200
        
        # Get commit info
        commit_sha = payload.get('after', '')
        commit_message = payload.get('head_commit', {}).get('message', '')
        
        logger.info(f"Received deployment webhook from {repo_name}")
        logger.info(f"Commit: {commit_sha[:8]} - {commit_message}")
        
        # Run deployment script
        if os.path.exists(DEPLOYMENT_SCRIPT):
            logger.info(f"Running deployment script: {DEPLOYMENT_SCRIPT}")
            
            # Set environment variables for the deployment script
            env = os.environ.copy()
            env['COMMIT_SHA'] = commit_sha
            env['REPO_NAME'] = repo_name
            env['DOCKER_IMAGE'] = f"ghcr.io/{repo_name.lower()}:latest"
            
            # Determine command based on script type
            if DEPLOYMENT_SCRIPT.endswith('.ps1'):
                # PowerShell script
                cmd = ['powershell.exe', '-ExecutionPolicy', 'Bypass', '-File', DEPLOYMENT_SCRIPT]
            else:
                # Bash script
                cmd = [DEPLOYMENT_SCRIPT]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600,  # 10 minute timeout
                env=env
            )
            
            if result.returncode == 0:
                logger.info("Deployment completed successfully")
                return jsonify({
                    'status': 'success',
                    'message': 'Deployment completed successfully',
                    'commit': commit_sha[:8],
                    'output': result.stdout
                })
            else:
                logger.error(f"Deployment failed: {result.stderr}")
                return jsonify({
                    'status': 'error',
                    'message': 'Deployment failed',
                    'commit': commit_sha[:8],
                    'error': result.stderr
                }), 500
        else:
            logger.error(f"Deployment script not found: {DEPLOYMENT_SCRIPT}")
            return jsonify({
                'status': 'error',
                'message': f'Deployment script not found: {DEPLOYMENT_SCRIPT}'
            }), 500
            
    except subprocess.TimeoutExpired:
        logger.error("Deployment timeout")
        return jsonify({
            'status': 'error',
            'message': 'Deployment timeout (10 minutes)'
        }), 500
    except Exception as e:
        logger.error(f"Webhook error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/webhook/manual', methods=['POST'])
def manual_deployment():
    """Manual deployment endpoint for testing."""
    try:
        payload = request.get_json() or {}
        image = payload.get('image', f'ghcr.io/sahilbharodiya/transaction-management-api:latest')
        
        logger.info(f"Manual deployment triggered with image: {image}")
        
        if os.path.exists(DEPLOYMENT_SCRIPT):
            env = os.environ.copy()
            env['DOCKER_IMAGE'] = image
            env['COMMIT_SHA'] = 'manual'
            env['REPO_NAME'] = 'manual-deployment'
            
            # Determine command based on script type
            if DEPLOYMENT_SCRIPT.endswith('.ps1'):
                # PowerShell script
                cmd = ['powershell.exe', '-ExecutionPolicy', 'Bypass', '-File', DEPLOYMENT_SCRIPT]
            else:
                # Bash script
                cmd = [DEPLOYMENT_SCRIPT]
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600,
                env=env
            )
            
            if result.returncode == 0:
                return jsonify({
                    'status': 'success',
                    'message': 'Manual deployment completed',
                    'image': image,
                    'output': result.stdout
                })
            else:
                return jsonify({
                    'status': 'error',
                    'message': 'Manual deployment failed',
                    'error': result.stderr
                }), 500
        else:
            return jsonify({
                'status': 'error',
                'message': f'Deployment script not found: {DEPLOYMENT_SCRIPT}'
            }), 500
            
    except Exception as e:
        logger.error(f"Manual deployment error: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'webhook-receiver',
        'deployment_script': DEPLOYMENT_SCRIPT,
        'script_exists': os.path.exists(DEPLOYMENT_SCRIPT)
    })

@app.route('/status', methods=['GET'])
def deployment_status():
    """Get deployment status."""
    try:
        # Check if deployment script exists
        script_exists = os.path.exists(DEPLOYMENT_SCRIPT)
        
        # Check if Docker is running
        docker_running = False
        try:
            subprocess.run(['docker', 'info'], capture_output=True, timeout=5)
            docker_running = True
        except:
            pass
        
        # Check if the API container is running
        api_running = False
        try:
            result = subprocess.run(
                ['docker', 'ps', '--filter', 'name=transaction-api', '--format', '{{.Names}}'],
                capture_output=True,
                text=True,
                timeout=5
            )
            api_running = 'transaction-api' in result.stdout
        except:
            pass
        
        return jsonify({
            'deployment_script_exists': script_exists,
            'docker_running': docker_running,
            'api_container_running': api_running,
            'allowed_repos': ALLOWED_REPOS,
            'webhook_secret_configured': bool(WEBHOOK_SECRET)
        })
        
    except Exception as e:
        return jsonify({
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('WEBHOOK_PORT', 5001))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    logger.info(f"Starting webhook receiver on port {port}")
    logger.info(f"Deployment script: {DEPLOYMENT_SCRIPT}")
    logger.info(f"Allowed repositories: {ALLOWED_REPOS}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
