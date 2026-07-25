#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" stop)

[ -z "$SESSION_JSON" ] && exit 0

START=$(echo "$SESSION_JSON" | jq -r '.start_time')
PROJECT=$(echo "$SESSION_JSON" | jq -r '.project // empty')
LAST_PROMPT=$(echo "$SESSION_JSON" | jq -r '.last_prompt // empty')

NOW=$(date +%s)
DURATION=$((NOW-START))

# Format Title and Subtitle context
TITLE="Task Completed"
SUBTITLE=""
[ -n "$PROJECT" ] && SUBTITLE="📁 $PROJECT"

MESSAGE="Completed in ${DURATION}s"
if [ -n "$LAST_PROMPT" ]; then
  MESSAGE="$MESSAGE • $LAST_PROMPT"
fi

TERMINAL_APP=""
TERMINAL_TTY=""
if [ -n "$SESSION_JSON" ]; then
  TERMINAL_APP=$(echo "$SESSION_JSON" | jq -r '.terminal_app // empty')
  TERMINAL_TTY=$(echo "$SESSION_JSON" | jq -r '.tty // empty')
fi

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "$TITLE" \
  "$MESSAGE" \
  "$TERMINAL_APP" \
  "$TERMINAL_TTY" \
  "$SUBTITLE"
