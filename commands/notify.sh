#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Wait for session file to be created (resolves race condition with async start hook)
SESSION_FILE="$HOME/.claude-notify/data/sessions/${CLAUDE_CODE_SESSION_ID:-}.json"
for i in {1..10}; do
  if [ -f "$SESSION_FILE" ] && [ -s "$SESSION_FILE" ]; then
    break
  fi
  sleep 0.1
done

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" read)
bash "$SCRIPT_DIR/../lib/session.sh" status "needs_approval"

STATUS_MSG="${1:-}"

PROJECT=""
LAST_PROMPT=""
if [ -n "$SESSION_JSON" ]; then
  PROJECT=$(echo "$SESSION_JSON" | jq -r '.project // empty')
  LAST_PROMPT=$(echo "$SESSION_JSON" | jq -r '.last_prompt // empty')
fi

# Format Title and Subtitle context
SHORT_PROJECT=$(echo "$PROJECT" | sed "s|^$HOME|~|")
TITLE="Claude Code"
[ -n "$PROJECT" ] && TITLE="📁 $SHORT_PROJECT"

SUBTITLE=""
[ -n "$LAST_PROMPT" ] && SUBTITLE="$LAST_PROMPT"

MESSAGE="Needs attention"
if [ -n "$STATUS_MSG" ]; then
  MESSAGE="Needs attention: $STATUS_MSG"
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
  "$SUBTITLE" \
  "true"
