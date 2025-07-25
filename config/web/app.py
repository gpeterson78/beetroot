import os
from flask import Flask, send_from_directory, jsonify, request, redirect, url_for
from blueprints.scripts import scripts_bp
from blueprints.version import version_bp

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")

app = Flask(__name__, static_folder=STATIC_DIR)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

# Serve the admin interface
@app.route('/')
def index():
    return send_from_directory(STATIC_DIR, "admin.html")

# Health check endpoint
@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({"status": "ok", "service": "beetroot-backend"})

# Example endpoint to request a script run (stub)
@app.route('/api/run', methods=['POST'])
def run_script():
    data = request.json
    script_name = data.get("script")
    # In the future: validate, log, and dispatch the script execution
    return jsonify({"result": f"Requested to run script: {script_name}"}), 202

# Register API blueprints
app.register_blueprint(scripts_bp, url_prefix='/api/scripts')
app.register_blueprint(version_bp, url_prefix='/api/version')

# Launch the app
if __name__ == "__main__":
    port = int(os.environ.get("FLASK_PORT", 4200))
    app.run(host='0.0.0.0', port=port, debug=True)
