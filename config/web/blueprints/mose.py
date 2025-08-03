import os
import subprocess
from flask import Blueprint, request, jsonify

mose_bp = Blueprint("mose", __name__)

# Path to the script
SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../scripts"))
SCRIPT_PATH = os.path.join(SCRIPT_DIR, "mose.sh")

# Helper to run mose.sh with proper flags
def run_mose_action(action, project=None, pretty=False):
    cmd = [SCRIPT_PATH, action, "--json"]
    if pretty:
        cmd.append("--pretty")
    if project:
        cmd += ["--project", project]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return jsonify(success=True, output=result.stdout.strip())
    except subprocess.CalledProcessError as e:
        return jsonify(success=False, error=e.stderr.strip(), output=e.stdout.strip()), 500

# Routes

@mose_bp.route("/mose/<action>", methods=["POST"])
def run_action(action):
    project = request.args.get("project")
    pretty = request.args.get("pretty", "false").lower() == "true"
    return run_mose_action(action, project, pretty)
