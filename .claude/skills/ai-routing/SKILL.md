---
name: ai-routing
description: The master routing decision tree. Use at the start of any non-trivial task to decide which agent (Claude direct, Codex via cdx, Gemini via gca, or a subagent) handles which part. Defines splits for hybrid tasks. Trigger when planning multi-step work, when unsure who should execute, or when a task spans research + build + synthesis.
---

# AI Routing

## Purpose

Decide WHO does the work. Claude (orchestrator), Codex (builder), Gemini (researcher), or a subagent.

## The decision tree

```
START
 │
 ├── Is the task pure conversation, lookup, or single small read? ──► Claude direct
 │
 ├── Does it involve search, web, OSINT, social, Google ecosystem? ──► Gemini (gca)
 │       └── Then synthesize ──► Claude direct
 │
 ├── Does it involve writing/editing code, files, configs at scale? ──► Codex (cdx)
 │       └── Then validate ──► Claude direct
 │
 ├── Does it span research AND build? ──► spawn `orchestrator` subagent
 │       ├── orchestrator spawns `researcher` (Gemini)
 │       ├── orchestrator spawns `builder` (Codex)
 │       └── orchestrator synthesizes
 │
 ├── Does it need final brand-voice polish? ──► spawn `reviewer` subagent
 │
 └── Otherwise: classify the dominant phase, route accordingly.
```

## Routing matrix

| Task type | Primary | Why |
|---|---|---|
| Find current pricing for 5 competitors | Gemini | Web research |
| Refactor auth module across 12 files | Codex | Multi-file code work |
| Draft email sequence for WORK outreach | Claude | Brand voice + judgment |
| Audit GA4 + GSC data, write report | Gemini → Codex → Claude | Research + analysis + synthesis |
| Build n8n workflow from spec | Codex | Config + code |
| OSINT on a prospect company | Gemini | Public data discovery |
| Generate hero image for landing page | Gemini (Nano Banana) | Image gen |
| Fix a typo in WordPress page | Claude direct | Trivial single edit |
| Migrate Mailchimp list to Mailcoach | Codex | File transformation + API calls |
| Write SOP doc for new process | Claude | Brand voice + structure |
| "What's trending in nurse staffing this week?" | Gemini | Search + monitoring |
| "Explain this stack trace" | Claude direct (small) or Codex (if needs repo context) | Depends on scope |
| Resize 200 product images | Codex | Bulk file op |
| Write blog post from research notes | Gemini (research) → Claude (writing) | Two phases |

## When in doubt

Default to **Codex/Gemini delegation**. The cost of an extra wrapper call is trivial compared to a long Claude session.

## Hybrid task pattern (most common)

Many tasks are hybrid. The pattern:

1. **Plan** (Claude, brief): identify phases.
2. **Research phase** (Gemini): gather data, write to `./.scratch/`.
3. **Build phase** (Codex): consume scratch, produce artifact.
4. **Synthesis** (Claude): final polish, brand voice, deliverable shaping.
5. **Review** (reviewer subagent, optional): if brand-facing.

Each handoff uses the structured format from `claude-usage-protocol`.

## Common anti-patterns to avoid

- **Claude doing the search** when Gemini exists. Costs more, gives less.
- **Claude reading raw research dumps** instead of Gemini's compressed summary.
- **Codex writing prose deliverables**. Codex builds; Claude writes.
- **Re-validating Codex's output** by re-reading files Codex already showed in EVIDENCE.
- **Skipping the wrappers** and calling `codex exec` or `gemini` directly. The wrappers enforce format and mode.

## Mode-aware routing

In **PEAK** mode: tighten thresholds. Anything that could go to Codex/Gemini goes there. Subagent spawn at 3+ tool calls.

In **OFFPEAK** mode: Claude can take more directly. Subagent spawn at 5+ tool calls.

## Quick reference

- `cdx "..."` = Codex
- `gca "..."` = Gemini
- `Task` tool with subagent_type = subagent
- Direct = Claude does it

If you can't decide in 5 seconds: delegate.
