from flask import Blueprint, jsonify
import subprocess

version_bp = Blueprint("version", __name__)

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

@version_bp.route("/hash", methods=["GET"])
def hash_check():
    hash_val = get_local_commit_hash()
    return jsonify({"hash": hash_val})
