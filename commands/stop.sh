#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SESSION_JSON=$(bash "$SCRIPT_DIR/../lib/session.sh" stop)

[ -z "$SESSION_JSON" ] && exit 0

START=$(echo "$SESSION_JSON" | jq -r '.start_time')
PROJECT=$(basename "$(echo "$SESSION_JSON" | jq -r '.project')")
TERM_PROG=$(echo "$SESSION_JSON" | jq -r '.term // empty')

NOW=$(date +%s)
DURATION=$((NOW-START))

bash "$SCRIPT_DIR/../lib/notification.sh" \
"Claude Notify" \
"$PROJECT finished in ${DURATION}s" \
"$TERM_PROG"
