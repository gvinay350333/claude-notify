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

# Resolve the tty of the Claude Code process so a notification can later
# focus this exact terminal tab. Hooks run non-interactively, so `tty`
# won't work here — read it from the parent Claude process instead.
TTY_DEV=$(ps -o tty= -p "${CLAUDE_PID:-$PPID}" 2>/dev/null | tr -d '[:space:]')
if [ -n "$TTY_DEV" ] && [ "$TTY_DEV" != "??" ]; then
  TTY_DEV="/dev/$TTY_DEV"
else
  TTY_DEV=""
fi

cat > "$SESSION_FILE" <<EOF
{
  "session_id":"$SESSION_ID",
  "project":"${CLAUDE_PROJECT_DIR}",
  "term":"${TERM_PROGRAM}",
  "tty":"$TTY_DEV",
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
