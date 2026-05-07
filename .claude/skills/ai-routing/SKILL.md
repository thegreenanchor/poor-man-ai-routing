---
name: ai-routing
description: The master routing decision tree. Use at the start of any non-trivial task to decide whether Codex handles directly, Gemini handles discovery, or Claude is needed for precision escalation.
---

# AI Routing

## Purpose

Decide WHO does the work. Codex is primary. Gemini researches. Claude is escalation-only for higher-thinking, rubrics, review, and precision.

## The decision tree

```
START
 │
 ├── Is the task normal execution, code, files, docs, tests, or automation? ──► Codex (`cx` / direct)
 │
 ├── Does it involve search, web, OSINT, social, Google ecosystem? ──► Gemini (gca)
 │       └── Then synthesize/execute ──► Codex
 │
 ├── Does it need strategy, scoring, rubric design, or precision review? ──► Claude escalation
 │
 ├── Does it span research AND build? ──► Codex orchestrates
 │       ├── Gemini gathers sources
 │       ├── Codex executes, edits, and synthesizes
 │       └── Claude reviews only if precision matters
 │
 ├── Does it need final brand-voice or code/content QA? ──► Claude reviewer escalation
 │
 └── Otherwise: classify the dominant phase, route accordingly.
```

## Routing matrix

| Task type | Primary | Why |
|---|---|---|
| Find current pricing for 5 competitors | Gemini | Web research |
| Refactor auth module across 12 files | Codex | Multi-file code work |
| Draft email sequence for WORK outreach | Codex → Claude review if final | Codex drafts, Claude polishes only if needed |
| Audit GA4 + GSC data, write report | Gemini → Codex → Claude review | Research + analysis + precision QA |
| Build n8n workflow from spec | Codex | Config + code |
| OSINT on a prospect company | Gemini | Public data discovery |
| Generate hero image for landing page | Gemini (Nano Banana) | Image gen |
| Fix a typo in WordPress page | Codex | Trivial execution |
| Migrate Mailchimp list to Mailcoach | Codex | File transformation + API calls |
| Write SOP doc for new process | Codex → Claude review if important | Codex drafts, Claude reviews precision |
| "What's trending in nurse staffing this week?" | Gemini | Search + monitoring |
| "Explain this stack trace" | Codex | Default workspace analysis |
| Resize 200 product images | Codex | Bulk file op |
| Write blog post from research notes | Gemini → Codex → Claude review if final | Two phases plus optional QA |

## When in doubt

Default to **Codex**. Use Gemini for discovery. Use Claude only when precision, judgment, or review justifies it.

## Hybrid task pattern (most common)

Many tasks are hybrid. The pattern:

1. **Plan** (Codex, brief): identify phases.
2. **Research phase** (Gemini): gather data, write to `./.scratch/`.
3. **Build/synthesis phase** (Codex): consume scratch, produce artifact.
4. **Review** (Claude reviewer, optional): if brand-facing, high-stakes, rubric-based, or precision-sensitive.

Each handoff uses the structured format from `claude-usage-protocol`.

## Common anti-patterns to avoid

- **Claude doing routine execution** when Codex exists.
- **Codex doing web research directly** when Gemini exists.
- **Claude reading raw research dumps** instead of Gemini's compressed summary.
- **Re-validating Codex's output** unless precision review requires it.
- **Skipping the wrappers** and calling `codex exec` or `gemini` directly. The wrappers enforce format and mode.

## Mode-aware routing

In **PEAK** mode: tighten thresholds. Anything that could stay in Codex/Gemini stays there. Claude only handles escalation.

In **OFFPEAK** mode: Claude can review more generously, but Codex still starts the work.

## Quick reference

- `cx` = Codex-primary session
- `cdx "..."` = scoped Codex worker task
- `gca "..."` = Gemini
- Claude escalation = review/precision only

If you can't decide in 5 seconds: keep it in Codex unless it is clearly research for Gemini or precision review for Claude.
