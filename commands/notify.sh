#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" read)

PROJECT=""
if [ -n "$SESSION_JSON" ]; then
  PROJECT=$(basename "$(echo "$SESSION_JSON" | jq -r '.project')")
fi

MESSAGE="Claude needs your attention"
[ -n "$PROJECT" ] && MESSAGE="$PROJECT needs your attention"

TERMINAL_APP=""
TERMINAL_TTY=""
if [ -n "$SESSION_JSON" ]; then
  TERMINAL_APP=$(echo "$SESSION_JSON" | jq -r '.terminal_app // empty')
  TERMINAL_TTY=$(echo "$SESSION_JSON" | jq -r '.tty // empty')
fi

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "Claude Notify" \
  "$MESSAGE" \
  "$TERMINAL_APP" \
  "$TERMINAL_TTY"
