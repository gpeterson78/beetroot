from .scripts import scripts_bp
from .system import system_bp
from .version import version_bp
from .health import health_bp
# from .docker import docker_bp
# from .dns import dns_bp

def register_blueprints(app):
    app.register_blueprint(scripts_bp, url_prefix="/api/scripts")
    app.register_blueprint(system_bp, url_prefix="/api/system")
    app.register_blueprint(version_bp, url_prefix="/api/version")
    app.register_blueprint(health_bp, url_prefix="/api/health")
    # app.register_blueprint(docker_bp, url_prefix="/api/docker")
    # app.register_blueprint(dns_bp, url_prefix="/api/dns")