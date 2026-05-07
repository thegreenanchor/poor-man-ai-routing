# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), versioning follows
[SemVer](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-07

### Added

- Initial public release.
- Three-AI routing architecture: Claude (orchestrator), Codex CLI (workhorse),
  Gemini CLI (research/content).
- 4 subagents: `orchestrator`, `researcher`, `builder`, `reviewer`.
- 28 domain skills across routing, marketing, ops, security, and creative.
- Time-aware mode system (PEAK / OFFPEAK) with automatic detection.
- Three-tier data access (summary / slice / full read) with mode-aware caps.
- Compressed handoff format enforced by `cdx` and `gca` wrappers.
- Stage-and-confirm Notion delivery via the `notion-output-routing` skill.
- Codex-primary backup mode: `ai-mode codex` and `cx` wrappers for use during
  Claude usage outages.
- Cross-platform install scripts (`INSTALL.ps1`, `INSTALL.sh`).
- Optional PreToolUse hook (`large-file-guard.sh`) for hard line caps.
- Brand customization template at `BRANDS.md`.
- MIT license.

### Notes

- Brand and color codes (`MAIN`, `WORK`, `SIDE`, `OTHER`) are placeholders.
  Edit `BRANDS.md` and propagate the codes through `.claude/AGENTS.md`,
  `.claude/GEMINI.md`, and `.claude/CLAUDE.md` as needed.
- Notion database IDs in `notion-output-routing` are placeholders. Replace
  `<YOUR_*_DB_ID>` markers with your own IDs after connecting the Notion MCP.

[1.0.0]: https://github.com/thegreenanchor/poor-man-ai-routing/releases/tag/v1.0.0
