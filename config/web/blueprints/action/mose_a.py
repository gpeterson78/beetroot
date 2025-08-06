# config/web/blueprints/action/mose_a.py

import os
import subprocess
from flask import Blueprint, request, jsonify
from flasgger import swag_from

mose_action_bp = Blueprint("mose_action", __name__)
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../config/scripts/mose.sh"))

def run_mose_action(action, project=None, pretty=False):
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


@mose_action_bp.route("/<action>", methods=["POST"])
@swag_from({
    "tags": ["mose"],
    "parameters": [
        {
            "name": "action",
            "in": "path",
            "type": "string",
            "required": True,
            "description": "Action to perform (up, down, pull, restart, upgrade, import)"
        }
    ],
    "requestBody": {
        "required": False,
        "content": {
            "application/json": {
                "schema": {
                    "type": "object",
                    "properties": {
                        "project": {"type": "string"},
                        "pretty": {"type": "boolean"}
                    }
                }
            }
        }
    },
    "responses": {
        200: {"description": "Successful execution"},
        500: {"description": "Error from script"}
    }
})
def post_mose_action(action):
    allowed_actions = ["up", "down", "pull", "restart", "upgrade", "import"]
    if action not in allowed_actions:
        return jsonify(success=False, error=f"Invalid action: {action}"), 400

    data = request.get_json(silent=True) or {}
    project = data.get("project")
    pretty = data.get("pretty", False)
    return run_mose_action(action, project=project, pretty=pretty)
