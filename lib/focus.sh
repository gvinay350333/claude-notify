#!/bin/bash

# Focus the terminal tab bound to a given tty device.
# Usage: focus.sh /dev/ttysNNN
# Currently supports Apple Terminal.

TTY_DEV="$1"

# Only accept a well-formed tty device path (avoids injecting anything odd
# into the AppleScript below).
case "$TTY_DEV" in
  /dev/ttys[0-9]*) ;;
  *) exit 0 ;;
esac

osascript <<EOF
tell application "Terminal"
  activate
  repeat with w in windows
    repeat with t in tabs of w
      if (tty of t) is "$TTY_DEV" then
        set selected of t to true
        set frontmost of w to true
        set index of w to 1
        return
      end if
    end repeat
  end repeat
end tell
EOF
