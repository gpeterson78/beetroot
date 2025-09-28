#!/usr/bin/env python3
import os
import logging
from flask import Flask, send_from_directory, jsonify, request
from flask_cors import CORS

# Paths
WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config/web'))
LOG_FILE = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../shared/logs/beetadmin.log'))

# Logging setup
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format='%(asctime)s - %(message)s')
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__, static_folder=WEB_DIR)
CORS(app)

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def serve_static(path):
    file_path = os.path.join(WEB_DIR, path)
    if path == "" or not os.path.exists(file_path):
        return send_from_directory(WEB_DIR, 'index.html')
    return send_from_directory(WEB_DIR, path)

# Example API route
@app.route('/api/status', methods=['GET'])
def get_status():
    logger.info("Status requested")
    return jsonify({
        "status": "ok",
        "message": "Beetroot admin backend is running."
    })

@app.route('/api/ping', methods=['GET'])
def ping():
    return jsonify({"message": "pong"})

if __name__ == '__main__':
    logger.info("Starting beetadmin backend on port 4200")
    app.run(host='0.0.0.0', port=4200)