from .system import system_bp
from .env import env_bp
from .orch import orch_bp
from .version import version_bp
from .config import config_bp

def register_blueprints(app):
    app.register_blueprint(system_bp, url_prefix="/api/system")
    app.register_blueprint(env_bp, url_prefix="/api/env")
    app.register_blueprint(orch_bp, url_prefix="/api/orch")
    app.register_blueprint(version_bp, url_prefix="/api/version")
    app.register_blueprint(config_bp, url_prefix="/api/config")
