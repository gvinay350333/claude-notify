#!/bin/bash

set -e

echo "🚀 Installing claude-notify..."

INSTALL_DIR="$HOME/.claude-notify"
CLAUDE_DIR="$HOME/.claude"
CONFIG_FILE="$CLAUDE_DIR/settings.json"
BACKUP_FILE="$CLAUDE_DIR/settings.json.bak"

mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/data/sessions"
mkdir -p "$INSTALL_DIR/data/logs"

echo "📦 Copying runtime files..."

rm -rf "$INSTALL_DIR/hooks"
rm -rf "$INSTALL_DIR/lib"
rm -rf "$INSTALL_DIR/commands"

cp -R hooks "$INSTALL_DIR/"
cp -R lib "$INSTALL_DIR/"
cp -R commands "$INSTALL_DIR/"

if [ -f VERSION ]; then
    cp VERSION "$INSTALL_DIR/"
fi

mkdir -p "$CLAUDE_DIR"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "✓ Backed up settings.json"
else
    echo "{}" > "$CONFIG_FILE"
fi

echo ""
echo "⚙️ Configuring Claude..."

bash lib/settings.sh

echo ""
echo "✅ claude-notify installed successfully!"
echo "📁 Installed to: $INSTALL_DIR"
