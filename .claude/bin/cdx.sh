#!/usr/bin/env bash
# cdx — Codex CLI wrapper
# Pre-bakes flags for headless use, enforces handoff format, applies mode-aware compression.
#
# Usage:
#   cdx "GOAL: ... FILES: ... SUCCESS: ..."
#   cdx -m gpt-5 "<prompt>"      # override model
#   cdx --quiet "<prompt>"        # suppress meta output

set -euo pipefail

# Resolve mode
MODE="${CLAUDE_USAGE_MODE:-PEAK}"
if [ -f "./.scratch/.mode" ]; then
  MODE=$(cat ./.scratch/.mode)
fi

# Compression hint per mode
if [ "$MODE" = "PEAK" ]; then
  COMPRESS_HINT="Return STATUS + SUMMARY (max 8 bullets) + EVIDENCE (verbatim slices, max 10 lines each) + ARTIFACTS only. No prose dumps. Heavy output goes to ./.scratch/."
else
  COMPRESS_HINT="Return STATUS + SUMMARY (up to 12 bullets) + EVIDENCE + ARTIFACTS. Slices may be longer where decisions need cross-section context."
fi

# Ensure scratch dir exists
mkdir -p ./.scratch

# Parse args (preserve position for prompt)
EXTRA_ARGS=()
PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model|--profile|--config)
      EXTRA_ARGS+=("$1" "$2")
      shift 2
      ;;
    --quiet)
      EXTRA_ARGS+=("$1")
      shift
      ;;
    *)
      if [ -z "$PROMPT" ]; then
        PROMPT="$1"
      else
        EXTRA_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if [ -z "$PROMPT" ]; then
  echo "cdx: missing prompt" >&2
  echo "Usage: cdx \"<scoped task>\"" >&2
  exit 1
fi

# Wrap prompt with format enforcement
WRAPPED="$COMPRESS_HINT

MANDATORY OUTPUT FORMAT:
STATUS: done | blocked | needs decision
SUMMARY:
  - bullet
EVIDENCE:
  - path:line — \"verbatim slice\"
ARTIFACTS:
  - ./.scratch/...
DECISIONS NEEDED:
  - question

TASK:
$PROMPT"

# Invoke Codex headless
exec codex exec \
  --sandbox workspace-write \
  --skip-git-repo-check \
  "${EXTRA_ARGS[@]}" \
  "$WRAPPED"
