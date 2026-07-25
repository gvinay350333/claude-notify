#!/bin/bash

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"
TERMINAL_APP="${3:-}"
TERMINAL_TTY="${4:-}"
LAST_PROMPT="${5:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Compile the Swift notifier if binary does not exist or was modified
if [ ! -f "$SCRIPT_DIR/notifier" ] || [ "$SCRIPT_DIR/notifier.swift" -nt "$SCRIPT_DIR/notifier" ]; then
  swiftc "$SCRIPT_DIR/notifier.swift" -o "$SCRIPT_DIR/notifier" >/dev/null 2>&1
fi

# Execute the native compiled notifier binary in the background
if [ -f "$SCRIPT_DIR/notifier" ]; then
  "$SCRIPT_DIR/notifier" "$TITLE" "$MESSAGE" "$TERMINAL_APP" "$TERMINAL_TTY" "$LAST_PROMPT" >/dev/null 2>&1 &
fi
