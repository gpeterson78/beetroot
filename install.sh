#!/bin/bash
# install.sh -- Beetroot environment installer (non-interactive)
set -e

INSTALL_PATH="$(pwd)"
SCRIPTS_PATH="$INSTALL_PATH/config/scripts"
VENV_PATH="$INSTALL_PATH/config/web/venv"
BEETUP="$SCRIPTS_PATH/beetup.sh"
BEETVER="$SCRIPTS_PATH/beetver.sh"

# --- Check if running as root ---
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this installer as root."
    echo "Run as a normal user with write permissions to $INSTALL_PATH"
    exit 1
fi

echo "Beetroot Installer"

# Detect if already installed
if [ -f "$VENV_PATH/bin/activate" ]; then
  echo "Beetroot is already installed in: $INSTALL_PATH"
  echo "To update, run: $BEETUP --update"
  echo "Or add it to your PATH: export PATH=\"\$PATH:$SCRIPTS_PATH\""
  exit 0
fi

# --- Check write permissions ---
if [ ! -w "$INSTALL_PATH" ]; then
    echo "ERROR: No write permission to $INSTALL_PATH"
    echo "Fix with: sudo chown -R $(whoami):$(whoami) $INSTALL_PATH"
    exit 1
fi

# Clone repo if not running from one
if [ ! -f "$BEETUP" ]; then
  echo "Cloning Beetroot repo..."
  git clone https://github.com/gpeterson78/beetroot.git "$INSTALL_PATH"
fi

# Ensure beetup is executable
chmod +x "$BEETUP"

# Run the full setup
exec "$BEETUP"