#!/bin/bash
# beetver.sh -- Beetroot version and dependency checker

set -e

PROJECT_ROOT="$(dirname "$(dirname "$(dirname "$0")")")"
VERSION_FILE="$PROJECT_ROOT/VERSION"
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

#--- Dependencies
REQUIRED_PKGS=(docker docker-compose python3 pip3 python3-venv)

check_installed() {
    dpkg -s "$1" &>/dev/null
}

get_version() {
    case "$1" in
        docker) docker --version ;;
        docker-compose)
            if command -v docker compose &>/dev/null; then
                docker compose version
            elif command -v docker-compose &>/dev/null; then
                docker-compose version
            else
                echo "not installed"
            fi ;;
        python3) python3 --version ;;
        pip3) pip3 --version ;;
        python3-venv) echo "(module, no version output)" ;;
        *) echo "unknown" ;;
    esac
}

install_package() {
    sudo apt update
    sudo apt install -y "$1"
}

echo -e "${GREEN}Checking dependencies...${RESET}"
for pkg in "${REQUIRED_PKGS[@]}"; do
    echo -n "$pkg: "
    if check_installed "$pkg"; then
        echo -e "${GREEN}installed${RESET} ($(get_version "$pkg"))"
    else
        echo -e "${RED}missing${RESET}"
        read -rp "  Install $pkg? [Y/n] " answer
        answer=${answer,,}  # lowercase
        if [[ "$answer" =~ ^(y|yes|)$ ]]; then
            install_package "$pkg"
        else
            echo "  Skipping $pkg"
        fi
    fi
done

echo ""
echo -e "${GREEN}Done.${RESET}"
