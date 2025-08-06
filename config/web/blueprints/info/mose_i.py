# config/web/blueprints/info/mose_i.py

import os
import subprocess
from flask import Blueprint, request, jsonify
from flasgger import swag_from
import logging

# Set up logging
LOG_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../shared/logs"))
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "web.log")

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# Define Flask blueprint
mose_info_bp = Blueprint("mose_info", __name__)

# Absolute path to the CLI script
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../../config/scripts/mose.sh"))

def run_mose(action, project=None, pretty=False):
    """
    Executes the mose.sh script with given parameters.
    Returns JSON output for use in the Beetroot API.
    """
    cmd = [SCRIPT_PATH, action, "--json"]
    if pretty:
        cmd.append("--pretty")
    if project:
        cmd.extend(["--project", project])

    logging.debug(f"[mose_info] Executing command: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        logging.debug(f"[mose_info] Script output:\n{result.stdout.strip()}")
        return jsonify(success=True, output=result.stdout.strip())

    except subprocess.CalledProcessError as e:
        logging.error(f"[mose_info] Script error: {e.stderr.strip()}")
        return jsonify(success=False, error=e.stderr.strip(), output=e.stdout.strip()), 500

    except Exception as e:
        logging.exception("[mose_info] Unexpected error")
        return jsonify(success=False, error=str(e)), 500

@mose_info_bp.route("/ps", methods=["GET"])
@swag_from({
    "tags": ["mose"],
    "parameters": [
        {
            "name": "project",
            "in": "query",
            "type": "string",
            "required": False,
            "description": "Project name to filter (optional)"
        },
        {
            "name": "pretty",
            "in": "query",
            "type": "boolean",
            "required": False,
            "description": "Pretty-print JSON output"
        }
    ],
    "responses": {
        200: {
            "description": "Status output for services",
            "examples": {
                "application/json": {
                    "success": True,
                    "output": "..."
                }
            }
        },
        500: {
            "description": "Script execution failed"
        }
    }
})
def get_mose_status():
    """
    HTTP GET /api/info/mose/ps
    Calls mose.sh with 'ps' to show container status.
    """
    project = request.args.get("project")
    pretty = request.args.get("pretty", "false").lower() == "true"
    return run_mose("ps", project=project, pretty=pretty)
