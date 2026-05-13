# Poor Man AI Routing

A global entrypoint-led routing configuration for Codex, Claude Code, and Gemini CLI. The AI you start in leads the session: Codex leads `cx` sessions, Claude leads Claude Code sessions, Gemini handles discovery, and Claude is always used for judgment-heavy decisions.

Public, generic, fork-and-customize. Brand placeholders in `BRANDS.md`.

---

## TL;DR

- **Codex-started sessions** (`cx`) make Codex the main orchestrator/executor.
- **Claude-started sessions** make Claude the orchestrator/synthesizer.
- **Gemini CLI** handles research, search, OSINT, Google ecosystem work, large public-source scans, multimodal discovery, and image generation.
- **Claude judgment escalation is mandatory** for strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish where quality matters, conflicts between sources/tool outputs, high-stakes judgment, and similar cases.
- Use `ai-mode` as a preference/status helper; once a session starts, the entrypoint wins.

---

## What this gives you

- **Three-AI routing**: the entrypoint leads, Gemini researches, and Claude handles judgment escalation.
- **Entrypoint-led workflow**: start in `cx` when you want Codex to lead; start in Claude Code when you want Claude to orchestrate.
- **Tiered data access**: Tier 1 summary → Tier 2 slice → Tier 3 full read. Default Tier 1 in PEAK, Tier 2 in OFFPEAK.
- **Time-aware modes**: PEAK (5am-2pm EST weekdays, max delegation) and OFFPEAK (everything else, more direct work allowed).
- **Permission posture**: full auto inside the working dir, prompts only for writes outside.
- **33 skills**: routing, marketing, ops, security, creative, Obsidian knowledge management.
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

### Step 4: Start Work From The Right Entrypoint

Codex picks up `AGENTS.md` and `CODEX_PRIMARY.md`. Gemini picks up `GEMINI.md`. Claude picks up `CLAUDE.md` when you start in Claude Code or when a session escalates for judgment.

Start in Codex when you want Codex to lead execution:

```bash
ai-mode codex
cx
```

Start in Claude Code when you want Claude to orchestrate:

```bash
ai-mode claude
claude
```

You do not type `cx` before every prompt. Use it once to start a Codex-led session. The mode file is stored at `~/.claude/.ai-routing/mode` by default, but the session entrypoint is authoritative if it conflicts with the mode file.

---

## File structure

```
~/.claude/
├── CLAUDE.md                  Claude escalation/review rules
├── CODEX_PRIMARY.md           Codex-started session instructions
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
│   ├── cx.sh / cx.ps1         Codex-led session launcher
│   ├── gca.sh / gca.ps1       Gemini wrapper
│   └── ai-mode.sh / ai-mode.ps1 Global mode switcher
├── hooks/
│   └── large-file-guard.sh    Optional PreToolUse hook
└── skills/                    33 routing and domain SOPs
```

See `docs/PHASES.md` for the full skill index with descriptions.

---

## Quick reference

### Mode commands

- `/peak` → force PEAK posture
- `/offpeak` → force OFFPEAK posture
- `/auto` → re-detect from clock
- `ai-mode status` → show global routing mode
- `ai-mode codex` → prefer Codex-led sessions
- `ai-mode claude` → prefer Claude-led orchestration sessions
- `ai-session-save` → export the latest Codex session and route the closeout log to the Obsidian wiki

### Wrappers

```bash
# Codex (build / file ops)
cdx "GOAL: ...
FILES IN SCOPE: ...
SUCCESS: ...
RETURN: STATUS + SUMMARY + EVIDENCE."

# Codex-led session
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

When `ai-session-save` is entered inside a connected Codex session, the routing instructions treat it as a full closeout command:

- save the local raw, structured, and Obsidian-ready files
- read the generated `obsidian-ready.md`
- write the session log to `Wiki/Logs/Session-YYYY-MM-DD.md`
- return both the local folder path and the vault file path

If the vault path is unavailable, the local export still completes and the vault write is skipped with a clear note.

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
| Unexpected routing behavior | Check which entrypoint started the session, then run `ai-mode status` if the wrapper message looks stale. |
| `codex: command not found` | Codex not installed. See `docs/INSTALL_TOOLS.md`. |
| Hooks not firing | Hooks must be enabled per session in `settings.json`. Default is off. |
| Mode always PEAK | DST not being applied. Use `TZ="America/New_York"` env or `/auto` override. |
| Gemini auth fails | Re-auth: `gemini auth` and follow prompts. |
| Codex sandbox blocks writes | Confirm wrapper is calling `--sandbox workspace-write`; check `~/.claude/bin/cdx`. |

---

## License

This is your config. Use it however you want.
