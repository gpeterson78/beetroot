#!/bin/bash
# beetgone.sh -- Cleanup script for beetroot environment
# Removes beetroot directories and optionally uninstalls dependencies

set -e

PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
SHARED_DIR="$PROJECT_ROOT/shared"
CONFIG_DIR="$PROJECT_ROOT/config"
DOCKER_DIR="$PROJECT_ROOT/docker"
DOCS_DIR="$PROJECT_ROOT/docs"

read -p "Are you sure you want to remove the entire beetroot environment? This cannot be undone. (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborting uninstallation."
    exit 0
fi

echo "Stopping all running docker services..."
find "$DOCKER_DIR" -type f -name 'docker-compose.yaml' | while read -r COMPOSE_FILE; do
    COMPOSE_DIR=$(dirname "$COMPOSE_FILE")
    echo "Bringing down: $COMPOSE_DIR"
    docker compose -f "$COMPOSE_FILE" down || true
done

echo "Removing project directories..."
rm -rf "$SHARED_DIR" "$CONFIG_DIR" "$DOCKER_DIR" "$DOCS_DIR"

echo "Removing top-level project files..."
rm -f "$PROJECT_ROOT/install.sh"
rm -f "$PROJECT_ROOT/README.md"
rm -f "$PROJECT_ROOT/LICENSE"
rm -f "$PROJECT_ROOT/.gitignore"

read -p "Do you want to remove optional dependencies? (docker, docker-compose, python3)? (y/N): " REMOVE_DEPS
if [[ "$REMOVE_DEPS" == "y" || "$REMOVE_DEPS" == "Y" ]]; then
    echo "Uninstalling optional dependencies..."
    sudo apt-get remove -y docker docker-compose python3 || true
    sudo apt-get autoremove -y
fi

echo "Beetroot environment has been removed."