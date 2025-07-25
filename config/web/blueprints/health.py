from flask import Blueprint, jsonify, current_app
import os

health_bp = Blueprint("health", __name__)

@health_bp.route("/", methods=["GET"])
def health_check():
    """
    Health Check
    ---
    tags:
      - System
    responses:
      200:
        description: Basic health check of the backend
        schema:
          type: object
          properties:
            status:
              type: string
              example: ok
            service:
              type: string
              example: beetroot-backend
            web_interface:
              type: string
              example: available
            index_route:
              type: string
              example: mapped
    """
    admin_ui_path = os.path.join(current_app.static_folder, "admin.html")
    web_interface = os.path.exists(admin_ui_path)

    # Optionally check if route '/' is mapped
    index_mapped = any(rule.rule == '/' for rule in current_app.url_map.iter_rules())

    return jsonify({
        "status": "ok",
        "service": "beetroot-backend",
        "web_interface": "available" if web_interface else "missing",
        "index_route": "mapped" if index_mapped else "missing"
    })
