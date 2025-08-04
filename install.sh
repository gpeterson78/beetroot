#!/bin/bash
# install.sh -- Beetroot environment installer (non-interactive)
set -e

INSTALL_PATH="$(pwd)"
SCRIPTS_PATH="$INSTALL_PATH/config/scripts"
VENV_PATH="$INSTALL_PATH/config/web/venv"
BEETUP="$SCRIPTS_PATH/beetup.sh"
BEETVER="$SCRIPTS_PATH/beetver.sh"
BEETWEB="$SCRIPTS_PATH/beetweb.sh"

# --- Check if running as root ---
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this installer as root."
    echo "Run as a normal user with write permissions to $INSTALL_PATH"
    exit 1
fi

echo "Beetroot Installer"

# --- Check write permissions ---
if [ ! -w "$INSTALL_PATH" ]; then
    echo "ERROR: No write permission to $INSTALL_PATH"
    echo "Fix with: sudo chown -R $(whoami):$(whoami) $INSTALL_PATH"
    exit 1
fi

# --- Detect if already installed ---
if [ -f "$VENV_PATH/bin/activate" ]; then
  echo "Beetroot is already installed in: $INSTALL_PATH"
  echo "To update, run: $BEETUP --update"
  echo "Or add it to your PATH: export PATH=\"\$PATH:$SCRIPTS_PATH\""
  exit 0
fi

# --- Clone repo if needed ---
if [ ! -f "$BEETUP" ]; then
  echo "Cloning Beetroot repo..."
  git clone https://github.com/gpeterson78/beetroot.git "$INSTALL_PATH"
fi

# --- Ensure scripts are executable ---
chmod +x "$SCRIPTS_PATH/"*.sh

# --- Run the full setup ---
"$BEETUP"

# --- Final messages ---
echo ""
echo "Beetroot environment setup complete."
echo "Verifying dependencies..."
echo ""

(
  set +e
  bash "$BEETVER"
)

echo ""
echo "To make Beetroot CLI tools available system-wide, add this to your shell profile:"
echo "  export PATH=\"\$PATH:$SCRIPTS_PATH\""
echo ""
echo "You can then manage Beetroot via the admin web admin at hostname:4200."
