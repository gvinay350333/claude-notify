#!/bin/bash

ACTION="$1"

DATA_DIR="$HOME/.claude-notify/sessions"
mkdir -p "$DATA_DIR"

SESSION_ID=$(jq -r '.session_id')
FILE="$DATA_DIR/$SESSION_ID.json"

case "$ACTION" in
  start)
    jq '. + {start_time: now|floor}' > "$FILE"
    ;;

  stop)
    [ ! -f "$FILE" ] && exit 0

    START=$(jq -r '.start_time' "$FILE")
    END=$(date +%s)
    DURATION=$((END - START))

    PROJECT=$(basename "$(jq -r '.cwd' "$FILE")")
    PROMPT=$(jq -r '.prompt // ""' "$FILE")

    osascript <<EOF
display notification "$PROMPT\nDuration: ${DURATION}s" with title "✅ $PROJECT"
EOF

    rm -f "$FILE"
    ;;
esac
