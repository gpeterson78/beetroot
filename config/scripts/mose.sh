#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# mose.sh — service orchestration CLI for beetroot
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
LOG_DIR="$PROJECT_ROOT/shared/logs"
LOG_FILE="$LOG_DIR/mose.log"

mkdir -p "$LOG_DIR"

log() { echo "$1" | tee -a "$LOG_FILE"; }
log_raw() { tee -a "$LOG_FILE"; }

usage() {
  cat <<EOF | tee -a "$LOG_FILE"
Usage:
  mose.sh <project|all> <action>
Actions:
  start        docker compose up -d
  stop         docker compose down
  restart      docker compose restart
  pull         docker compose pull
  upgrade      docker compose pull && up -d
  status       docker compose ps

Examples:
  mose.sh immich status
  mose.sh wordpress start
  mose.sh all stop
  mose.sh all upgrade     # Will show warning prompt
EOF
  exit 1
}

# ------------ Parse Args ------------
PROJECT=""
ACTION="status"

if [[ $# -eq 0 ]]; then
  usage
fi

# Normalize args
if [[ "$1" == "all" ]]; then
  PROJECT="all"
else
  PROJECT="$1"
fi

if [[ -n "$2" ]]; then
  ACTION="$2"
fi

# ------------ Core Function ------------
run_project() {
  local name="$1"
  local dir="$DOCKER_DIR/$name"
  local compose="$dir/docker-compose.yaml"

  if [ ! -d "$dir" ]; then
    log "Error: Project directory not found: $dir"
    return 1
  fi
  if [ ! -f "$compose" ]; then
    log "Warning: No docker-compose.yaml found in $dir"
    return 1
  fi

  echo | tee -a "$LOG_FILE"
  log "Running action '$ACTION' for project: $name"

  case "$ACTION" in
    status)  docker compose -f "$compose" ps | log_raw ;;
    start)   docker compose -f "$compose" up -d | log_raw ;;
    stop)    docker compose -f "$compose" down | log_raw ;;
    restart) docker compose -f "$compose" restart | log_raw ;;
    pull)    docker compose -f "$compose" pull | log_raw ;;
    upgrade)
      docker compose -f "$compose" pull | log_raw
      docker compose -f "$compose" up -d | log_raw
      ;;
    *)
      log "Unknown action: $ACTION"
      usage
      ;;
  esac
}

# ------------ Main Dispatcher ------------
if [[ "$PROJECT" == "all" ]]; then
  if [[ "$ACTION" == "pull" || "$ACTION" == "upgrade" ]]; then
    echo
    echo "WARNING: You're performing '$ACTION' on ALL services."
    echo "Some services (e.g., Immich) may have breaking changes."
    read -p "Do you want to continue? (yes/no): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
      echo "Aborted."
      exit 1
    fi
  fi
  for dir in "$DOCKER_DIR"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    run_project "$name"
  done
else
  run_project "$PROJECT"
fi

log "Operation completed."
