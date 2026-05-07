#!/usr/bin/env bash
# ai-mode - Global routing mode switcher

set -euo pipefail

COMMAND="${1:-status}"
STATE_DIR="${AI_ROUTING_HOME:-$HOME/.claude/.ai-routing}"
MODE_FILE="$STATE_DIR/mode"

read_mode() {
  if [ -f "$MODE_FILE" ]; then
    tr '[:upper:]' '[:lower:]' < "$MODE_FILE" | tr -d '[:space:]'
  else
    printf "claude"
  fi
}

case "$COMMAND" in
  claude)
    mkdir -p "$STATE_DIR"
    printf "claude" > "$MODE_FILE"
    echo "AI routing mode: claude"
    echo "Use Claude Code normally. Codex remains available through cdx/cx."
    ;;
  codex)
    mkdir -p "$STATE_DIR"
    printf "codex" > "$MODE_FILE"
    echo "AI routing mode: codex"
    echo "Start Codex-primary work with: cx"
    ;;
  status)
    echo "AI routing mode: $(read_mode)"
    echo "Mode file: $MODE_FILE"
    ;;
  -h|--help|help)
    echo "Usage: ai-mode [status|codex|claude]"
    echo "  ai-mode codex   Switch globally to Codex-primary outage mode"
    echo "  ai-mode claude  Switch globally back to Claude orchestration"
    echo "  ai-mode status  Show the current mode"
    ;;
  *)
    echo "Unknown mode command: $COMMAND" >&2
    echo "Usage: ai-mode [status|codex|claude]" >&2
    exit 1
    ;;
esac
