#!/bin/bash

set -e

CONFIG_FILE="$HOME/.claude/settings.json"
HOOK_COMMAND="$HOME/.claude-notify/hooks/entrypoint.sh"

TMP_FILE=$(mktemp)

jq --arg cmd "$HOOK_COMMAND" '

# Ensure hooks object exists
.hooks = (.hooks // {}) |

############################
# STOP HOOK
############################

.hooks.Stop = (.hooks.Stop // []) |

.hooks.Stop |= map(
  .hooks |= map(
    select((.command | test("claude-notify|entrypoint")) | not)
  )
) |

.hooks.Stop |= map(select(.hooks | length > 0)) |

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
] |

############################
# USER PROMPT SUBMIT HOOK
############################

.hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) |

.hooks.UserPromptSubmit |= map(
  .hooks |= map(
    select((.command | test("claude-start|claude-notify|entrypoint")) | not)
  )
) |

.hooks.UserPromptSubmit |= map(select(.hooks | length > 0)) |

.hooks.UserPromptSubmit += [
  {
    "hooks": [
      {
        "type": "command",
        "command": $cmd
      }
    ]
  }
]

' "$CONFIG_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$CONFIG_FILE"

echo "✓ Claude hooks configured"
