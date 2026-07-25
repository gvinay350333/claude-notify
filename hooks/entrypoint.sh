#!/bin/bash

set -e

# Ensure homebrew and local paths are included so that jq is found in background environments
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PAYLOAD=$(cat -)

EVENT=$(echo "$PAYLOAD" | jq -r '.hook_event_name')

case "$EVENT" in
  UserPromptSubmit)
    PROMPT_TEXT=$(echo "$PAYLOAD" | jq -r '.prompt // empty')
    "$ROOT_DIR/commands/start.sh" "$PROMPT_TEXT"
    ;;
  Stop)
    "$ROOT_DIR/commands/stop.sh"
    ;;
esac
