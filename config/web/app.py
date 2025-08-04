import os
from flask import Flask, send_from_directory, jsonify, request, redirect, url_for
from blueprints.scripts import scripts_bp
from blueprints.version import version_bp
from blueprints.health import health_bp
from blueprints.mose import mose_bp
from flasgger import Swagger

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STATIC_DIR = os.path.join(BASE_DIR, "static")

app = Flask(__name__, static_folder=STATIC_DIR)
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = True

swagger = Swagger(app)

# Serve the admin interface
@app.route('/')
def index():
    return send_from_directory(STATIC_DIR, "admin.html")

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
app.register_blueprint(health_bp, url_prefix='/api/health')
app.register_blueprint(mose_bp, url_prefix='/api/mose')

# Launch the app
if __name__ == "__main__":
    port = int(os.environ.get("FLASK_PORT", 4200))
    app.run(host='0.0.0.0', port=port, debug=True)
