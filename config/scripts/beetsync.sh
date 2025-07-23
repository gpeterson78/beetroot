#!/bin/bash
# beetsync.sh -- Safely update beetroot platform from public GitHub repo

# Author: Grady Peterson
# License: MIT

set -e

CONFIG_FILE="./snand.config"  # To be renamed/configured later
. "$CONFIG_FILE"

TIMESTAMP=$(date +%Y%m%d%H%M%S)
TEMP_BACKUP_DIR="$BACKUP_PATH/temp_backup_$TIMESTAMP"
FINAL_BACKUP_FILE="$BACKUP_PATH/snand_config_$TIMESTAMP.tar.gz"
GIT_TEMP_REPO_DIR="/tmp/beetroot-repo"
VENV_DIR="./config/web/venv"
REQUIREMENTS_FILE="./config/web/requirements.txt"

mkdir -p "$BACKUP_PATH" "$TEMP_BACKUP_DIR"

log() { echo "🪵 $1"; }

# --- Git Repo Sync ---
if [ -d "$GIT_TEMP_REPO_DIR/.git" ]; then
  log "Pulling from Git repo..."
  git -C "$GIT_TEMP_REPO_DIR" pull origin main || exit 1
else
  log "Cloning Git repo..."
  git clone "$GIT_REPO_URL" "$GIT_TEMP_REPO_DIR" || exit 1
fi

# --- Directory Sync with Backup ---
sync_path() {
  SRC_DIR="$1"
  DEST_DIR="$2"
  find "$SRC_DIR" -type f | while read -r FILE_PATH; do
    REL_PATH="${FILE_PATH#$SRC_DIR/}"
    DEST_PATH="$DEST_DIR/$REL_PATH"

    if [ -f "$DEST_PATH" ]; then
      log "Backing up $DEST_PATH"
      mkdir -p "$(dirname "$TEMP_BACKUP_DIR/$REL_PATH")"
      cp "$DEST_PATH" "$TEMP_BACKUP_DIR/$REL_PATH"
    fi

    log "Updating $DEST_PATH"
    mkdir -p "$(dirname "$DEST_PATH")"
    cp "$FILE_PATH" "$DEST_PATH"
  done
}

sync_path "$GIT_TEMP_REPO_DIR/docker" "./docker"
sync_path "$GIT_TEMP_REPO_DIR/scripts" "./config/scripts"

# Make scripts executable
find ./config/scripts -type f -exec chmod +x {} \;

# --- Virtual Environment Setup ---
if [ ! -d "$VENV_DIR" ]; then
  log "Creating Python virtual environment in $VENV_DIR"
  python3 -m venv "$VENV_DIR"
fi

log "Activating virtualenv and installing/updating requirements"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$REQUIREMENTS_FILE"
deactivate

# --- Archive any backups ---
if [ "$(ls -A "$TEMP_BACKUP_DIR")" ]; then
  tar -czf "$FINAL_BACKUP_FILE" -C "$TEMP_BACKUP_DIR" .
  log "Backup archived: $FINAL_BACKUP_FILE"
fi

rm -rf "$TEMP_BACKUP_DIR"
log "Sync complete and Python environment is ready."
