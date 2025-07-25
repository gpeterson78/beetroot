from flask import Blueprint, request, jsonify
import subprocess

scripts_bp = Blueprint('scripts', __name__)

@scripts_bp.route('/run', methods=['POST'])
def run_script():
    data = request.json or {}
    script = data.get("script")
    if not script:
        return jsonify({"error": "No script specified"}), 400

    try:
        result = subprocess.run(
            [f"./config/scripts/{script}.sh"],
            capture_output=True, text=True, check=True
        )
        return jsonify({"status": "success", "output": result.stdout})
    except subprocess.CalledProcessError as e:
        return jsonify({"status": "error", "message": e.stderr}), 500
