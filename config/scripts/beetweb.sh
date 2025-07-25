#!/bin/bash
# beetweb.sh -- Control the Beetroot web interface
# Runs the Flask admin interface (port configurable)
# Requires Python virtual environment under config/web/venv

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WEB_DIR="$BASE_DIR/config/web"
VENV_DIR="$WEB_DIR/venv"
PID_FILE="/tmp/beetweb.pid"
LOG_FILE="/tmp/beetweb.log"
PORT_FILE="$WEB_DIR/web.port"
DEFAULT_PORT=4200

# Read stored port or default
PORT=$( [ -f "$PORT_FILE" ] && cat "$PORT_FILE" || echo "$DEFAULT_PORT" )

start() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Web interface already running on port $PORT (PID $(cat "$PID_FILE"))"
        exit 0
    fi

    if [ ! -d "$VENV_DIR" ]; then
        echo "Error: Virtual environment not found. Run beetsync first."
        exit 1
    fi

    echo "Starting web interface on port $PORT..."
    source "$VENV_DIR/bin/activate"
    export FLASK_APP="$WEB_DIR/app.py"
    export BEETROOT_WEB_PORT="$PORT"
    nohup flask run --host=0.0.0.0 --port="$PORT" > "$LOG_FILE" 2>&1 &
    PID=$!
    echo "$PID" > "$PID_FILE"
    echo "Started. PID: $PID (logs: $LOG_FILE)"
    deactivate
}

stop() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Stopping web interface (PID $(cat "$PID_FILE"))..."
        kill "$(cat "$PID_FILE")"
        rm -f "$PID_FILE"
        echo "Stopped."
    else
        echo "Web interface not running, but PID file exists. Cleaning up."
        rm -f "$PID_FILE"
    fi
}

status() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Web interface is running on port $PORT (PID $(cat "$PID_FILE"))"
    else
        echo "Web interface is not running."
    fi
}

set_port() {
    local new_port="$1"
    echo "$new_port" > "$PORT_FILE"
    echo "Port updated to $new_port. Restart to apply."
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    restart) stop; start ;;
    status) status ;;
    set-port) shift; set_port "$1" ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|set-port <port>}"
        exit 1
        ;;
esac
