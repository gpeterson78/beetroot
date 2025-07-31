#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# mose.sh — Service orchestration for Beetroot (Docker wrapper)
# -----------------------------------------------------------------------------
# This script wraps docker-compose commands for all or individual projects
# found under the docker/ directory. It allows starting, stopping, upgrading,
# and checking the status of services in a unified way.

# ---------------------------------------------
# Color constants for output
YELLOW="\033[1;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# ---------------------------------------------
# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
LOG_DIR="$PROJECT_ROOT/shared/logs"
LOG_FILE="$LOG_DIR/mose.log"

mkdir -p "$LOG_DIR"

# ---------------------------------------------
# Docker install + permission check
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Error: Docker is not installed or not in PATH.${NC}"
  exit 1
fi

if ! docker ps >/dev/null 2>&1; then
  echo -e "${RED}Error: Current user does not have permission to run Docker.${NC}"
  echo
  echo -e "${YELLOW}Your user ('$USER') does not have permission to access the Docker daemon.${NC}"
  echo
  echo "This is usually because your user is not in the 'docker' group."
  echo "To fix this, run the following command:"
  echo
  echo "  sudo usermod -aG docker \$USER"
  echo
  echo "After that, log out and back in, or run:"
  echo
  echo "  newgrp docker"
  echo
  echo "This should allow Docker commands to run without sudo."
  exit 1
fi

# ---------------------------------------------
# Logging helpers
log() { echo -e "$1" | tee -a "$LOG_FILE"; }
log_raw() { tee -a "$LOG_FILE"; }

# ---------------------------------------------
# JSON output helper
emit_json() {
  local json="$1"
  if $PRETTY; then echo "$json" | jq .; else echo "$json"; fi
}

# ---------------------------------------------
# Help message
usage() {
  cat <<EOF

Beetroot Docker Orchestration Utility
-------------------------------------
Usage:
  mose.sh <action> [--project NAME] [--json] [--pretty]

Actions:
  up         Start the project containers (detached by default)
  down       Stop and remove containers
  restart    Restart running containers
  pull       Pull updated Docker images
  upgrade    Pull and restart services (pull + up -d)
  ps         Show status of containers (docker compose ps)

Flags:
  --project  Run action only on the specified project
  --json     Output result in machine-readable JSON
  --pretty   Pretty-print JSON (used with --json)
  --help     Show this help message

Examples:
  mose.sh ps
  mose.sh pull
  mose.sh upgrade --project immich
  mose.sh restart --project wordpress
  mose.sh --json

EOF
  exit 0
}

# ---------------------------------------------
# Argument parsing
JSON_OUTPUT=false
PRETTY=false
PROJECT_FILTER=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=true; shift ;;
    --pretty) PRETTY=true; shift ;;
    --help) usage ;;
    --project)
      shift
      PROJECT_FILTER="$1"
      shift
      ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

ACTION=""
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
  ACTION="${POSITIONAL[0]}"
fi

SAFE_ACTIONS=("ps" "status")

# ---------------------------------------------
# No arguments? Show quote and project list
if [[ -z "$ACTION" && -z "$PROJECT_FILTER" ]]; then
  mapfile -t projects < <(find "$DOCKER_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  if $JSON_OUTPUT; then
    printf '%s\n' "${projects[@]}" | jq -R . | jq -s .
  else
    echo -e "${YELLOW}We are completely wireless at Schrute Farms! As soon as I find out where Mose hid the wires, we can get the power back on!${NC}"
    echo
    echo -e "${YELLOW}Available Beetroot Projects:${NC}"
    for p in "${projects[@]}"; do echo " - $p"; done
    echo
    echo "Run with --help for usage."
  fi
  exit 0
fi

# ---------------------------------------------
# Run action for a specific project
run_project() {
  local name="$1"
  local dir="$DOCKER_DIR/$name"
  local compose="$dir/docker-compose.yaml"
  local status=0
  local output=""

  echo -e "${YELLOW}→ Executing '$ACTION' in project: $name${NC}"

  if [[ ! -d "$dir" ]]; then
    output="Project directory not found: $dir"
    status=1
  elif [[ ! -f "$compose" ]]; then
    output="No docker-compose.yaml in $dir"
    status=1
  else
    if $JSON_OUTPUT; then
      # Capture full output for JSON mode
      case "$ACTION" in
        up)       output=$(docker compose -f "$compose" up -d 2>&1) ;;
        down)     output=$(docker compose -f "$compose" down 2>&1) ;;
        restart)  output=$(docker compose -f "$compose" restart 2>&1) ;;
        pull)     output=$(docker compose -f "$compose" pull 2>&1) ;;
        upgrade)
          output=$(docker compose -f "$compose" pull 2>&1)
          output+="\n"
          output+=$(docker compose -f "$compose" up -d 2>&1)
          ;;
        ps|status) output=$(docker compose -f "$compose" ps 2>&1) ;;
        *) output="Unknown action: $ACTION"; status=1 ;;
      esac
    else
      # Stream output directly to log and console
      case "$ACTION" in
        up)       docker compose -f "$compose" up -d | tee -a "$LOG_FILE" ;;
        down)     docker compose -f "$compose" down | tee -a "$LOG_FILE" ;;
        restart)  docker compose -f "$compose" restart | tee -a "$LOG_FILE" ;;
        pull)     docker compose -f "$compose" pull | tee -a "$LOG_FILE" ;;
        upgrade)
          docker compose -f "$compose" pull | tee -a "$LOG_FILE"
          docker compose -f "$compose" up -d | tee -a "$LOG_FILE"
          ;;
        ps|status) docker compose -f "$compose" ps | tee -a "$LOG_FILE" ;;
        *)
          echo -e "${RED}Unknown action: $ACTION${NC}"
          return 1
          ;;
      esac
    fi
  fi

  if $JSON_OUTPUT; then
    printf '{"project": "%s", "success": %s, "action": "%s", "output": %s}' \
      "$name" "$( [[ $status -eq 0 ]] && echo true || echo false )" \
      "$ACTION" "$(jq -Rs <<< "$output")"
  else
    if [[ $status -eq 0 ]]; then
      log "${GREEN}✅ $name [$ACTION] succeeded${NC}"
    else
      log "${RED}❌ $name [$ACTION] failed: $output${NC}"
    fi
  fi
  return $status
}

# ---------------------------------------------
# Run across all detected docker project dirs
run_all() {
  if $JSON_OUTPUT; then
    echo -n '{"success": true, "action": "'"$ACTION"'", "projects": ['
    first=true
    for dir in "$DOCKER_DIR"/*; do
      [[ -d "$dir" ]] || continue
      name=$(basename "$dir")
      $first || echo -n ","
      run_project "$name"
      first=false
    done
    echo "]}"
  else
    for dir in "$DOCKER_DIR"/*; do
      [[ -d "$dir" ]] || continue
      name=$(basename "$dir")
      run_project "$name"
    done
  fi
}

# ---------------------------------------------
# Helper to avoid prompts for safe read-only actions
is_safe_action() {
  for safe in "${SAFE_ACTIONS[@]}"; do
    [[ "$ACTION" == "$safe" ]] && return 0
  done
  return 1
}

# ---------------------------------------------
# Execution logic
if [[ -n "$PROJECT_FILTER" ]]; then
  if [[ ! -d "$DOCKER_DIR/$PROJECT_FILTER" ]]; then
    log "${RED}Error: Project '$PROJECT_FILTER' not found in docker/.${NC}"
    exit 1
  fi
  run_project "$PROJECT_FILTER"
else
  if ! $JSON_OUTPUT && ! is_safe_action; then
    echo
    if [[ "$ACTION" == "upgrade" ]]; then
      echo -e "${RED}WARNING: You are upgrading all services."
      echo "Some services may have breaking changes."
      echo "Please review each project’s README before proceeding.${NC}"
    else
      echo -e "${YELLOW}You are about to run '$ACTION' on ALL services.${NC}"
    fi
    echo
    read -rp "Are you sure? [y/N]: " CONFIRM
    [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || {
      echo "Aborted."
      exit 1
    }
  fi
  run_all
fi

$JSON_OUTPUT && exit 0
log "Operation completed."
