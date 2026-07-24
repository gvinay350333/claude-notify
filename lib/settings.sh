#!/bin/bash

set -e

CONFIG_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="$HOME/.claude-notify/hooks/entrypoint.sh"

TMP_FILE=$(mktemp)

jq --arg cmd "$HOOK_COMMAND" '
# Ensure hooks and Stop exist
.hooks = (.hooks // {}) |
.hooks.Stop = (.hooks.Stop // []) |

# Remove any old claude-notify hook regardless of path
.hooks.Stop |= map(
  .hooks |= map(
    select(
      (.command | test("claude-notify\\.sh$")) | not
    )
  )
) |

# Remove empty hook groups
.hooks.Stop |= map(select(.hooks | length > 0)) |

# Add our hook
.hooks.Stop += [
  {
    "hooks": [
      {
        "type": "command",
        "command": $cmd,
        "async": true
      }
    ]
  }
]
' "$CONFIG_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"

echo "✓ Claude Stop hook configured"
