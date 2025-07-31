#!/bin/bash
set -euo pipefail

# -----------------------------------------------------------------------------
# mose.sh — Service orchestration for Beetroot (Docker wrapper)
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_DIR="$PROJECT_ROOT/docker"
LOG_DIR="$PROJECT_ROOT/shared/logs"
LOG_FILE="$LOG_DIR/mose.log"

mkdir -p "$LOG_DIR"

log() { echo "$1" | tee -a "$LOG_FILE"; }
log_raw() { tee -a "$LOG_FILE"; }

# ------------ Flags and JSON Support ------------
JSON_OUTPUT=false
PRETTY=false

for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUTPUT=true ;;
    --pretty) PRETTY=true ;;
  esac
done

emit_json() {
  local json="$1"
  if $PRETTY; then
    echo "$json" | jq .
  else
    echo "$json"
  fi
}

# ------------ Help Text ------------
usage() {
  if $JSON_OUTPUT; then
    emit_json '{"success": false, "error": "Usage: mose.sh <project|all> <action> [--json] [--pretty]"}'
  else
    cat <<EOF | tee -a "$LOG_FILE"
Usage:
  mose.sh <project|all> <action>

Actions:
  up         Start services (default: detached)
  down       Stop and remove containers
  restart    Restart running containers
  pull       Pull updated images
  upgrade    Pull + restart services
  ps         Show container status

Flags:
  --json     Output structured JSON
  --pretty   Pretty-print JSON (requires --json)

Examples:
  mose.sh immich ps
  mose.sh all upgrade
EOF
  fi
  exit 1
}

# ------------ Arg Parsing ------------
PROJECT=""
ACTION="ps"

POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --json|--pretty) ;;  # already handled
    *) POSITIONAL+=("$arg") ;;
  esac
done

if [[ ${#POSITIONAL[@]} -eq 0 ]]; then usage; fi

PROJECT="${POSITIONAL[0]}"
ACTION="${POSITIONAL[1]:-ps}"

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
      ps)       output=$(docker compose -f "$compose" ps 2>&1) ;;
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
      log "✅ $name [$ACTION]"
      echo "$output" | log_raw
    else
      log "❌ $name [$ACTION] failed: $output"
    fi
  fi
  return $status
}

# ------------ Dispatcher ------------
if [[ "$PROJECT" == "all" ]]; then
  if [[ "$ACTION" == "pull" || "$ACTION" == "upgrade" ]] && ! $JSON_OUTPUT; then
    echo
    echo "WARNING: Performing '$ACTION' on ALL services."
    read -rp "Continue? (yes/no): " CONFIRM
    [[ "$CONFIRM" == "yes" ]] || { echo "Aborted."; exit 1; }
  fi

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
else
  if ! run_project "$PROJECT"; then
    [[ $JSON_OUTPUT ]] && exit 1
  fi
fi

$JSON_OUTPUT && exit 0
log "Operation completed."
