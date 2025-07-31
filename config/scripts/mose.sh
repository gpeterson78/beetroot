#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# mose.sh — Service orchestration for Beetroot (Docker wrapper)
# -----------------------------------------------------------------------------

# Color constants
YELLOW="\033[1;33m"
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
LOG_DIR="$PROJECT_ROOT/shared/logs"
LOG_FILE="$LOG_DIR/mose.log"

mkdir -p "$LOG_DIR"

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
log_raw() { tee -a "$LOG_FILE"; }

emit_json() {
  local json="$1"
  if $PRETTY; then echo "$json" | jq .; else echo "$json"; fi
}

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
  list       List available project directories

Flags:
  --project  Run action only on the specified project
  --list     Same as 'list' action (also accepts: mose.sh list)
  --json     Output result in machine-readable JSON
  --pretty   Pretty-print JSON (used with --json)
  --help     Show this help message

Examples:
  mose.sh ps
  mose.sh pull
  mose.sh upgrade --project immich
  mose.sh restart --project wordpress
  mose.sh --list --json

EOF
  exit 0
}

# ------------ Flags and JSON Support ------------
JSON_OUTPUT=false
PRETTY=false
PROJECT_FILTER=""
LIST_MODE=false
POSITIONAL=()

i=0
while [[ $i -lt $# ]]; do
  arg="${!i}"
  case "$arg" in
    --json) JSON_OUTPUT=true ;;
    --pretty) PRETTY=true ;;
    --help) usage ;;
    --list|list) LIST_MODE=true ;;
    --project)
      i=$((i + 1))
      PROJECT_FILTER="${!i}"
      ;;
    --projects)
      i=$((i + 1))
      next_arg="${!i:-}"
      if [[ "$next_arg" == "list" ]]; then LIST_MODE=true; fi
      ;;
    *) POSITIONAL+=("$arg") ;;
  esac
  i=$((i + 1))
done

ACTION="${POSITIONAL[0]:-}"
SAFE_ACTIONS=("ps" "status")

# ------------ Schrute Mode ------------
if [[ -z "$ACTION" && "$LIST_MODE" == false ]]; then
  echo -e "${YELLOW}We are completely wireless at Schrute Farms! As soon as I find out where Mose hid the wires, we can get the power back on!${NC}"
  echo
  echo "Run with --help for usage."
  exit 0
fi

# ------------ Project Listing Mode ------------
if $LIST_MODE; then
  mapfile -t projects < <(find "$DOCKER_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  if $JSON_OUTPUT; then
    printf '%s\n' "${projects[@]}" | jq -R . | jq -s .
  else
    echo -e "${YELLOW}Available Beetroot Projects:${NC}"
    for p in "${projects[@]}"; do echo " - $p"; done
  fi
  exit 0
fi

# ------------ Core Executor ------------
run_project() {
  local name="$1"
  local dir="$DOCKER_DIR/$name"
  local compose="$dir/docker-compose.yaml"
  local output=""
  local status=0

  if [[ ! -d "$dir" ]]; then
    output="Project directory not found"
    status=1
  elif [[ ! -f "$compose" ]]; then
    output="No docker-compose.yaml in $dir"
    status=1
  else
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
      *)
        output="Unknown action: $ACTION"
        status=1
        ;;
    esac
  fi

  if $JSON_OUTPUT; then
    printf '{"project": "%s", "success": %s, "action": "%s", "output": %s}' \
      "$name" "$( [[ $status -eq 0 ]] && echo true || echo false )" \
      "$ACTION" "$(jq -Rs <<< "$output")"
  else
    echo
    if [[ $status -eq 0 ]]; then
      log "${GREEN}$name [$ACTION]${NC}"
      echo "$output" | log_raw
    else
      log "${RED}$name [$ACTION] failed: $output${NC}"
    fi
  fi
  return $status
}

# ------------ Dispatcher ------------
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

is_safe_action() {
  for safe in "${SAFE_ACTIONS[@]}"; do
    [[ "$ACTION" == "$safe" ]] && return 0
  done
  return 1
}

# ------------ Execution Path ------------
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
