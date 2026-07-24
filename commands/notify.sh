#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/../lib/notification.sh" \
  "Claude Notify" \
  "Claude has finished responding."
