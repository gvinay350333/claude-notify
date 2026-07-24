#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/../lib/session.sh" stop

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "Claude Notify" \
  "Claude finished responding."
