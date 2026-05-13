# Poor Man AI Routing

> 💡 Think of this as a traffic controller for three AI tools. Start in Codex when you want work done on files, code, docs, automation, or your Obsidian wiki. Start in Claude when you want strategy, judgment, review, or polished thinking. Gemini is the scout that goes out to research the web, scan public sources, and generate images.

## TL;DR

- **Entrypoint wins**: the AI you start in leads that session.
- **Start with `cx`** when you want Codex to lead execution.
- **Start in Claude Code** when you want Claude to orchestrate.
- **Use Gemini through `gca`** for research, search, OSINT, Google ecosystem work, large public-source scans, multimodal discovery, and image generation.
- **Use Claude for judgment**: strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish, source/tool conflicts, high-stakes judgment, and similar cases.
- **Outputs go to Obsidian** using stage-and-confirm, duplicate checks, and wiki routing.

Public, generic, fork-and-customize. Brand placeholders live in `BRANDS.md`.

---

## What This Is

Poor Man AI Routing is a portable `~/.claude/` configuration that coordinates Codex CLI, Claude Code, and Gemini CLI without needing a complex platform.

It gives you:

- Entry-point-led routing rules for Codex-led and Claude-led sessions.
- Wrappers for Codex (`cx`, `cdx`) and Gemini (`gca`) with structured handoff formats.
- Time-aware PEAK/OFFPEAK modes for saving expensive context.
- A shared skill library for marketing, ops, security, creative work, Obsidian, and automation.
- Obsidian-first output routing for durable session logs, drafts, wiki updates, and source ingestion.
- A mandatory Claude judgment gate so Codex can execute fast without skipping strategy/review when it matters.

---

## Routing Model

### Start In Codex

Use `cx` when you want Codex to be the main operator.

Codex handles:

- Code and file edits
- Repo scans and refactors
- Tests, builds, scripts, and automation
- Documentation updates
- Obsidian wiki INGEST/LINT work
- Normal synthesis from local files and known context

Codex still routes out:

- To **Gemini** for discovery and current/source-backed information
- To **Claude** whenever judgment is needed

### Start In Claude

Use Claude Code when you want Claude to orchestrate.

Claude handles:

- Strategy
- Judgment calls
- Ambiguous tradeoffs
- Scoring rubrics
- Precision review
- Brand-facing final QA
- Brand voice/polish where quality matters
- Conflicts between sources, tools, files, or agents

Claude delegates:

- Execution-heavy work to Codex through `cdx`
- Discovery work to Gemini through `gca`

### Use Gemini

Use `gca` for:

- Web search and current facts
- News, rules, prices, standards, and market changes
- OSINT on public companies/domains/assets
- Google Analytics, Search Console, Drive, and NotebookLM-style tasks
- Large public-source scans
- Multimodal discovery
- Image generation with Gemini image models such as Nano Banana / Nano Banana Pro

Gemini returns compressed summaries, sources, quotes, and scratch artifacts. The session lead turns that into the final work.

---

## Judgment Rule

Claude must be used anytime judgment is needed, including:

- Strategy decisions
- Ambiguous tradeoffs
- Scoring rubrics
- Precision review
- Final QA for brand-facing work
- Brand voice/polish where quality matters
- Conflicts between sources/tool outputs
- High-stakes judgment
- Similar cases involving reputation, positioning, money, legal/medical/financial risk, or irreversible decisions

This applies even in Codex-led sessions. Codex leads execution, but Claude is the judgment specialist.

---

## Obsidian Output

Durable outputs route to the active Obsidian vault:

```text
C:\Users\moveb\iCloudDrive\iCloud~md~obsidian\nameless
```

Default delivery behavior:

- Draft non-trivial outputs to `./.scratch/obsidian-stage/<topic>-<date>.md`
- Show the intended vault destination before writing
- Run the pre-write duplicate check before creating new wiki pages
- Merge into canonical pages when duplicates are found
- Write session logs to `Wiki/Logs/Session-YYYY-MM-DD.md`

The Web Clipper inbox path inside the vault is:

```text
Sources/_inbox
```

---

## Install

### Prerequisites

1. Claude Code CLI installed and authenticated.
2. Node.js 20+.
3. Codex CLI and Gemini CLI installed.
4. PowerShell 7+, WSL2, Git Bash, Linux, or macOS shell.
5. Optional: `jq` for the large-file guard hook.

Install Codex and Gemini:

```bash
npm install -g @openai/codex
npm install -g @google/gemini-cli
```

Install this config:

```powershell
cd <repo-root>
.\INSTALL.ps1
```

Or from bash:

```bash
cd <repo-root>
chmod +x INSTALL.sh
./INSTALL.sh
```

The installer backs up the existing `~/.claude/`, copies this repo's `.claude/`, installs wrappers, updates PATH where possible, and verifies the CLIs.

---

## Daily Use

Start a Codex-led session:

```bash
ai-mode codex
cx
```

Start a Claude-led session:

```bash
ai-mode claude
claude
```

Run a scoped Codex worker task:

```bash
cdx "GOAL: Fix the failing test.
FILES IN SCOPE: src/
SUCCESS: tests pass.
RETURN: STATUS + SUMMARY + EVIDENCE."
```

Run Gemini research:

```bash
gca "TOPIC: Current competitor pricing for travel nurse staffing platforms.
SCOPE: United States, last 90 days.
WHAT I NEED:
  - pricing pages
  - plan names
  - source URLs
TIER: 2."
```

Save a session:

```bash
ai-session-save
```

Session exports are written locally to:

```text
~/Documents/workspace/AI Session Logs/
```

Connected Codex sessions also route closeout logs to Obsidian.

---

## File Structure

```text
~/.claude/
├── CLAUDE.md                  Claude-led orchestration and judgment rules
├── CODEX_PRIMARY.md           Codex-led session rules
├── AGENTS.md                  Codex orientation
├── GEMINI.md                  Gemini orientation
├── settings.json              Permissions, env, hooks
├── agents/
│   ├── orchestrator.md
│   ├── researcher.md
│   ├── builder.md
│   └── reviewer.md
├── bin/
│   ├── cdx.sh / cdx.ps1       Scoped Codex worker wrapper
│   ├── cx.sh / cx.ps1         Codex-led session launcher
│   ├── gca.sh / gca.ps1       Gemini wrapper
│   └── ai-mode.sh / ai-mode.ps1
├── hooks/
│   └── large-file-guard.sh
└── skills/                    Routing and domain SOPs
```

See `docs/PHASES.md` for the skill index.

---

## Customization

- Edit skills in `~/.claude/skills/<name>/SKILL.md`.
- Edit brand placeholders in `BRANDS.md`.
- Adjust PEAK/OFFPEAK thresholds in `skills/usage-mode-awareness/SKILL.md`.
- Enable hooks in `~/.claude/settings.json`.
- Re-run the installer after pulling repo updates.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `cx` or `cdx` not found | Open a new shell, check PATH, or re-run the installer. |
| `codex` not found | Install Codex CLI with `npm install -g @openai/codex`. |
| `gemini` not found | Install Gemini CLI with `npm install -g @google/gemini-cli`. |
| Unexpected routing behavior | Check the session entrypoint first; entrypoint wins over the mode file. |
| Claude was skipped for judgment | Tighten the prompt or routing rule: judgment-heavy work must escalate to Claude. |
| Obsidian output landed wrong | Check `obsidian-output-routing` and the staged file path before confirming writes. |
| Duplicate wiki pages | Run the pre-write duplicate check and merge into the canonical page. |

---

## License

This is your config. Use it however you want.
