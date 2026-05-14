# Poor Man AI Routing

A lightweight routing and memory system for using Codex, Claude, Gemini, and Obsidian together without building a full agent platform.

The core idea is simple:

```text
Entrypoint first, task route second, judgment gate third, wiki writeback last.
```

This repo is inspired by Andrej Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): raw sources go into an inbox, then an LLM turns them into a durable Markdown knowledge base that gets better over time.

## What This System Does

Poor Man AI Routing coordinates three AI tools plus a persistent Obsidian memory layer.

- **Codex** is the execution workbench.
- **Gemini** is the discovery and research layer.
- **Claude** is the judgment and review layer.
- **Codex fallback** covers Claude judgment duties when Claude usage is exhausted.
- **Obsidian** stores durable knowledge, source trails, project logs, and reusable context.

The result is a practical workflow where each tool does the work it is best suited for, while the wiki prevents repeated context loading.

## Quick Start

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

Run Gemini research:

```bash
gca "TOPIC: Current market research for [topic].
SCOPE: United States, last 90 days.
WHAT I NEED:
  - key findings
  - source URLs
  - contradictions
TIER: 2."
```

Run a scoped Codex worker task:

```bash
cdx "GOAL: Update this file.
FILES IN SCOPE: path/to/file.md
SUCCESS: requested section is updated.
RETURN: STATUS + SUMMARY + EVIDENCE."
```

Save a session:

```bash
ai-session-save
```

When the domain is known:

```bash
ai-session-save -Domain CROSS
```

## Core Routing Model

The entrypoint decides who leads first.

| Entrypoint | Lead | Use When |
|---|---|---|
| `cx` | Codex | File edits, code, docs, local workspace work, wiki ingest, normal synthesis |
| Claude Code | Claude | Strategy, judgment, scoring, final QA, brand polish |
| `gca` | Gemini | Search, current facts, OSINT, public-source scans, Google ecosystem work |
| `cdx` | Codex worker | A parent session needs a focused execution task |

The entrypoint wins over the mode file for the active session.

## Tool Responsibilities

### Codex

Use Codex for execution-heavy work:

- Local files.
- Code.
- Documentation.
- Repo scans.
- Scripts and automation.
- Obsidian ingest and lint work.
- Normal synthesis from local context.
- Project file updates.

### Gemini

Use Gemini for discovery:

- Current web research.
- Public-source verification.
- Competitor research.
- OSINT.
- Google ecosystem tasks.
- Large source scans.
- Multimodal discovery.

Gemini should return compressed findings, source links, and scratch artifacts to the session lead.

### Claude

Use Claude for judgment when available:

- Strategy decisions.
- Ambiguous tradeoffs.
- Scoring rubrics.
- Final brand-facing QA.
- Voice and polish.
- Ethics, equity, privacy, and data protection review.
- Source conflicts.
- High-stakes decisions.

## Claude Usage Fallback

When Claude usage is exhausted, unavailable, or blocked by quota, Codex temporarily covers Claude's judgment duties.

Use this exact label:

```text
Claude unavailable: Codex fallback review
```

Codex fallback must:

- Cite sources for factual claims.
- Mark assumptions clearly.
- Prefer conservative recommendations.
- Avoid overconfident strategy calls.
- Flag high-stakes output for later Claude review.
- Never claim Claude reviewed, approved, scored, or polished work unless Claude actually did it.

When Claude usage returns, use this exact label:

```text
Claude available: normal judgment escalation restored
```

Fallback does not change the entrypoint rule. A `cx` session stays Codex-led, Claude Code stays Claude-led when Claude is usable, `gca` stays Gemini discovery, and `cdx` stays a scoped Codex worker.

## LLM Wiki Protocol

The Obsidian vault is the durable memory system.

Raw sources go to:

```text
Sources/_inbox
```

Canonical knowledge goes under:

```text
Wiki/
```

Before finalizing non-trivial work:

1. Classify the domain.
2. Decide whether the output is a source, project update, campaign update, concept, synthesis, or log.
3. Stage wiki-ready drafts when needed.
4. Run duplicate checks before creating canonical pages.
5. Merge into the canonical page if one exists.
6. Update `Wiki/index.md` for new pages.
7. Append the operation to `Wiki/log.md`.
8. Return the relevant path to the user.

## Domain Codes

Domains keep work routed to the right project and brand context.

| Code | Meaning |
|---|---|
| `MNA` | MNA Healthcare work |
| `TGA` | The Green Anchor work |
| `PPH` | Pink Party House Co. client work |
| `SHL` | Side Hustle Labs |
| `TGAH` | TGA Health |
| `PERSONAL` | Personal projects, health, learning, travel |
| `CROSS` | Shared AI routing, wiki, automation, or infrastructure |

Use the most specific domain possible. Use `CROSS` only for shared system work or genuinely cross-domain artifacts.

## Quality Gate

Block and revise any output with a hard fail:

- Em dash.
- Unsupported factual claim.
- Invented source, quote, stat, pay rate, testimonial, credential, or certification.
- Unnecessary sensitive personal, candidate, facility, or patient data.
- Brand-facing output without Claude review or labeled Codex fallback review.
- New wiki page without duplicate check, index update, and log entry.

Score major outputs against:

- Human usefulness.
- Truth and evidence.
- Human voice.
- Ethics and equity.
- Privacy and data protection.
- Strategic fit.
- Craft by output type.
- Delivery hygiene.

## Project Layers

Project-specific systems can sit on top of this global routing layer.

Recommended project files:

```text
AGENTS.md
AI_ROUTING.yaml
agents/
skills/
company-docs/
```

Example project layer:

```text
workspace/mna/
├── AGENTS.md
├── AI_ROUTING.yaml
├── company-docs/
├── agents/
└── skills/
```

Project layers should:

- Point to their source-of-truth context.
- Define specialized agents.
- Define reusable SOP skills.
- Preserve the global entrypoint protocol.
- Preserve Claude fallback behavior.
- Write durable work back to the LLM Wiki with the correct domain.

## Standard Workflow

Use this pattern for most tasks:

1. Read the request.
2. Identify the entrypoint.
3. Identify the domain.
4. Check whether current research is needed.
5. Route discovery to Gemini if needed.
6. Route execution to Codex.
7. Route judgment to Claude if available.
8. If Claude is unavailable, run labeled Codex fallback review.
9. Apply quality gates.
10. Write back to Obsidian if the work is non-trivial.
11. Return concise results with paths and next steps.

## Install

Prerequisites:

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

## File Structure

```text
~/.claude/
├── CLAUDE.md
├── CODEX_PRIMARY.md
├── AGENTS.md
├── GEMINI.md
├── settings.json
├── agents/
│   ├── orchestrator.md
│   ├── researcher.md
│   ├── builder.md
│   └── reviewer.md
├── bin/
│   ├── cdx.sh / cdx.ps1
│   ├── cx.sh / cx.ps1
│   ├── gca.sh / gca.ps1
│   └── ai-mode.sh / ai-mode.ps1
├── hooks/
│   └── large-file-guard.sh
└── skills/
```

See `docs/PHASES.md` for the skill index.

## Customization

- Edit skills in `~/.claude/skills/<name>/SKILL.md`.
- Edit brand placeholders in `BRANDS.md`.
- Adjust PEAK/OFFPEAK thresholds in `skills/usage-mode-awareness/SKILL.md`.
- Enable hooks in `~/.claude/settings.json`.
- Re-run the installer after pulling repo updates.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `cx` or `cdx` not found | Open a new shell, check PATH, or re-run the installer. |
| `codex` not found | Install Codex CLI with `npm install -g @openai/codex`. |
| `gemini` not found | Install Gemini CLI with `npm install -g @google/gemini-cli`. |
| Unexpected routing behavior | Check the session entrypoint first. Entrypoint wins over the mode file. |
| Claude was skipped for judgment | If Claude is available, escalate to Claude. If Claude is unavailable, run `Claude unavailable: Codex fallback review`. |
| Obsidian output landed wrong | Check `obsidian-output-routing` and the staged file path before confirming writes. |
| Duplicate wiki pages | Run the pre-write duplicate check and merge into the canonical page. |

## License

This is your config. Use it however you want.
