import os
import subprocess
from flask import Blueprint, request, jsonify
from flasgger import swag_from

mose_bp = Blueprint("mose", __name__)
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../scripts/mose.sh"))

def run_mose(action, project=None, pretty=False):
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


@mose_bp.route("/", methods=["GET"])
@swag_from({
    "tags": ["mose"],
    "parameters": [
        {
            "name": "action",
            "in": "query",
            "type": "string",
            "required": True,
            "description": "Action to perform (up, down, ps, pull, restart, upgrade, import)"
        },
        {
            "name": "project",
            "in": "query",
            "type": "string",
            "required": False,
            "description": "Project name (optional, applies only to one project)"
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
            "description": "Successful command execution",
            "examples": {
                "application/json": {
                    "success": True,
                    "output": "..."
                }
            }
        },
        500: {
            "description": "Script failed to execute",
            "examples": {
                "application/json": {
                    "success": False,
                    "error": "Error message",
                    "output": "Partial output"
                }
            }
        }
    }
})
def mose_route():
    action = request.args.get("action")
    project = request.args.get("project")
    pretty = request.args.get("pretty", "false").lower() == "true"

    if not action:
        return jsonify(success=False, error="Missing required parameter: action"), 400

    return run_mose(action, project=project, pretty=pretty)
