#!/bin/bash
set -e

PROJECT_ROOT="$(dirname "$0")"
LOG_FILE="$PROJECT_ROOT/shared/logs/install.log"
CONFIG_FILE="$PROJECT_ROOT/config/service-config.yaml"

mkdir -p "$PROJECT_ROOT/shared/logs"
touch "$LOG_FILE"

log() {
    echo "$1"
    echo "$(date +'%F %T') - $1" >> "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        log "Missing required command: $1"
        MISSING_DEPS+=("$1")
    fi
}

MISSING_DEPS=()
log "🔍 Checking system dependencies..."

check_command docker
check_command docker-compose
check_command python3
check_command curl

if [ "${#MISSING_DEPS[@]}" -gt 0 ]; then
    echo "❌ Missing dependencies: ${MISSING_DEPS[*]}"
    echo "Please install them before continuing."
    exit 1
fi

log "✅ All dependencies found."

log "📁 Creating default directories..."
mkdir -p "$PROJECT_ROOT/shared/files" "$PROJECT_ROOT/shared/backup" "$PROJECT_ROOT/shared/library"

if [ ! -f "$CONFIG_FILE" ]; then
    log "📝 Creating empty config file..."
    mkdir -p "$(dirname "$CONFIG_FILE")"
    touch "$CONFIG_FILE"
fi

log "🚀 Running beetenv to scan and register services..."
python3 "$PROJECT_ROOT/config/scripts/beetenv.py"

read -p "Choose port for local admin interface (default 80): " ADMIN_PORT
ADMIN_PORT=${ADMIN_PORT:-80}

echo "Starting beetroot admin web interface on port $ADMIN_PORT..."

nohup python3 config/web/backend.py --port "$ADMIN_PORT" >/dev/null 2>&1 &

log "✅ Installation complete."
echo "🎉 Setup finished! You can now launch services with:"
echo "   ./config/scripts/mose.sh wordpress --up"