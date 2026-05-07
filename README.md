# Poor Man AI Routing

A global Codex-primary routing configuration that keeps Codex as the daily workbench, routes research to Gemini CLI, and reserves Claude Code for higher-thinking review, scoring rubrics, strategy, and precision QA.

Public, generic, fork-and-customize. Brand placeholders in `BRANDS.md`.

---

## TL;DR

- **Codex CLI** is where work starts: code, files, docs, scripts, builds, verification, and normal synthesis.
- **Gemini CLI** handles research, search, OSINT, and source gathering.
- **Claude Code** handles escalation: higher-thinking tasks, scoring rubrics, content/code review, strategy, and final QA.
- Daily start: `ai-mode codex`, then `cx`.
- Use `ai-mode claude` only when you intentionally want Claude-first escalation/review.

---

## What this gives you

- **Three-AI routing**: Codex starts and executes. Gemini researches. Claude reviews and handles precision escalation.
- **Codex-primary workflow**: switch globally to Codex with `ai-mode codex` and start work with `cx`.
- **Tiered data access**: Tier 1 summary → Tier 2 slice → Tier 3 full read. Default Tier 1 in PEAK, Tier 2 in OFFPEAK.
- **Time-aware modes**: PEAK (5am-2pm EST weekdays, max delegation) and OFFPEAK (everything else, more direct work allowed).
- **Permission posture**: full auto inside the working dir, prompts only for writes outside.
- **28 skills**: routing, marketing, ops, security, creative.
- **Subagents**: researcher, builder, reviewer, plus Claude-side orchestrator for escalation planning.
- **Bash + PowerShell wrappers**: `cdx` (Codex) and `gca` (Gemini) with format enforcement baked in.

---

## Install

### Prerequisites

1. **Claude Code CLI** installed and authed.
2. **Node.js 20+** (for Codex CLI and Gemini CLI installs).
3. **WSL2 with bash** OR **PowerShell 7+** OR **Git Bash**.
4. **`jq`** (for the optional large-file-guard hook).

### Step 1: Install Codex CLI and Gemini CLI

See `docs/INSTALL_TOOLS.md` for full instructions. Quick version:

```bash
# Codex CLI
npm install -g @openai/codex

# Gemini CLI
npm install -g @google/gemini-cli
```

Then authenticate each per their docs.

### Step 2: Install this config

**Windows PowerShell** (recommended for native Windows):

```powershell
cd <repo-root>
.\INSTALL.ps1
```

**WSL / Git Bash / Linux / Mac**:

```bash
cd <repo-root>
chmod +x INSTALL.sh
./INSTALL.sh
```

The installer:
1. Backs up any existing `~/.claude/` to `~/.claude.bak.<timestamp>/`
2. Copies this `.claude/` directory to `~/.claude/`
3. Makes the wrappers in `~/.claude/bin/` executable
4. Adds `~/.claude/bin/` to your PATH (if not already)
5. Verifies Codex and Gemini are installed and reachable

### Step 3: Verify

In a new terminal:

```bash
which cdx        # should print ~/.claude/bin/cdx
which cx         # should print ~/.claude/bin/cx
which gca        # should print ~/.claude/bin/gca
codex --version  # should print Codex version
gemini --version # should print Gemini version
ai-mode status   # should print claude or codex

# Smoke test the wrappers (these will actually call the LLMs)
cdx "GOAL: Print 'hello from codex' and exit. RETURN: STATUS only."
cx "Inspect this folder and report the current routing mode. Do not edit files."
gca "TOPIC: What is 2+2? TIER: 1."
```

### Step 4: Start Codex-primary work

Codex picks up `AGENTS.md` and `CODEX_PRIMARY.md`. Gemini picks up `GEMINI.md`. Claude picks up `CLAUDE.md` when you deliberately escalate.

Set Codex as the global routing mode:

```bash
ai-mode codex
```

Then start work:

```bash
cx
```

You do not type `cx` before every prompt. Use it once to start a new Codex-primary session. When you intentionally need Claude-first review/escalation:

```bash
ai-mode claude
```

The mode is stored at `~/.claude/.ai-routing/mode` by default. Set `AI_ROUTING_HOME` if you want to keep that state somewhere else.

---

## File structure

```
~/.claude/
├── CLAUDE.md                  Claude escalation/review rules
├── CODEX_PRIMARY.md           Codex-primary daily routing instructions
├── settings.json              Permissions, env, hooks
├── AGENTS.md                  Codex orientation
├── GEMINI.md                  Gemini orientation
├── agents/
│   ├── orchestrator.md        Claude-side escalation planner
│   ├── researcher.md          Routes to Gemini
│   ├── builder.md             Routes to Codex
│   └── reviewer.md            Precision review / final QA check
├── bin/
│   ├── cdx.sh / cdx.ps1       Codex wrapper
│   ├── cx.sh / cx.ps1         Codex-primary launcher
│   ├── gca.sh / gca.ps1       Gemini wrapper
│   └── ai-mode.sh / ai-mode.ps1 Global mode switcher
├── hooks/
│   └── large-file-guard.sh    Optional PreToolUse hook
└── skills/                    25 domain SOPs
```

See `docs/PHASES.md` for the full skill index with descriptions.

---

## Quick reference

### Mode commands

- `/peak` → force PEAK posture
- `/offpeak` → force OFFPEAK posture
- `/auto` → re-detect from clock
- `ai-mode status` → show global routing mode
- `ai-mode codex` → switch to Codex-primary mode
- `ai-mode claude` → switch to Claude escalation/review mode
- `ai-session-save` → export the latest Codex session into raw, structured, and Notion-ready logs

### Wrappers

```bash
# Codex (build / file ops)
cdx "GOAL: ...
FILES IN SCOPE: ...
SUCCESS: ...
RETURN: STATUS + SUMMARY + EVIDENCE."

# Codex-primary daily mode
ai-mode codex
cx
cx "Fix the failing tests and summarize what changed."

# End-only session logging
ai-session-save
ai-session-save -Title "Routing system update"

# Gemini (search / OSINT / large doc scan)
gca "TOPIC: ...
SCOPE: ...
WHAT I NEED: ...
TIER: 1 or 2."
```

Session logs are written to:

```text
~/Documents/workspace/AI Session Logs/
```

### Subagents

Spawn via Claude Code's Task tool or by mentioning the subagent in the prompt.

### Mode detection

Run at session start (Claude Code does this automatically per `CLAUDE.md`):

```bash
TZ="America/New_York" date +"%H %A"
```

---

## Customization

Each skill is a markdown file. Edit `~/.claude/skills/<name>/SKILL.md` to refine. Changes take effect on next session.

To add a skill: create a new directory under `~/.claude/skills/` with a `SKILL.md` containing YAML frontmatter (`name`, `description`).

To adjust thresholds: edit `~/.claude/skills/usage-mode-awareness/SKILL.md`.

To enable the large-file-guard hook: edit `~/.claude/settings.json` `hooks.PreToolUse` to include the script.

---

## What's NOT in this repo

These are already provided by Anthropic skills (do not duplicate):
- `docx`, `pptx`, `xlsx`, `pdf` — Office document creation
- `canvas-design` — visual design
- `internal-comms` — internal communications
- `ops-analyst` — operational analysis
- `brand-guidelines` — Anthropic brand assets

---

## Updating

This system is intentionally modular. To update:
1. Pull the latest version of this repo.
2. Re-run `INSTALL.sh` or `INSTALL.ps1`. It backs up your current config first.
3. Re-apply any custom edits from your backup.

For partial updates (one skill), just copy that skill's directory.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `cdx: command not found` | PATH not picked up. Open new shell or `source ~/.bashrc` / `~/.zshrc`. |
| `cx: command not found` | Re-run the installer and open a new shell; verify `~/.claude/bin` is on PATH. |
| Wrong routing mode | Run `ai-mode status`, then `ai-mode codex` or `ai-mode claude`. |
| `codex: command not found` | Codex not installed. See `docs/INSTALL_TOOLS.md`. |
| Hooks not firing | Hooks must be enabled per session in `settings.json`. Default is off. |
| Mode always PEAK | DST not being applied. Use `TZ="America/New_York"` env or `/auto` override. |
| Gemini auth fails | Re-auth: `gemini auth` and follow prompts. |
| Codex sandbox blocks writes | Confirm wrapper is calling `--sandbox workspace-write`; check `~/.claude/bin/cdx`. |

---

## License

This is your config. Use it however you want.
