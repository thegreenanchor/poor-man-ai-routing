#!/usr/bin/env bash
# cx - Codex-primary launcher

set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "help" ]; then
  echo "Usage: cx [task]"
  echo "Starts Codex as the primary routing agent."
  echo "Run 'ai-mode codex' to make Codex-primary mode explicit."
  exit 0
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROMPT_FILE="$( dirname "$SCRIPT_DIR" )/CODEX_PRIMARY.md"

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Missing Codex primary prompt: $PROMPT_FILE" >&2
  exit 1
fi

mkdir -p ./.scratch

MODE_FILE="${AI_ROUTING_HOME:-$HOME/.claude/.ai-routing}/mode"
MODE="claude"
if [ -f "$MODE_FILE" ]; then
  MODE="$(tr '[:upper:]' '[:lower:]' < "$MODE_FILE" | tr -d '[:space:]')"
fi

BASE_PROMPT="$(cat "$PROMPT_FILE")"
if [ "$#" -gt 0 ]; then
  USER_PROMPT="$*"
else
  USER_PROMPT="Start a Codex-primary interactive session in this workspace. Ask what to work on next if no task is already clear."
fi

WRAPPED="$BASE_PROMPT

GLOBAL ROUTING MODE: $MODE

USER TASK:
$USER_PROMPT"

exec codex \
  --sandbox workspace-write \
  --ask-for-approval never \
  "$WRAPPED"
