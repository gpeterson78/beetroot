#!/bin/bash
set -e

WEB_DIR="$(dirname "$(realpath "$0")")/../web"
ENV_FILE="$WEB_DIR/.env"
VENV_DIR="$WEB_DIR/venv"
APP_FILE="$WEB_DIR/app.py"
FLASK_PID_FILE="$WEB_DIR/.flask.pid"

print_usage() {
  echo "Usage: $0 {start|stop|status|port <port>|help}"
  exit 1
}

ensure_env_file() {
  if [ ! -f "$ENV_FILE" ]; then
    echo "FLASK_ENV=development" > "$ENV_FILE"
    echo "FLASK_PORT=8080" >> "$ENV_FILE"
    echo "Created default .env at $ENV_FILE"
  fi
}

get_port() {
  grep FLASK_PORT "$ENV_FILE" | cut -d= -f2
}

start_web() {
  ensure_env_file
  source "$ENV_FILE"
  source "$VENV_DIR/bin/activate"

  if [ -f "$FLASK_PID_FILE" ] && kill -0 "$(cat "$FLASK_PID_FILE")" 2>/dev/null; then
    echo "Web interface is already running (PID $(cat "$FLASK_PID_FILE"))."
    exit 0
  fi

  echo "Starting web interface on port $FLASK_PORT..."
  FLASK_APP="$APP_FILE" flask run --host=0.0.0.0 --port="$FLASK_PORT" &
  echo $! > "$FLASK_PID_FILE"
  echo "Started. PID: $(cat "$FLASK_PID_FILE")"
}

stop_web() {
  if [ -f "$FLASK_PID_FILE" ]; then
    PID=$(cat "$FLASK_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      echo "Stopped web interface (PID $PID)."
    else
      echo "Web interface not running, but PID file exists. Cleaning up."
    fi
    rm -f "$FLASK_PID_FILE"
  else
    echo "Web interface is not running."
  fi
}

status_web() {
  if [ -f "$FLASK_PID_FILE" ] && kill -0 "$(cat "$FLASK_PID_FILE")" 2>/dev/null; then
    echo "Web interface is running (PID $(cat "$FLASK_PID_FILE"))."
  else
    echo "Web interface is not running."
  fi
}

change_port() {
  NEW_PORT="$1"
  if [[ ! "$NEW_PORT" =~ ^[0-9]+$ ]]; then
    echo "Invalid port: $NEW_PORT"
    exit 1
  fi
  sed -i "s/^FLASK_PORT=.*/FLASK_PORT=$NEW_PORT/" "$ENV_FILE"
  echo "Updated port to $NEW_PORT in $ENV_FILE"
  echo "Restart the web interface to apply the change."
}

### Main
COMMAND="$1"
case "$COMMAND" in
  start) start_web ;;
  stop) stop_web ;;
  status) status_web ;;
  port) shift; [ -z "$1" ] && print_usage; change_port "$1" ;;
  help|"") print_usage ;;
  *) echo "Unknown command: $COMMAND"; print_usage ;;
esac
