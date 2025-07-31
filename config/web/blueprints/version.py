import os
import subprocess
from flask import Blueprint, jsonify, Response
from flasgger import swag_from

version_bp = Blueprint("version", __name__)

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
SCRIPT = os.path.join(BASE_DIR, "config/scripts/beetver.sh")

def run_beetver(args=None):
    try:
        cmd = [SCRIPT]
        if args:
            cmd.extend(args)
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        return None

@version_bp.route("/", methods=["GET"])
@swag_from({
    'responses': {
        200: {
            'description': "Full version info (all fields)",
            'examples': {
                'application/json': {
                    "success": True,
                    "version": "0.2.1",
                    "commit": "abc123",
                    "os": "Debian GNU/Linux 12 (bookworm)",
                    "dependencies": {
                        "docker": "present",
                        "python3": "present",
                        "git": "missing"
                    }
                }
            }
        }
    }
})
def version_full():
    """Get full version info (JSON)"""
    output = run_beetver(["--all", "--json"])
    if output:
        return Response(output, mimetype="application/json")
    return jsonify({"success": False, "error": "Failed to retrieve version info"}), 500

@version_bp.route("/version", methods=["GET"])
@swag_from({
    'responses': {
        200: {
            'description': "Beetroot version string",
            'examples': {'text/plain': "0.2.1"}
        }
    }
})
def version_only():
    """Get just the version string"""
    output = run_beetver(["--version"])
    if output:
        return Response(output + "\n", mimetype="text/plain")
    return Response("unknown\n", mimetype="text/plain"), 500

@version_bp.route("/hash", methods=["GET"])
@swag_from({
    'responses': {
        200: {
            'description': "Git commit hash",
            'examples': {'text/plain': "abc123"}
        }
    }
})
def hash_only():
    """Get current Git commit hash"""
    output = run_beetver(["--hash"])
    if output:
        return Response(output + "\n", mimetype="text/plain")
    return Response("unknown\n", mimetype="text/plain"), 500

@version_bp.route("/os", methods=["GET"])
@swag_from({
    'responses': {
        200: {
            'description': "Operating system string",
            'examples': {'text/plain': "Debian GNU/Linux 12 (bookworm)"}
        }
    }
})
def os_info():
    """Get OS info"""
    output = run_beetver(["--os"])
    if output:
        return Response(output + "\n", mimetype="text/plain")
    return Response("unknown\n", mimetype="text/plain"), 500

@version_bp.route("/dependencies", methods=["GET"])
@swag_from({
    'responses': {
        200: {
            'description': "Dependency status",
            'examples': {
                'application/json': {
                    "dependencies": {
                        "docker": "present",
                        "python3": "present",
                        "git": "missing"
                    }
                }
            }
        }
    }
})
def dependencies_info():
    """Get dependency check results"""
    output = run_beetver(["--dependencies", "--json"])
    if output:
        return Response(output, mimetype="application/json")
    return jsonify({"success": False, "error": "Dependency check failed"}), 500
