---
name: ai-routing
description: The master routing decision tree. Use at the start of any non-trivial task to decide which session entrypoint leads and which specialist handles each part (Claude judgment, Codex execution, Gemini discovery, or subagents). Defines splits for hybrid tasks and mandatory Claude judgment escalation.
---

# AI Routing

## Purpose

Decide who leads and who handles each part. The session entrypoint leads: `cx` means Codex-led, Claude Code means Claude-led. Gemini is the discovery layer. Claude is mandatory for judgment-heavy decisions.

All non-trivial work must end in an Obsidian LLM Wiki writeback. The session lead is responsible for making work durable in the correct domain even when another CLI AI performed the work.

## Entrypoint rule

- Start in `cx`: Codex is the primary orchestrator/executor for the session.
- Start in Claude Code: Claude is the orchestrator/synthesizer for the session.
- Call `cdx`: Codex is a scoped worker for the current parent.
- Call `gca`: Gemini handles discovery/research.
- If the mode file conflicts with the entrypoint, the entrypoint wins.

## Mandatory Claude judgment escalation

Use Claude whenever the task involves strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish where quality matters, conflicts between sources/tool outputs, high-stakes judgment, or similar cases.

## Claude usage fallback

Entrypoint protocol is evaluated first. Claude availability is evaluated second.

- If Claude is available, judgment-heavy work routes to Claude as usual.
- If Claude usage is exhausted, unavailable, or blocked by quota, the session lead does not stop by default.
- In that state, Codex temporarily performs the judgment pass and labels it exactly: `Claude unavailable: Codex fallback review`.
- Codex fallback review must use stricter evidence and quality standards than ordinary execution: cite sources for factual claims, mark assumptions, prefer conservative recommendations, and flag high-stakes decisions for later Claude review.
- Codex must not claim that Claude reviewed, approved, scored, or polished anything unless Claude actually did the work.
- When Claude usage returns, restore normal judgment escalation and label the state: `Claude available: normal judgment escalation restored`.

Fallback does not change the entrypoint rule. A `cx` session remains Codex-led, a Claude Code session remains Claude-led when Claude is usable, `gca` remains Gemini discovery, and `cdx` remains a scoped Codex worker.

## Mandatory wiki writeback

Before finalizing any non-trivial task:
1. Classify domain: `MNA`, `TGA`, `PPH`, `SHL`, `TGAH`, `PERSONAL`, or `CROSS`.
2. Update the canonical page:
   - `Wiki/Projects/<project>.md` for project/task work
   - `Wiki/Campaigns/<campaign>.md` for campaign/content calendar work
   - `Wiki/Content/<item>.md` for individual content
   - `Wiki/Synthesis/Work Queue.md` when the destination is genuinely unclear
3. Record task status, next action, decisions, and artifacts.
4. Append the operation to `Wiki/log.md`.

This applies to Codex, Claude, Gemini, and any subagent. Session logs do not replace project/task logging.

## The decision tree

```
START
 │
 ├── Which entrypoint started the session?
 │       ├── cx ──► Codex leads execution and final response
 │       └── Claude Code ──► Claude leads orchestration and synthesis
 │
 ├── Does the task need judgment?
 │       ├── Claude available ──► Claude
 │       └── Claude unavailable ──► Codex fallback review, clearly labeled
 │
 ├── Does it involve search, web, OSINT, social, Google ecosystem? ──► Gemini (gca)
 │       └── Then return to the session lead; escalate to Claude if judgment is needed
 │
 ├── Does it involve writing/editing code, files, configs at scale? ──► Codex (cx lead or cdx worker)
 │       └── Then validate in Codex; escalate to Claude if judgment is needed
 │
 ├── Does it span research AND build? ──► session lead coordinates Gemini + Codex
 │
 ├── Does it need final brand-voice polish? ──► Claude
 │
 └── Otherwise: session lead handles it directly.
```

## Routing matrix

| Task type | Primary | Why |
|---|---|---|
| Find current pricing for 5 competitors | Gemini | Web research |
| Refactor auth module across 12 files | Codex | Multi-file code work |
| Draft email sequence for WORK outreach | Session lead → Claude review | Brand voice + judgment |
| Audit GA4 + GSC data, write report | Gemini → Codex/session lead → Claude if judgment needed | Research + analysis + synthesis |
| Build n8n workflow from spec | Codex | Config + code |
| OSINT on a prospect company | Gemini | Public data discovery |
| Generate hero image for landing page | Gemini (Nano Banana) | Image gen |
| Fix a typo in WordPress page | Session lead | Trivial single edit |
| Migrate Mailchimp list to Mailcoach | Codex | File transformation + API calls |
| Write SOP doc for new process | Session lead → Claude if strategic/brand-sensitive | Structure plus possible judgment |
| "What's trending in nurse staffing this week?" | Gemini | Search + monitoring |
| "Explain this stack trace" | Session lead or Codex | Depends on repo context |
| Resize 200 product images | Codex | Bulk file op |
| Write blog post from research notes | Gemini → session lead → Claude polish if quality matters | Two phases plus judgment gate |

## When in doubt

Default to the session lead for ordinary work, Gemini for discovery, Codex for execution-heavy work, and Claude for judgment. If Claude is unavailable, use the labeled Codex fallback review until Claude usage returns.

## Hybrid task pattern (most common)

Many tasks are hybrid. The pattern:

1. **Plan** (session lead): identify phases.
2. **Research phase** (Gemini): gather data, write to `./.scratch/`.
3. **Build phase** (Codex): consume scratch, produce artifact.
4. **Synthesis** (session lead): assemble the deliverable.
5. **Judgment/review** (Claude when available, otherwise labeled Codex fallback review): required when any judgment trigger applies.
6. **Wiki writeback** (session lead): update project/campaign/content/Work Queue page and `Wiki/log.md`.

Each handoff uses the structured format from `claude-usage-protocol`.

## Common anti-patterns to avoid

- **Claude doing the search** when Gemini exists. Costs more, gives less.
- **Claude reading raw research dumps** instead of Gemini's compressed summary.
- **Skipping the judgment gate**. Codex can draft and synthesize, but Claude reviews when judgment or brand quality matters. If Claude is unavailable, Codex must run the labeled fallback review instead of silently skipping review.
- **Re-validating Codex's output** by re-reading files Codex already showed in EVIDENCE.
- **Skipping the wrappers** and calling `codex exec` or `gemini` directly. The wrappers enforce format and mode.

## Mode-aware routing

In **PEAK** mode: tighten thresholds. Anything that could go to Codex/Gemini goes there. Subagent spawn at 3+ tool calls.

In **OFFPEAK** mode: Claude can take more directly. Subagent spawn at 5+ tool calls.

## Quick reference

- `cx` = Codex-led session
- `cdx "..."` = scoped Codex worker
- `gca "..."` = Gemini
- `Task` tool with subagent_type = subagent
- Claude Code = Claude-led session and judgment escalation
- Claude unavailable = Codex fallback review, clearly labeled

If you can't decide in 5 seconds: delegate.
