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
echo "🔔 Checking notification helper..."

if command -v terminal-notifier >/dev/null 2>&1; then
    echo "✓ terminal-notifier found (notifications are clickable)"
elif command -v brew >/dev/null 2>&1; then
    printf "  terminal-notifier not found. Install it for click-to-focus notifications? [y/N] "
    read -r reply
    case "$reply" in
        [Yy]*) brew install terminal-notifier ;;
        *) echo "  Skipped. Notifications will work but won't be clickable." ;;
    esac
else
    echo "  ⚠ terminal-notifier and Homebrew not found."
    echo "    Notifications will work but won't be clickable. Install terminal-notifier for click-to-focus."
fi

echo ""
echo "⚙️ Configuring Claude..."

bash lib/settings.sh

echo ""
echo "✅ claude-notify installed successfully!"
echo "📁 Installed to: $INSTALL_DIR"
