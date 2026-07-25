#!/bin/bash

set -e

ACTION="$1"

DATA_DIR="$HOME/.claude-notify/data/sessions"
mkdir -p "$DATA_DIR"

SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"

[ -z "$SESSION_ID" ] && exit 0

SESSION_FILE="$DATA_DIR/$SESSION_ID.json"

case "$ACTION" in
start)

TERM_APP=""
# Try to get the frontmost application name
FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null || echo "")

case "$FRONTMOST" in
  Terminal|iTerm|iTerm2|WezTerm|Alacritty|Ghostty|kitty|Hyper|Cursor|Code|Electron)
    TERM_APP="$FRONTMOST"
    ;;
  *)
    # Fallback to TERM_PROGRAM env var mapping
    case "$TERM_PROGRAM" in
      Apple_Terminal) TERM_APP="Terminal" ;;
      iTerm.app) TERM_APP="iTerm" ;;
      WezTerm) TERM_APP="WezTerm" ;;
      Alacritty) TERM_APP="Alacritty" ;;
      Ghostty) TERM_APP="Ghostty" ;;
      vscode)
        if pgrep -x "Cursor" >/dev/null 2>&1; then
          TERM_APP="Cursor"
        else
          TERM_APP="Code"
        fi
        ;;
      *) TERM_APP="" ;;
    esac
    ;;
esac

SESSION_TTY=""
# Try standard tty command
SESSION_TTY=$(tty 2>/dev/null || echo "")

if [ -z "$SESSION_TTY" ] || [ "$SESSION_TTY" = "not a tty" ]; then
  SESSION_TTY=""
  # Try to find the TTY of the parent shell process by traversing up the process tree
  PID=$$
  for i in {1..5}; do
    [ -z "$PID" ] && break
    TTY_VAL=$(ps -o tty= -p "$PID" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$TTY_VAL" ] && [ "$TTY_VAL" != "??" ] && [ "$TTY_VAL" != "?" ]; then
      SESSION_TTY="/dev/$TTY_VAL"
      break
    fi
    PID=$(ps -o ppid= -p "$PID" 2>/dev/null | tr -d '[:space:]')
  done
fi

cat > "$SESSION_FILE" <<EOF
{
  "session_id":"$SESSION_ID",
  "project":"${CLAUDE_PROJECT_DIR}",
  "start_time":$(date +%s),
  "terminal_app":"$TERM_APP",
  "tty":"$SESSION_TTY"
}
EOF
;;

read)

[ -f "$SESSION_FILE" ] || exit 0

cat "$SESSION_FILE"
;;

stop)

[ -f "$SESSION_FILE" ] || exit 0

cat "$SESSION_FILE"

rm -f "$SESSION_FILE"
;;

esac
