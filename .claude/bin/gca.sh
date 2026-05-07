#!/usr/bin/env bash
# gca — Gemini CLI wrapper
# Headless invocation, enforces handoff format, mode-aware compression.
#
# Usage:
#   gca "<question or task>"
#   gca -m gemini-2.5-pro "<prompt>"

set -euo pipefail

MODE="${CLAUDE_USAGE_MODE:-PEAK}"
if [ -f "./.scratch/.mode" ]; then
  MODE=$(cat ./.scratch/.mode)
fi

if [ "$MODE" = "PEAK" ]; then
  COMPRESS_HINT="Top 5 sources max. Verbatim quotes max 20 words. SUMMARY max 8 bullets. Full dump goes to ./.scratch/research-{topic}-$(date +%Y-%m-%d).md."
else
  COMPRESS_HINT="Top 8 sources. Verbatim quotes max 25 words. SUMMARY up to 12 bullets. Full dump still goes to ./.scratch/."
fi

mkdir -p ./.scratch

EXTRA_ARGS=()
PROMPT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      EXTRA_ARGS+=("$1" "$2")
      shift 2
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
  echo "gca: missing prompt" >&2
  echo "Usage: gca \"<question>\"" >&2
  exit 1
fi

WRAPPED="$COMPRESS_HINT

MANDATORY OUTPUT FORMAT:
STATUS: done | blocked
SUMMARY:
  - bullet
SOURCES:
  - title — URL — date
EVIDENCE:
  - URL — \"verbatim quote\"
ARTIFACTS:
  - ./.scratch/research-...md
DECISIONS NEEDED:
  - question

TASK:
$PROMPT"

exec gemini --yolo --skip-trust "${EXTRA_ARGS[@]}" -p "$WRAPPED"
