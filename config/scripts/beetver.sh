#!/bin/bash
# beetver.sh -- Beetroot version and dependency checker (non-installing)

set -e

PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
SCRIPT_DIR="$(dirname "$0")"
VERSION_FILE="$PROJECT_ROOT/VERSION"
DEPENDENCIES_FILE="$SCRIPT_DIR/DEPENDENCIES"
REPO="gpeterson78/beetroot"
GITHUB_VERSION_URL="https://raw.githubusercontent.com/$REPO/main/VERSION"

# ANSI color helpers
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

#--- Show local Beetroot version
if [ -f "$VERSION_FILE" ]; then
    LOCAL_VERSION=$(cat "$VERSION_FILE")
    echo -e "${GREEN}Beetroot Version: $LOCAL_VERSION${RESET}"
else
    echo -e "${RED}VERSION file not found at $VERSION_FILE${RESET}"
    LOCAL_VERSION="unknown"
fi

#--- Fetch remote version
REMOTE_VERSION=$(curl -fsSL "$GITHUB_VERSION_URL" 2>/dev/null || echo "unavailable")
if [ "$REMOTE_VERSION" != "unavailable" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
    echo -e "${YELLOW}A newer Beetroot version is available: $REMOTE_VERSION${RESET}"
    echo -e "Run: ${GREEN}./beetup.sh --update${RESET}"
fi

echo ""
echo -e "${GREEN}Checking environment dependencies...${RESET}"

#--- Version helpers
get_version() {
    case "$1" in
        docker) docker --version 2>/dev/null ;;
        docker-compose)
            if command -v docker compose &>/dev/null; then
                docker compose version 2>/dev/null
            elif command -v docker-compose &>/dev/null; then
                docker-compose version 2>/dev/null
            else
                echo "not installed"
            fi ;;
        python3) python3 --version 2>/dev/null ;;
        pip3) pip3 --version 2>/dev/null ;;
        python3-venv) echo "(Python module; no version output)" ;;
        *) echo "unknown" ;;
    esac
}

is_installed() {
    dpkg -s "$1" &>/dev/null || command -v "$1" &>/dev/null
}

#--- Process dependency file
if [ ! -f "$DEPENDENCIES_FILE" ]; then
    echo -e "${RED}Missing DEPENDENCIES file: $DEPENDENCIES_FILE${RESET}"
    exit 1
fi

while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue  # skip blank lines and comments
    printf "%-16s" "$pkg"

    if is_installed "$pkg"; then
        echo -e "${GREEN}installed${RESET} ($(get_version "$pkg"))"
    else
        echo -e "${RED}missing${RESET}"
        echo "    → To install: ${YELLOW}sudo apt install $pkg${RESET}"
    fi
done < "$DEPENDENCIES_FILE"

echo ""
echo -e "${GREEN}Done.${RESET}"
