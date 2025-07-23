from flask import Blueprint, request, jsonify
import subprocess
import os

scripts_bp = Blueprint('scripts', __name__)

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts'))

@scripts_bp.route('/run', methods=['POST'])
def run_script():
    script_name = request.json.get('script')
    script_path = os.path.join(SCRIPT_DIR, script_name)
    if not os.path.isfile(script_path):
        return jsonify({'error': 'Script not found'}), 404
    try:
        result = subprocess.run([script_path], capture_output=True, text=True, check=True)
        return jsonify({'output': result.stdout, 'error': result.stderr})
    except subprocess.CalledProcessError as e:
        return jsonify({'output': e.stdout, 'error': e.stderr, 'code': e.returncode}), 500