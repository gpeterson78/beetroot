#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# mose.sh — service orchestration CLI for beetroot
#
# Optional: Add this script directory (config/scripts/) to your $PATH:
#   export PATH="/path/to/beetroot/config/scripts:$PATH"
# This allows you to run `mose.sh` from anywhere.
#
# Logs are written to: shared/logs/mose.log
# -----------------------------------------------------------------------------

# Path-safe resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
LOG_DIR="$PROJECT_ROOT/shared/logs"
LOG_FILE="$LOG_DIR/mose.log"

mkdir -p "$LOG_DIR"

# Logging functions
log() {
  echo "$1" | tee -a "$LOG_FILE"
}

log_raw() {
  tee -a "$LOG_FILE"
}

usage() {
  echo "Usage:" | tee -a "$LOG_FILE"
  echo "  mose.sh <project> [--up|--down|--pull|--update]" | tee -a "$LOG_FILE"
  echo "  mose.sh --all [--up|--down|--pull|--update]" | tee -a "$LOG_FILE"
  echo "  mose.sh <project>           # Show status" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  echo "Examples:" | tee -a "$LOG_FILE"
  echo "  mose.sh immich              # Show status of Immich" | tee -a "$LOG_FILE"
  echo "  mose.sh wordpress --up      # Start WordPress" | tee -a "$LOG_FILE"
  echo "  mose.sh chamboard --update  # Pull and restart Chamboard" | tee -a "$LOG_FILE"
  echo "  mose.sh --all --down        # Stop all services" | tee -a "$LOG_FILE"
  exit 1
}

# ------------ Parse Args ------------
PROJECT=""
ACTION="status"
ALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL=true ;;
    --up) ACTION="up" ;;
    --down) ACTION="down" ;;
    --pull) ACTION="pull" ;;
    --update) ACTION="update" ;;
    -*)
      echo "Error: Unknown option: $1" | tee -a "$LOG_FILE"
      usage
      ;;
    *)
      PROJECT="$1"
      ;;
  esac
  shift
done

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
    status)
      docker compose -f "$compose" ps | log_raw
      ;;
    up)
      docker compose -f "$compose" up -d | log_raw
      ;;
    down)
      docker compose -f "$compose" down | log_raw
      ;;
    pull)
      docker compose -f "$compose" pull | log_raw
      ;;
    update)
      docker compose -f "$compose" pull | log_raw
      docker compose -f "$compose" up -d | log_raw
      ;;
    *)
      echo "Unknown action: $ACTION" | tee -a "$LOG_FILE"
      return 1
      ;;
  esac
}

# ------------ Main Dispatch ------------
if $ALL; then
  for dir in "$DOCKER_DIR"/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    run_project "$name"
  done
elif [ -n "$PROJECT" ]; then
  run_project "$PROJECT"
else
  usage
fi

log "Operation completed."
