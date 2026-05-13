#!/usr/bin/env bash
# cx - Codex-led launcher

set -euo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "${1:-}" = "help" ]; then
  echo "Usage: cx [task]"
  echo "Starts a Codex-led session. The entrypoint wins over the mode file."
  echo "Codex still routes discovery to Gemini and judgment-heavy decisions to Claude."
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
  USER_PROMPT="Start a Codex-led interactive session in this workspace. Ask what to work on next if no task is already clear."
fi

WRAPPED="$BASE_PROMPT

GLOBAL ROUTING MODE: $MODE

SESSION ENTRYPOINT: Codex via cx
SESSION ROLE: Codex is the primary orchestrator/executor for this session. Use Gemini for discovery work. Escalate to Claude whenever judgment is needed, including strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish where quality matters, conflicts between sources/tool outputs, high-stakes judgment, and similar cases.

USER TASK:
$USER_PROMPT"

exec codex \
  --sandbox workspace-write \
  --ask-for-approval never \
  "$WRAPPED"
