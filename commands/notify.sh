#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" read)

PROJECT=""
if [ -n "$SESSION_JSON" ]; then
  PROJECT=$(basename "$(echo "$SESSION_JSON" | jq -r '.project')")
fi

MESSAGE="Claude needs your attention"
[ -n "$PROJECT" ] && MESSAGE="$PROJECT needs your attention"

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "Claude Notify" \
  "$MESSAGE"
