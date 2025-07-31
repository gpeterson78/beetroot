#!/bin/bash
# beetver.sh -- Version and dependency status checker for Beetroot
set -euo pipefail

# Path to VERSION and DEPENDENCIES files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../../VERSION"
DEPENDENCIES_FILE="$SCRIPT_DIR/../../DEPENDENCIES"

# Output flags
json=false
pretty=false

for arg in "$@"; do
  case "$arg" in
    --json) json=true ;;
    --pretty) pretty=true ;;
  esac
done

VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo 'unknown')"
COMMIT_HASH="$(git -C "$SCRIPT_DIR/../.." rev-parse HEAD 2>/dev/null || echo 'unknown')"
OS_NAME="$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"')"

readarray -t DEPENDENCIES < <(grep -v '^#' "$DEPENDENCIES_FILE" 2>/dev/null || echo "")

check_dep() {
  command -v "$1" &>/dev/null && echo "present" || echo "missing"
}

generate_json() {
  echo -n '{'
  echo -n "\\"success\\": true, \\"version\\": \\"$VERSION\\", \\"commit\\": \\"$COMMIT_HASH\\", \\"os\\": \\"$OS_NAME\\", \\"dependencies\\": {"
  local first=true
  for dep in "${DEPENDENCIES[@]}"; do
    [[ -z "$dep" ]] && continue
    status="$(check_dep "$dep")"
    $first || echo -n ", "
    echo -n "\\"$dep\\": \\"$status\\""
    first=false
  done
  echo '}}'
}

if $json; then
  if $pretty; then
    generate_json | python3 -m json.tool
  else
    generate_json
  fi
else
  echo "Version: $VERSION"
  echo "Commit: $COMMIT_HASH"
  echo "OS: $OS_NAME"
  echo "Dependencies:"
  for dep in "${DEPENDENCIES[@]}"; do
    [[ -z "$dep" ]] && continue
    echo "  $dep: $(check_dep "$dep")"
  done
fi
