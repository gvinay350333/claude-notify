#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"
TTY_DEV="${3:-}"
TERM_PROG="${4:-}"

# Clickable notification: only when terminal-notifier is available, we know
# the session's tty, and it's a terminal we can focus (Apple Terminal today).
# Clicking runs focus.sh, which brings that exact tab to the front.
if command -v terminal-notifier >/dev/null 2>&1 \
   && [ -n "$TTY_DEV" ] \
   && [ "$TERM_PROG" = "Apple_Terminal" ]; then
  terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -execute "bash '$SCRIPT_DIR/focus.sh' '$TTY_DEV'"
else
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
fi
