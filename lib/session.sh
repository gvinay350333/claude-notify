#!/bin/bash

set -e

ACTION="$1"

DATA_DIR="$HOME/.claude-notify/data/sessions"
mkdir -p "$DATA_DIR"

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"

[ -z "$SESSION_ID" ] && exit 0

SESSION_FILE="$DATA_DIR/$SESSION_ID.json"

case "$ACTION" in
start)

cat > "$SESSION_FILE" <<EOF
{
  "session_id":"$SESSION_ID",
  "project":"${CLAUDE_PROJECT_DIR}",
  "start_time":$(date +%s)
}
EOF
;;

read)

[ -f "$SESSION_FILE" ] || exit 0

cat "$SESSION_FILE"
;;

stop)

[ -f "$SESSION_FILE" ] || exit 0

cat "$SESSION_FILE"

rm -f "$SESSION_FILE"
;;

esac
