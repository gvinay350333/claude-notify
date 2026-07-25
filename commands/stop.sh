#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" stop)

[ -z "$SESSION_JSON" ] && exit 0

START=$(echo "$SESSION_JSON" | jq -r '.start_time')
PROJECT=$(basename "$(echo "$SESSION_JSON" | jq -r '.project')")

NOW=$(date +%s)
DURATION=$((NOW-START))

TERMINAL_APP=""
TERMINAL_TTY=""
if [ -n "$SESSION_JSON" ]; then
  TERMINAL_APP=$(echo "$SESSION_JSON" | jq -r '.terminal_app // empty')
  TERMINAL_TTY=$(echo "$SESSION_JSON" | jq -r '.tty // empty')
fi

bash "$SCRIPT_DIR/../lib/notification.sh" \
"Claude Notify" \
"$PROJECT finished in ${DURATION}s" \
"$TERMINAL_APP" \
"$TERMINAL_TTY"
