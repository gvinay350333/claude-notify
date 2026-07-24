#!/bin/bash

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"

LOG_DIR="$HOME/.claude-notify/data/logs"
mkdir -p "$LOG_DIR"
echo "$(date '+%F %T') notify title=[$TITLE] msg=[$MESSAGE]" >> "$LOG_DIR/notification.log"

# Post the notification as Terminal itself. macOS 26 blocks third-party
# notifier apps (e.g. terminal-notifier, a 2017 ad-hoc-signed build), so we
# rely on the built-in osascript path. Because Terminal owns the notification,
# clicking it brings Terminal to the front. Args are passed via argv (not
# interpolated) so the title/message can't break or inject into AppleScript.
osascript - "$TITLE" "$MESSAGE" <<'APPLESCRIPT'
on run argv
  set theTitle to item 1 of argv
  set theMessage to item 2 of argv
  tell application "Terminal" to display notification theMessage with title theTitle
end run
APPLESCRIPT
