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

chmod +x "$INSTALL_DIR/commands/list.sh"
chmod +x "$INSTALL_DIR/lib/list_sessions.py"

echo "🔨 Compiling Swift helper..."
swiftc "$INSTALL_DIR/lib/notifier.swift" -o "$INSTALL_DIR/lib/notifier" >/dev/null 2>&1

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
echo "⚙️ Configuring Shell Aliases..."
for RC_FILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$RC_FILE" ]; then
        ADDED=0
        for ALIAS_CMD in "/clist" "clist"; do
            # Check for exact alias definition
            if ! grep -F -q "alias ${ALIAS_CMD}=" "$RC_FILE"; then
                if [ "$ADDED" -eq 0 ]; then
                    echo "" >> "$RC_FILE"
                    echo "# claude-notify aliases" >> "$RC_FILE"
                    ADDED=1
                fi
                echo "alias ${ALIAS_CMD}=\"bash \\$HOME/.claude-notify/commands/list.sh\"" >> "$RC_FILE"
                echo "✓ Added ${ALIAS_CMD} alias to $RC_FILE"
            fi
        done
    fi
done

echo ""
echo "✅ claude-notify installed successfully!"
echo "📁 Installed to: $INSTALL_DIR"
