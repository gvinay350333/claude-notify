#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"
TTY_DEV="${3:-}"
TERM_PROG="${4:-}"

# Resolve terminal-notifier without depending on the hook's PATH (which may
# not include Homebrew's bin dir).
TN=$(command -v terminal-notifier 2>/dev/null)
[ -z "$TN" ] && [ -x /opt/homebrew/bin/terminal-notifier ] && TN=/opt/homebrew/bin/terminal-notifier
[ -z "$TN" ] && [ -x /usr/local/bin/terminal-notifier ] && TN=/usr/local/bin/terminal-notifier

LOG_DIR="$HOME/.claude-notify/data/logs"
mkdir -p "$LOG_DIR"

# Clickable notification: only when terminal-notifier is available, we know
# the session's tty, and it's a terminal we can focus (Apple Terminal today).
# Clicking runs focus.sh, which brings that exact tab to the front.
if [ -n "$TN" ] && [ -n "$TTY_DEV" ] && [ "$TERM_PROG" = "Apple_Terminal" ]; then
  echo "$(date '+%F %T') branch=terminal-notifier tty=$TTY_DEV" >> "$LOG_DIR/notification.log"
  "$TN" \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -execute "bash '$SCRIPT_DIR/focus.sh' '$TTY_DEV'"
else
  echo "$(date '+%F %T') branch=osascript tn=[$TN] tty=[$TTY_DEV] term=[$TERM_PROG]" >> "$LOG_DIR/notification.log"
  osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
fi
