#!/usr/bin/env python3
"""
Simple Flask application for Serverless GitOps PaaS
Provides a health endpoint and basic API functionality
"""

import os
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, request

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Configuration
APP_PORT = int(os.getenv('APP_PORT', 5000))
ENVIRONMENT = os.getenv('ENVIRONMENT', 'development')
APP_VERSION = os.getenv('APP_VERSION', '1.0.0')

@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint for load balancer and monitoring
    """
    health_status = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'environment': ENVIRONMENT,
        'version': APP_VERSION,
        'service': 'gitops-paas-sample-app'
    }
    
    logger.info(f"Health check requested - Status: {health_status['status']}")
    return jsonify(health_status), 200

@app.route('/', methods=['GET'])
def root():
    """
    Root endpoint with application information
    """
    app_info = {
        'name': 'Serverless GitOps PaaS Sample App',
        'version': APP_VERSION,
        'environment': ENVIRONMENT,
        'description': 'A simple Flask application demonstrating GitOps deployment',
        'endpoints': {
            'health': '/health',
            'info': '/info',
            'status': '/status'
        },
        'timestamp': datetime.utcnow().isoformat()
    }
    
    logger.info("Root endpoint accessed")
    return jsonify(app_info), 200

@app.route('/info', methods=['GET'])
def info():
    """
    Detailed application information
    """
    info_data = {
        'application': {
            'name': 'GitOps PaaS Sample App',
            'version': APP_VERSION,
            'environment': ENVIRONMENT,
            'framework': 'Flask',
            'python_version': os.getenv('PYTHON_VERSION', 'Unknown')
        },
        'deployment': {
            'deployed_at': os.getenv('DEPLOYED_AT', 'Unknown'),
            'commit_sha': os.getenv('GITHUB_SHA', 'Unknown'),
            'build_number': os.getenv('GITHUB_RUN_NUMBER', 'Unknown')
        },
        'system': {
            'hostname': os.getenv('HOSTNAME', 'Unknown'),
            'port': APP_PORT,
            'timestamp': datetime.utcnow().isoformat()
        }
    }
    
    logger.info("Info endpoint accessed")
    return jsonify(info_data), 200

@app.route('/status', methods=['GET'])
def status():
    """
    Application status and metrics
    """
    status_data = {
        'status': 'running',
        'uptime': 'active',
        'metrics': {
            'requests_processed': 0,  # Would be implemented with proper metrics
            'memory_usage': 'normal',
            'cpu_usage': 'normal'
        },
        'last_check': datetime.utcnow().isoformat()
    }
    
    logger.info("Status endpoint accessed")
    return jsonify(status_data), 200

@app.route('/api/echo', methods=['POST'])
def echo():
    """
    Echo endpoint for testing API functionality
    """
    try:
        data = request.get_json()
        if not data:
            data = {'message': 'No data provided'}
        
        response = {
            'echo': data,
            'timestamp': datetime.utcnow().isoformat(),
            'method': request.method,
            'headers': dict(request.headers)
        }
        
        logger.info(f"Echo endpoint called with data: {data}")
        return jsonify(response), 200
    
    except Exception as e:
        logger.error(f"Error in echo endpoint: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    """
    Handle 404 errors
    """
    return jsonify({
        'error': 'Not Found',
        'message': 'The requested resource was not found',
        'timestamp': datetime.utcnow().isoformat()
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """
    Handle 500 errors
    """
    return jsonify({
        'error': 'Internal Server Error',
        'message': 'An internal server error occurred',
        'timestamp': datetime.utcnow().isoformat()
    }), 500

if __name__ == '__main__':
    logger.info(f"Starting GitOps PaaS Sample App on port {APP_PORT}")
    logger.info(f"Environment: {ENVIRONMENT}")
    logger.info(f"Version: {APP_VERSION}")
    
    app.run(
        host='0.0.0.0',
        port=APP_PORT,
        debug=(ENVIRONMENT == 'development')
    ) 