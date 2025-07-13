#!/usr/bin/env python3

import os
import re
import yaml
import logging
from pathlib import Path

# Constants
ROOT_DIR = Path(__file__).resolve().parents[2]
DOCKER_DIR = ROOT_DIR / "docker"
LOG_FILE = ROOT_DIR / "shared/logs/beetenv.log"
CONFIG_FILE = ROOT_DIR / "config/service-config.yaml"
DOCS_URL = "https://snand.org/docs/services"

# Setup logging
LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

def log(msg):
    logging.info(msg)
    print(msg)

def load_config():
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, 'r') as f:
            return yaml.safe_load(f) or {}
    else:
        CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        return {}

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        yaml.safe_dump(config, f)

def find_projects():
    return [d.name for d in DOCKER_DIR.iterdir() if (d / "docker-compose.yaml").exists()]

def parse_compose(compose_path):
    try:
        with open(compose_path, 'r') as f:
            content = f.read()
        env_needed = 'env_file: .env' in content
        traefik_labels = bool(re.search(r'traefik\..*:', content))
        return env_needed, traefik_labels
    except Exception as e:
        log(f"Error reading {compose_path}: {e}")
        return False, False

def ensure_project_config(config, project):
    if project not in config:
        print(f"\nNew project detected: '{project}'")
        routed = input("  Should this be routed via Traefik? (y/n): ").lower().strip() == 'y'
        entry = {
            "routed": routed,
            "internal_port": int(input("  Internal container port (e.g. 80): ") if routed else 80),
            "hostname": input("  Hostname (e.g. project.local): ") if routed else f"{project}.local",
            "entrypoint": input("  Traefik entrypoint [web/websecure]: ") if routed else "web"
        }
        config[project] = entry
        save_config(config)
        log(f"Added {project} to service-config.yaml")

def inspect_project(project, config):
    compose_path = DOCKER_DIR / project / "docker-compose.yaml"
    env_path = DOCKER_DIR / project / ".env"
    env_needed, has_traefik = parse_compose(compose_path)

    log(f"Inspecting '{project}'")
    print(f"\n[{project}]")

    if env_needed and not env_path.exists():
        print("  Missing .env file")
        log(f"{project}: Missing .env file")
    elif env_needed:
        print("  .env file found")

    ensure_project_config(config, project)

    if config.get(project, {}).get("routed", False):
        if not has_traefik:
            print("  Traefik labels not found in compose")
            print(f"    See: {DOCS_URL}#{project}")
            log(f"{project}: Missing Traefik labels")
        else:
            print("  Traefik labels found")

    print("  Inspection complete")

def main():
    print("Scanning docker services...\n")
    config = load_config()
    for project in find_projects():
        inspect_project(project, config)
    print("\nEnvironment check complete.")

if __name__ == "__main__":
    main()