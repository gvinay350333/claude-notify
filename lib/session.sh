#!/bin/bash

set -e

ACTION="$1"

DATA_DIR="$HOME/.claude-notify/data/sessions"
mkdir -p "$DATA_DIR"

SESSION_ID=$(jq -r '.session_id')
SESSION_FILE="$DATA_DIR/$SESSION_ID.json"

case "$ACTION" in

start)

    jq \
      --arg start "$(date +%s)" \
      '. + {start_time:$start}' \
      > "$SESSION_FILE"

    ;;

stop)

    [ ! -f "$SESSION_FILE" ] && exit 0

    cat "$SESSION_FILE"

    ;;

esac
