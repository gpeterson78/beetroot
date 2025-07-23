import os
from flask import Flask, send_from_directory, jsonify, request
from blueprints.scripts import scripts_bp

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")

app = Flask(__name__, static_folder=STATIC_DIR)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

# Serve the minimal admin interface
@app.route('/')
def index():
    return send_from_directory(STATIC_DIR, "admin.html")

# Example API endpoint: health check
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "beetroot-backend"})

# Example API endpoint: version info (stub for now)
@app.route('/api/version', methods=['GET'])
def version():
    # In future, read from a version file or script
    return jsonify({"version": "0.1.0", "source": "local"})

# Example API endpoint: run a script (stub, not implemented yet)
@app.route('/api/run', methods=['POST'])
def run_script():
    data = request.json
    script_name = data.get("script")
    # TODO: Implement actual script execution logic
    return jsonify({"result": f"Requested to run script: {script_name}"}), 202

app.register_blueprint(scripts_bp, url_prefix='/api/scripts')

if __name__ == "__main__":
    port = int(os.environ.get("FLASK_PORT", 4200))  # Use env var if set, else default to 4200
    app.run(host='0.0.0.0', port=port, debug=True)
