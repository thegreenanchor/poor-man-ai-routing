#!/usr/bin/env bash
# large-file-guard.sh — PreToolUse hook
# Blocks Read calls on files exceeding the mode's line cap.
# Returns non-zero exit code with a message that prompts Claude to delegate.
#
# To enable: add this entry to ~/.claude/settings.json hooks.PreToolUse:
#   {
#     "matcher": "Read",
#     "hooks": [
#       { "type": "command", "command": "~/.claude/hooks/large-file-guard.sh" }
#     ]
#   }

set -euo pipefail

# Read tool input from stdin (Claude Code passes JSON)
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Resolve mode
MODE="${CLAUDE_USAGE_MODE:-PEAK}"
if [ -f "./.scratch/.mode" ]; then
  MODE=$(cat ./.scratch/.mode)
fi

if [ "$MODE" = "PEAK" ]; then
  CAP=200
else
  CAP=500
fi

# Skip if no file_path or file doesn't exist
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

LINES=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)

if [ "$LINES" -gt "$CAP" ]; then
  echo "BLOCKED: $FILE_PATH is $LINES lines, exceeds $MODE cap of $CAP. Delegate to Codex via cdx for slice + evidence." >&2
  exit 2
fi

exit 0
