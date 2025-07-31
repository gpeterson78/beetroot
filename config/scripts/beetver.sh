#!/bin/bash
# beetver.sh -- Version and dependency status checker for Beetroot
set -euo pipefail

# Color codes
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="$SCRIPT_DIR/../../VERSION"
DEPENDENCIES_FILE="$SCRIPT_DIR/DEPENDENCIES"

VERSION="$(cat "$VERSION_FILE" 2>/dev/null || echo 'unknown')"
COMMIT_HASH="$(git -C "$SCRIPT_DIR/../.." rev-parse HEAD 2>/dev/null || echo 'unknown')"
OS_NAME="$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '"')"

# Default flags
json=false
pretty=false
mode="summary"

# Load dependencies safely
DEPENDENCIES=()
if [[ -f "$DEPENDENCIES_FILE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(echo "$line" | xargs)"
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    DEPENDENCIES+=("$line")
  done < "$DEPENDENCIES_FILE"
fi

check_dep_status() {
  command -v "$1" &>/dev/null && echo "present" || echo "missing"
}

get_dep_help() {
  local pkg="$1"
  case "$OS_NAME" in
    *Debian*|*Ubuntu*)
      echo "sudo apt install $pkg"
      ;;
    *Arch*)
      echo "sudo pacman -S $pkg"
      ;;
    *)
      echo "Install $pkg from your system package manager."
      ;;
  esac
}

print_usage() {
  echo "Usage: beetver.sh [--version|--hash|--os|--dependencies|--all] [--json] [--pretty]"
  echo
  echo "Options:"
  echo "  --version        Show Beetroot version only"
  echo "  --hash           Show current git commit hash"
  echo "  --os             Show detected operating system"
  echo "  --dependencies   Show status of required dependencies"
  echo "  --all            Show all version-related information"
  echo "  --json           Output machine-readable JSON"
  echo "  --pretty         Format JSON for readability (requires --json)"
  echo "  --help           Show this help message"
}

generate_json() {
  local deps_json=""
  for dep in "${DEPENDENCIES[@]}"; do
    [[ -z "$dep" ]] && continue
    status="$(check_dep_status "$dep")"
    deps_json+="\"$dep\": \"$status\","
  done
  deps_json="${deps_json%,}"  # Remove trailing comma

  cat <<EOF
{
  "success": true,
  "version": "$VERSION",
  "hash": "$COMMIT_HASH",
  "os": "$OS_NAME",
  "dependencies": { $deps_json }
}
EOF
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    --json) json=true ;;
    --pretty) pretty=true ;;
    --help) print_usage; exit 0 ;;
    --version) mode="version" ;;
    --hash) mode="hash" ;;
    --os) mode="os" ;;
    --dependencies) mode="dependencies" ;;
    --all) mode="all" ;;
    *) echo "Unknown option: $arg"; print_usage; exit 1 ;;
  esac
done

# If no mode switch, default to summary + help
if [[ "$#" -eq 0 ]]; then
  echo "Beetroot version: $VERSION"
  echo
  print_usage
  exit 0
fi

# Output logic
if $json; then
  case "$mode" in
    version)
      echo "{ \"version\": \"$VERSION\" }"
      ;;
    hash)
      echo "{ \"commit\": \"$COMMIT_HASH\" }"
      ;;
    os)
      echo "{ \"os\": \"$OS_NAME\" }"
      ;;
    dependencies)
      echo -n '{ "dependencies": {'
      first=true
      for dep in "${DEPENDENCIES[@]}"; do
        [[ -z "$dep" ]] && continue
        status="$(check_dep_status "$dep")"
        $first || echo -n ", "
        echo -n "\"$dep\": \"$status\""
        first=false
      done
      echo "} }"
      ;;
    all)
      if $pretty; then
        generate_json | python3 -m json.tool
      else
        generate_json
      fi
      ;;
  esac
else
  case "$mode" in
    version)
      echo "$VERSION"
      ;;
    hash)
      echo "$COMMIT_HASH"
      ;;
    os)
      echo "$OS_NAME"
      ;;
    dependencies)
      echo -e "${YELLOW}Dependencies:${NC}"
      for dep in "${DEPENDENCIES[@]}"; do
        status="$(check_dep_status "$dep")"
        if [[ "$status" == "present" ]]; then
          echo -e "  $dep: ${GREEN}present${NC}"
        else
          help=$(get_dep_help "$dep")
          echo -e "  $dep: ${RED}missing${NC} → $help"
        fi
      done
      ;;
    all)
      echo -e "${YELLOW}Beetroot Version:${NC} $VERSION"
      echo -e "${YELLOW}Commit Hash:${NC} $COMMIT_HASH"
      echo -e "${YELLOW}OS:${NC} $OS_NAME"
      echo -e "${YELLOW}Dependencies:${NC}"
      for dep in "${DEPENDENCIES[@]}"; do
        status="$(check_dep_status "$dep")"
        if [[ "$status" == "present" ]]; then
          echo -e "  $dep: ${GREEN}present${NC}"
        else
          help=$(get_dep_help "$dep")
          echo -e "  $dep: ${RED}missing${NC} → $help"
        fi
      done
      ;;
  esac
fi
