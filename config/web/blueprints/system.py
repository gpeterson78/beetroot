from flask import Blueprint, jsonify
import platform
import os

system_bp = Blueprint('system', __name__)

@system_bp.route('/health')
def health():
    return jsonify({"status": "ok", "service": "beetroot-backend"})

@system_bp.route('/info')
def system_info():
    return jsonify({
        "os": platform.system(),
        "os_version": platform.release(),
        "python_version": platform.python_version(),
        "hostname": os.uname().nodename
    })
