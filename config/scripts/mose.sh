usage() {
  cat <<EOF | tee -a "$LOG_FILE"

Beetroot Docker Orchestration Utility
-------------------------------------
Usage:
  mose.sh <project|all> <action> [--json] [--pretty]

Actions:
  up         Start the project containers (detached by default)
  down       Stop and remove containers
  restart    Restart running containers
  pull       Pull updated Docker images
  upgrade    Pull and restart services (pull + up -d)
  ps         Show status of containers (docker compose ps)

Flags:
  --json     Output result in machine-readable JSON
  --pretty   Pretty-print JSON (used with --json)
  --help     Show this help message

Examples:
  mose.sh immich ps
  mose.sh traefik restart
  mose.sh all upgrade
  mose.sh all pull --json --pretty

Notes:
  - When running with 'all', actions are performed across all folders in docker/
  - 'upgrade' is useful for batch updating all projects
  - JSON output includes one object per project for bulk ops

EOF
  exit 1
}
