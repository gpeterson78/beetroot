#!/bin/bash
# beetver.sh -- Version and dependency status checker for Beetroot
set -euo pipefail

# Color codes
GREEN="\\033[0;32m"
RED="\\033[0;31m"
YELLOW="\\033[1;33m"
NC="\\033[0m" # No Color

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

# Load dependencies safely
DEPENDENCIES=()
if [[ -f "$DEPENDENCIES_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    DEPENDENCIES+=("$line")
  done < "$DEPENDENCIES_FILE"
fi

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
  echo -e "${YELLOW}Version:${NC} $VERSION"
  echo -e "${YELLOW}Commit:${NC}  $COMMIT_HASH"
  echo -e "${YELLOW}OS:${NC}      $OS_NAME"
  echo -e "${YELLOW}Dependencies:${NC}"
  for dep in "${DEPENDENCIES[@]}"; do
    status="$(check_dep "$dep")"
    if [[ "$status" == "present" ]]; then
      echo -e "  $dep: ${GREEN}present${NC}"
    else
      echo -e "  $dep: ${RED}missing${NC}"
    fi
  done
fi
