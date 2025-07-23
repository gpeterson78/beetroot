#!/bin/bash
set -e

INSTALL_PATH="$(pwd)"
SCRIPTS_PATH="$INSTALL_PATH/config/scripts"
VENV_PATH="$INSTALL_PATH/config/web/venv"
BEETSYNC="$SCRIPTS_PATH/beetsync.sh"

echo "🔧 Beetroot Installer"

# Detect if already installed
if [ -f "$VENV_PATH/bin/activate" ]; then
  echo "Beetroot is already installed in: $INSTALL_PATH"
  echo "To update, run: $BEETSYNC --update"
  echo "ℹOr add it to your PATH: export PATH=\"\$PATH:$SCRIPTS_PATH\""
  exit 0
fi

# Confirm install path
echo "This will install Beetroot into: $INSTALL_PATH"
read -rp "Press ENTER to continue or Ctrl+C to cancel..."

# Clone repo if not running from one
if [ ! -f "$BEETSYNC" ]; then
  echo "Cloning Beetroot repo..."
  git clone https://github.com/gpeterson78/beetroot.git "$INSTALL_PATH"
fi

# Ensure beetsync is executable
chmod +x "$BEETSYNC"

# Run the full setup
exec "$BEETSYNC"
