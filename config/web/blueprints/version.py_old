from flask import Blueprint, jsonify, Response
import subprocess
import os

version_bp = Blueprint("version", __name__)

# Path to VERSION file (assumes this file is in config/web/blueprints/)
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../"))
VERSION_FILE = os.path.join(BASE_DIR, "VERSION")

def get_local_commit_hash():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        return "unknown"

def get_project_version():
    try:
        with open(VERSION_FILE, "r") as f:
            return f.read().strip()
    except Exception:
        return "unknown"

# --- API Routes ---

@version_bp.route("/", methods=["GET"])
def version_info():
    """Combined output for legacy/debug use."""
    return jsonify({
        "version": get_project_version(),
        "hash": get_local_commit_hash()
    })

@version_bp.route("/version", methods=["GET"])
def version_only():
    return Response(get_project_version(), mimetype="text/plain")

@version_bp.route("/hash", methods=["GET"])
def hash_only():
    return Response(get_local_commit_hash(), mimetype="text/plain")
