#!/bin/bash

set -e

echo "🚀 Installing claude-notify..."

CONFIG_DIR="$HOME/.claude"
CONFIG_FILE="$CONFIG_DIR/settings.json"
BACKUP_FILE="$CONFIG_DIR/settings.json.bak"

mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✓ Backup created: $BACKUP_FILE"
else
    echo "{}" > "$CONFIG_FILE"
fi

echo "✓ Claude config found"

echo ""
echo "Next step:"
echo "We'll automatically configure Claude hooks in the next version."
