#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PROMPT_TEXT="${1:-}"
bash "$SCRIPT_DIR/../lib/session.sh" start "$PROMPT_TEXT"
