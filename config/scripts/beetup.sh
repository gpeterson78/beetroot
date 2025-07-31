#!/bin/bash
# beetup.sh -- Beetroot Platform Sync & Updater
# Grady Peterson, MIT License

set -euo pipefail

# --- Configuration ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="$REPO_DIR/config/scripts"
WEB_DIR="$REPO_DIR/config/web"
VENV_DIR="$WEB_DIR/venv"
REQUIREMENTS_FILE="$WEB_DIR/requirements.txt"
HOOK_DIR="$SCRIPT_DIR/hooks/beetup"
BACKUP_DIR="$REPO_DIR/backups"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

log() { echo "[beetup] $1"; }

log "Resetting local repo to origin/main (discarding local changes)"
git -C "$REPO_DIR" fetch origin main
git -C "$REPO_DIR" reset --hard origin/main

# # --- 1. Git Pull ---
# log "Updating local repo at $REPO_DIR"
# if ! git -C "$REPO_DIR" pull origin main; then
#   log "Git pull failed"
#   exit 1
# fi

# --- 2. System Update (APT) ---
# log "Updating system packages (apt)"
# sudo apt-get update -y
# sudo apt-get upgrade -y

# --- Check for python3-venv availability ---
if ! python3 -m venv --help >/dev/null 2>&1; then
  log "Missing python3-venv package. Please install it:"
  log "  sudo apt install python3-venv"
  exit 1
fi

# --- 3. Python Virtual Environment ---
if [ ! -d "$VENV_DIR" ]; then
  log "Creating Python virtual environment at $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

log "Updating Python dependencies"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
if [ -f "$REQUIREMENTS_FILE" ]; then
  pip install -r "$REQUIREMENTS_FILE"
else
  log "WARNING: requirements.txt not found at $REQUIREMENTS_FILE"
fi
deactivate

# --- 4. Make All Scripts Executable ---
log "Ensuring all scripts in $SCRIPT_DIR are executable"
find "$SCRIPT_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# --- 5. Run Optional Update Hooks ---
log "Ensuring all update hooks are executable"
find "$HOOK_DIR" -type f -name "*.sh" -exec chmod +x {} \;

if [ -d "$HOOK_DIR" ]; then
  log "Running update hooks from $HOOK_DIR"
  for hook in "$HOOK_DIR"/*.sh; do
    [ -x "$hook" ] && log "Running hook: $(basename "$hook")" && "$hook"
  done
else
  log "No update hooks directory found at $HOOK_DIR"
fi

log "Beetroot platform sync complete."
