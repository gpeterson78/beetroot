#!/bin/bash
# beetsync.sh -- Safely update beetroot platform from public GitHub repo

# Author: Grady Peterson
# License: MIT

set -e

# ---------------------------------------------
# Configuration
# ---------------------------------------------

REPO_URL="https://github.com/snand-beetroot/beetroot.git"
TEMP_DIR="/tmp/beetroot-sync"
PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
BACKUP_DIR="$PROJECT_ROOT/shared/backup/sync-$(date +%Y%m%d%H%M%S)"
POST_SYNC_SCRIPT="$PROJECT_ROOT/config/scripts/beetenv.py"

# ---------------------------------------------
# Start sync process
# ---------------------------------------------

echo "[beetsync] Starting update from $REPO_URL..."
echo "[beetsync] Backing up current environment to $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/backup.tar.gz" -C "$PROJECT_ROOT" . --exclude='shared/backup'

echo "[beetsync] Cloning latest repo into $TEMP_DIR"
rm -rf "$TEMP_DIR"
git clone --depth=1 "$REPO_URL" "$TEMP_DIR"

echo "[beetsync] Syncing core project files..."
rsync -av \
  --exclude '*.env' \
  --exclude 'shared/' \
  --exclude '.git' \
  --exclude 'docker/*/.env' \
  "$TEMP_DIR/" "$PROJECT_ROOT/"

echo "[beetsync] Cleaning up temporary clone..."
rm -rf "$TEMP_DIR"

# ---------------------------------------------
# Post-sync hook
# ---------------------------------------------

if [ -x "$POST_SYNC_SCRIPT" ]; then
    echo "[beetsync] Running beetenv to validate environment..."
    "$POST_SYNC_SCRIPT"
else
    echo "[beetsync] beetenv.py not found or not executable. Skipping environment check."
fi

echo "[beetsync] Update complete. Your beetroot platform is now synced with the latest version."