#!/bin/bash

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"
# Terminal the session runs in (from $TERM_PROGRAM); caller passes it, but
# fall back to this process's own env if not provided.
TERM_PROG="${3:-$TERM_PROGRAM}"

# macOS only — osascript is the notification transport. No-op elsewhere.
command -v osascript >/dev/null 2>&1 || exit 0

LOG_DIR="$HOME/.claude-notify/data/logs"
mkdir -p "$LOG_DIR"

# Map $TERM_PROGRAM to the macOS app name to attribute the notification to.
# When the notification is owned by that app, clicking it brings the app to
# the front. Unknown terminals fall through to a plain banner.
case "$TERM_PROG" in
  Apple_Terminal) APP="Terminal" ;;
  iTerm.app)      APP="iTerm" ;;
  vscode)         APP="Visual Studio Code" ;;
  WarpTerminal)   APP="Warp" ;;
  Hyper)          APP="Hyper" ;;
  Tabby)          APP="Tabby" ;;
  ghostty)        APP="Ghostty" ;;
  WezTerm)        APP="WezTerm" ;;
  *)              APP="" ;;
esac

echo "$(date '+%F %T') notify term=[$TERM_PROG] app=[$APP] msg=[$MESSAGE]" >> "$LOG_DIR/notification.log"

# Plain banner, owned by osascript (always works, clicking opens Script Editor).
post_generic() {
  osascript - "$TITLE" "$MESSAGE" <<'APPLESCRIPT'
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT
}

# Banner owned by the terminal app, so clicking it focuses that app.
# Args go through argv (not string interpolation) so they can't inject.
post_as_app() {
  osascript - "$1" "$TITLE" "$MESSAGE" <<'APPLESCRIPT'
on run argv
  tell application (item 1 of argv) to display notification (item 3 of argv) with title (item 2 of argv)
end run
APPLESCRIPT
}

if [ -n "$APP" ]; then
  post_as_app "$APP" 2>/dev/null || post_generic
else
  post_generic
fi
