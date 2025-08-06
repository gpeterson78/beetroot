# config/web/blueprints/info/mose_i.py

import os
import subprocess
from flask import Blueprint, request, jsonify
from flasgger import swag_from

mose_info_bp = Blueprint("mose_info", __name__)
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../config/scripts/mose.sh"))

def run_mose_info(action="ps", project=None, pretty=False):
    cmd = [SCRIPT_PATH, action, "--json"]
    if pretty:
        cmd.append("--pretty")
    if project:
        cmd.extend(["--project", project])

    try:
        result = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return jsonify(success=True, output=result.stdout.strip())
    except subprocess.CalledProcessError as e:
        return jsonify(success=False, error=e.stderr.strip(), output=e.stdout.strip()), 500


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
            "description": "Status output for services"
        }
    }
})
def get_mose_status():
    project = request.args.get("project")
    pretty = request.args.get("pretty", "false").lower() == "true"
    return run_mose_info("ps", project=project, pretty=pretty)