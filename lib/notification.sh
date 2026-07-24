#!/bin/bash

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"

# macOS only — osascript is the notification transport. No-op elsewhere.
command -v osascript >/dev/null 2>&1 || exit 0

# Args go through argv (not string interpolation) so the title/message
# cannot break or inject into the AppleScript.
osascript - "$TITLE" "$MESSAGE" <<'APPLESCRIPT'
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT
