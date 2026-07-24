#!/bin/bash

TITLE="${1:-Claude Notify}"
MESSAGE="${2:-Task completed}"

osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
