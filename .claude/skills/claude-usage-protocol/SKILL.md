---
name: claude-usage-protocol
description: The detailed token discipline SOP. Use at the start of any non-trivial work to apply the savings rules. Defines tiered access, scratchpad rules, when to spawn subagents, and the anti-patterns that burn Claude usage. Always relevant when planning a task.
---

# Claude Usage Protocol

## Principle

Claude burns the most expensive tokens in the system. Every line read, every tool result, every retry costs. The protocol is: **Claude touches as little as possible, as briefly as possible, only for decisions only Claude can make.**

Everything else gets pushed to Codex or Gemini, who return compressed results.

## The 8 rules

### Rule 1 — Default to delegate

- Tasks needing 3+ execution tool calls: hand to Codex.
- Tasks involving search, web fetch, OSINT, social, or large doc scan: hand to Gemini.
- Claude executes directly only when delegation overhead exceeds the work itself.

### Rule 2 — Three access tiers

**Tier 1 — Summary** (default for discovery)
Worker compresses to bullets. Use when Claude needs to know what's in there, not the literal contents.

**Tier 2 — Targeted slice** (default for execution)
Worker returns line numbers + verbatim slice with surrounding context. Claude reads only the slice. Use for: edits, debugging, verification, fact-checking.

**Tier 3 — Full read** (rare, intentional)
Claude reads the whole file. Allowed when: file < line cap, or work needs whole-file context. Document the override in the response.

**Locate-then-load**: ask the worker to find the relevant section first, read only that slice.

### Rule 3 — Compressed handoff format

Codex/Gemini return:
```
STATUS: done | blocked | needs decision
SUMMARY: ≤10 bullets
EVIDENCE: file:line — "verbatim slice"
ARTIFACTS: ./.scratch/...
DECISIONS NEEDED: questions
```

The `EVIDENCE` block carries the literal bytes Claude needs. No re-read required.

### Rule 4 — Scratchpad discipline

- Heavy outputs write to `./.scratch/` in the working dir.
- Claude reads scratch files only when synthesis is needed, not as a default step.
- Scratch persists across sessions.

### Rule 5 — No redundant verification

- If Codex says tests pass, do not re-run.
- If Gemini returns sources with URLs, do not re-fetch unless user flags suspicion.
- If a subagent reports done, trust the STATUS unless EVIDENCE contradicts.

### Rule 6 — Subagent-first for multi-step work

- Tasks needing 5+ tool calls: spawn a subagent.
- Subagents have their own context window. Main thread stays clean.
- Subagent returns the same compressed format.

### Rule 7 — Stop-talking

- Final reply: deliverable + max 3 sentences.
- No process recaps ("First I did X, then Y...").
- User asked for output, not narration.

### Rule 8 — Token-cheap defaults

- Use Haiku-tier reasoning where the response is mechanical.
- Reserve top-tier reasoning for routing decisions and final synthesis.

## Line caps and file caps

| Mode | Max lines per file Claude reads | Max files Claude reads in a row |
|---|---|---|
| PEAK | 200 | 2 |
| OFFPEAK | 500 | 4 |

Beyond these: delegate. No exceptions unless a Tier 3 override is justified in the response.

## Tool-specific rules

**Edit operations** — Codex returns the exact `old_string` (with surrounding context for uniqueness) and the proposed `new_string`. Claude calls Edit. No re-read needed.

**Spreadsheets** — Codex slices via the `xlsx` skill. Claude never opens the file directly.

**Code debugging** — Codex returns: error trace + 30 lines around the error site, verbatim. Claude diagnoses from the slice.

**Contracts / verbatim-sensitive docs** — Gemini extracts exact clauses by topic. Claude reviews clauses, not the full doc.

**Search results** — Gemini returns title + URL + verbatim excerpt. Never paraphrased.

## Anti-patterns

These all waste Claude usage. Avoid:

- **Reading a full file to find one function.** Use Grep or ask Codex.
- **Reading multiple files to "get oriented."** Spawn `orchestrator` subagent.
- **Fetching URLs directly.** Always Gemini.
- **Re-summarizing a Codex/Gemini summary.** Pass it through.
- **Running long bash sequences in main thread.** Delegate to builder subagent.
- **Padding final replies with "I hope this helps" / "Let me know if..."** Cut.
- **Re-validating worker output** with new tool calls when EVIDENCE already covers it.
- **Reading scratch files as a default first step.** Synthesize from summaries; open scratch only if needed.

## Override patterns

Claude can break rules when:

- File is under the cap → Tier 3 read is fine.
- A previous Tier 2 slice was insufficient and the work needs cross-section context.
- The user explicitly says "read it yourself" or "do it directly."
- Overhead of delegation > the work.

Document the override in the response: "Reading directly because [reason]."

## Pre-work checklist (run mentally before any task)

1. What's the dominant domain? (Code, research, write, plan)
2. Who should execute? (Claude direct, cdx, gca, subagent)
3. What tier do I need? (1 default, 2 if exact bytes matter)
4. What's the success criteria for the worker?
5. What's the format of the return?

If you can't answer all 5 in 10 seconds, the task needs more decomposition first.

## Usage savings, ranked by leverage

1. **Use Codex/Gemini for everything possible** (~70% savings on execution-heavy work).
2. **Apply line caps + Tier 1 default** (~30% savings on read-heavy work).
3. **Spawn subagents for multi-step** (~40% savings on complex tasks; main thread stays cheap).
4. **Tighten final reply** (~10% savings, every reply).
5. **PEAK mode in business hours** (~20% on top of all the above).
