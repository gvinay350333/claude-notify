#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" read)

PROJECT=""
TTY_DEV=""
TERM_PROG=""

if [ -n "$SESSION_JSON" ]; then
  PROJECT=$(basename "$(echo "$SESSION_JSON" | jq -r '.project')")
  TTY_DEV=$(echo "$SESSION_JSON" | jq -r '.tty // empty')
  TERM_PROG=$(echo "$SESSION_JSON" | jq -r '.term // empty')
fi

MESSAGE="Claude needs your attention"
[ -n "$PROJECT" ] && MESSAGE="$PROJECT needs your attention"

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "Claude Notify" \
  "$MESSAGE" \
  "$TTY_DEV" \
  "$TERM_PROG"
