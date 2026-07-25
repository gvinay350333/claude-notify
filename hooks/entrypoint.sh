#!/bin/bash

set -e

# Ensure homebrew and local paths are included so that jq is found in background environments
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

EVENT=$(jq -r '.hook_event_name')

case "$EVENT" in
  UserPromptSubmit)
    "$ROOT_DIR/commands/start.sh"
    ;;
  Stop)
    "$ROOT_DIR/commands/stop.sh"
    ;;
  Notification)
    echo "Notification Hook Fired $(date)" >> ~/.claude-notify/data/logs/notification.log
    "$ROOT_DIR/commands/notify.sh"
    ;;
esac
