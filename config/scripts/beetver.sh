#!/bin/bash
# beetver.sh -- Beetroot system version and environment checker

set -e

# --- Path Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$PROJECT_ROOT/VERSION"
DEPENDENCIES_FILE="$SCRIPT_DIR/DEPENDENCIES"
REPO="gpeterson78/beetroot"
GITHUB_VERSION_URL="https://raw.githubusercontent.com/$REPO/main/VERSION"

# --- ANSI Colors ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# --- OS Detection ---
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$ID"
        OS_NAME="$PRETTY_NAME"
    else
        OS="unknown"
        OS_NAME="Unknown OS"
    fi
}

# --- Print Beetroot Version ---
print_version() {
    echo -e "${GREEN}Beetroot Version:${RESET}"
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo -e "${RED}VERSION file not found at $VERSION_FILE${RESET}"
    fi
}

# --- Print Current Commit + Remote Version ---
print_hash() {
    echo -e "${GREEN}Git Commit Hash:${RESET}"
    HASH=$(git -C "$PROJECT_ROOT" rev-parse HEAD 2>/dev/null || echo "not a git repo")
    echo "$HASH"

    REMOTE_VERSION=$(curl -fsSL "$GITHUB_VERSION_URL" 2>/dev/null || echo "unavailable")
    if [ -f "$VERSION_FILE" ]; then
        LOCAL_VERSION=$(cat "$VERSION_FILE")
        if [ "$REMOTE_VERSION" != "unavailable" ] && [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
            echo -e "${YELLOW}A newer Beetroot version is available: $REMOTE_VERSION${RESET}"
            echo -e "Run: ${GREEN}./beetup.sh --update${RESET}"
        fi
    fi
}

# --- Print OS Info ---
print_os() {
    detect_os
    echo -e "${GREEN}Operating System:${RESET} $OS_NAME"
}

# --- Get Installed Version of a Package ---
get_version() {
    if dpkg -s "$1" &>/dev/null; then
        dpkg-query -W -f='${Version}' "$1" 2>/dev/null
    elif command -v "$1" &>/dev/null; then
        "$1" --version 2>/dev/null | head -n 1
    else
        echo "not installed"
    fi
}

# --- Check if Installed ---
is_installed() {
    dpkg -s "$1" &>/dev/null || command -v "$1" &>/dev/null
}

# --- Generate Install Hint Based on OS ---
get_install_hint() {
    case "$OS" in
        debian|ubuntu)
            echo "sudo apt install $1"
            ;;
        rhel|centos|fedora)
            echo "sudo yum install $1"
            ;;
        arch)
            echo "sudo pacman -S $1"
            ;;
        *)
            echo "Install manually: $1"
            ;;
    esac
}

# --- Check and Print Dependencies ---
print_dependencies() {
    detect_os
    echo -e "${GREEN}Checking environment dependencies...${RESET}"
    echo ""
    printf "%-16s %-10s %s\n" "Package" "Status" "Version / Install Hint"
    printf "%-16s %-10s %s\n" "----------------" "----------" "----------------------------"

    if [ ! -f "$DEPENDENCIES_FILE" ]; then
        echo -e "${RED}Missing DEPENDENCIES file: $DEPENDENCIES_FILE${RESET}"
        exit 1
    fi

    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

        if is_installed "$pkg"; then
            STATUS="${GREEN}INSTALLED${RESET}"
            HINT="$(get_version "$pkg")"
        else
            STATUS="${RED}MISSING${RESET}"
            HINT="${YELLOW}$(get_install_hint "$pkg")${RESET}"
        fi

        printf "%-16s %-10b %b\n" "$pkg" "$STATUS" "$HINT"
    done < "$DEPENDENCIES_FILE"

    echo ""
    echo -e "${GREEN}Done.${RESET}"
}

# --- Main Execution Dispatcher ---
case "$1" in
    -version)
        print_version
        ;;
    -hash)
        print_hash
        ;;
    -os)
        print_os
        ;;
    -dependencies)
        print_dependencies
        ;;
    -all)
        print_version
        echo ""
        print_hash
        echo ""
        print_os
        echo ""
        print_dependencies
        ;;
    *)
        echo -e "${GREEN}Beetroot System Checker${RESET}"
        echo ""
        echo -e "Usage: ${YELLOW}$0 [option]${RESET}"
        echo ""
        echo "Available options:"
        echo -e "  ${YELLOW}-version${RESET}        Show current Beetroot version from VERSION file"
        echo -e "  ${YELLOW}-hash${RESET}           Show local git commit hash and compare to GitHub main"
        echo -e "  ${YELLOW}-os${RESET}             Show local operating system version"
        echo -e "  ${YELLOW}-dependencies${RESET}   Check required packages from DEPENDENCIES file"
        echo -e "  ${YELLOW}-all${RESET}            Run all checks"
        echo ""
        echo "Example:"
        echo -e "  ${YELLOW}$0 -all${RESET}"
        exit 0
        ;;
esac

