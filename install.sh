#!/bin/bash
# install.sh -- Beetroot environment installer (non-interactive)

set -e

INSTALL_PATH="$(pwd)"
SCRIPTS_PATH="$INSTALL_PATH/config/scripts"
VENV_PATH="$INSTALL_PATH/config/web/venv"
BEETVER="$SCRIPTS_PATH/beetver.sh"
BEETWEB="$SCRIPTS_PATH/beetweb.sh"

# --- Check if running as root ---
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this installer as root."
    echo "Run as a normal user with write permissions to $INSTALL_PATH"
    exit 1
fi

echo "Beetroot Installer"

# --- Detect if already installed ---
if [ -f "$VENV_PATH/bin/activate" ]; then
    echo "Beetroot is already installed in: $INSTALL_PATH"
    echo "To update, run: $SCRIPTS_PATH/beetup.sh --update"
    echo "To make Beetroot commands available globally:"
    echo "  export PATH=\"\$PATH:$SCRIPTS_PATH\""
    exit 0
fi

# --- Set up Python virtual environment ---
echo "Setting up Python environment..."
python3 -m venv "$VENV_PATH"
source "$VENV_PATH/bin/activate"
pip install -r "$INSTALL_PATH/config/web/requirements.txt"

# --- Completion message ---
echo ""
echo "Beetroot environment setup complete."
echo "Please verify all dependencies are installed:"
echo ""

bash "$BEETVER"

# --- Instructions for adding to PATH ---
echo ""
echo "To make Beetroot commands available globally, add this to your shell profile:"
echo "  export PATH=\"\$PATH:$SCRIPTS_PATH\""
echo ""

# --- Web interface instructions ---
echo "To start the Beetroot web interface, run:"
echo "  $BEETWEB start"
echo ""
echo "You can now manage Beetroot via the web admin interface."
