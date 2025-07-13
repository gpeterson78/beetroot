#!/bin/bash
set -e

CONFIG_FILE="./snand.config"  # Move to `config/beetroot.env` eventually
. "$CONFIG_FILE"

TIMESTAMP=$(date +%Y%m%d%H%M%S)
TEMP_BACKUP_DIR="$BACKUP_PATH/temp_backup_$TIMESTAMP"
FINAL_BACKUP_FILE="$BACKUP_PATH/snand_config_$TIMESTAMP.tar.gz"
GIT_TEMP_REPO_DIR="/tmp/beetroot-repo"

mkdir -p "$BACKUP_PATH" "$TEMP_BACKUP_DIR"

log() { echo "🪵 $1"; }

# Clone or pull repo
if [ -d "$GIT_TEMP_REPO_DIR/.git" ]; then
  log "Pulling from Git repo..."
  git -C "$GIT_TEMP_REPO_DIR" pull origin main || exit 1
else
  log "Cloning Git repo..."
  git clone "$GIT_REPO_URL" "$GIT_TEMP_REPO_DIR" || exit 1
fi

# Copy updated files with backup
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

# Make copied scripts executable
find ./config/scripts -type f -exec chmod +x {} \;

# Archive backups
if [ "$(ls -A "$TEMP_BACKUP_DIR")" ]; then
  tar -czf "$FINAL_BACKUP_FILE" -C "$TEMP_BACKUP_DIR" .
  log "Backup archived: $FINAL_BACKUP_FILE"
fi

rm -rf "$TEMP_BACKUP_DIR"
log "✅ Sync complete."
