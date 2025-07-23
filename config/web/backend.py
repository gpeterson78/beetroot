import os
import json
import subprocess
from flask import Flask, jsonify, send_from_directory, request
from flask_cors import CORS

app = Flask(__name__, static_folder="ui", static_url_path="/")
CORS(app)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
LOGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../shared/logs"))

# Serve index.html
@app.route('/')
def serve_index():
    return send_from_directory(app.static_folder, "index.html")

# Example: Get beetroot status
@app.route('/api/status', methods=['GET'])
def get_status():
    try:
        result = subprocess.run(["../scripts/mose.sh", "--all"], capture_output=True, text=True)
        return jsonify({
            "success": True,
            "output": result.stdout
        })
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

# Example: Return logs (simple tail for now)
@app.route('/api/logs', methods=['GET'])
def get_logs():
    try:
        log_file = os.path.join(LOGS_DIR, "mose.log")
        if not os.path.exists(log_file):
            return jsonify({"log": "Log file not found."})
        with open(log_file, 'r') as f:
            lines = f.readlines()[-100:]  # last 100 lines
        return jsonify({"log": ''.join(lines)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Config file access for future UI configuration
@app.route('/api/config', methods=['GET'])
def get_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, 'r') as f:
            return jsonify(json.load(f))
    else:
        return jsonify({})

@app.route('/api/config', methods=['POST'])
def save_config():
    data = request.json
    with open(CONFIG_PATH, 'w') as f:
        json.dump(data, f, indent=4)
    return jsonify({"message": "Configuration saved."})

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(description='Run beetroot admin web backend.')
    parser.add_argument('--port', type=int, default=80, help='Port to serve admin interface')
    args = parser.parse_args()

    app.run(host='0.0.0.0', port=args.port)