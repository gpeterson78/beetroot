#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CONFIG_FILE="./snand.config"

case "$1" in
  --sync)
    "$SCRIPT_DIR/config/scripts/sync.sh"
    ;;
  --update)
    "$SCRIPT_DIR/config/scripts/compose.sh" --update
    ;;
  --help|-h)
    echo "beetroot CLI 🥬"
    echo "Usage: ./beetroot.sh [--sync | --update | PROJECT_NAME --start]"
    ;;
  *)
    echo "Unknown command. Use --help."
    exit 1
    ;;
esac
