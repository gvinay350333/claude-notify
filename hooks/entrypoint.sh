#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENT=$(jq -r '.hook_event_name')

case "$EVENT" in
  UserPromptSubmit)
    bash "$SCRIPT_DIR/../lib/session.sh" start
    ;;
  Stop)
    bash "$SCRIPT_DIR/../lib/session.sh" stop
    ;;
esac
