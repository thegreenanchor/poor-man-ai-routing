---
name: codex-handoff
description: How to use Codex as the primary workbench or as a scoped worker via `cdx`. Defines the scoped-task template, success criteria patterns, and escalation boundaries.
---

# Codex Handoff

## When to use Codex

- Codex-led sessions via `cx`.
- Writing new code (any language).
- Editing existing code (single file or repo-wide).
- Multi-file scans (find all callers, find all references, audit imports).
- Generating boilerplate, scaffolding, configs.
- Running test suites, linters, build systems.
- File transformations (CSV reshape, JSON migrations, log parsing).
- Building automations (n8n, Zapier exports, scripts).

## When NOT to use Codex

- Web research → Gemini.
- Image generation → Gemini (Nano Banana).
- Final brand-voice polish when precision matters → Claude review.
- Strategy decisions, ambiguous tradeoffs, scoring rubrics, precision review, final QA for brand-facing work, brand voice/polish where quality matters, conflicts between sources/tool outputs, high-stakes judgment, and similar cases → Claude escalation.
- Web research, OSINT, Google ecosystem, large public-source lookups → Gemini.

## The scoped-task template

Every Codex prompt follows this shape. Skip a field only if it's truly N/A.

```
GOAL: [one sentence, observable outcome]
FILES IN SCOPE: [exact paths, glob patterns, or "any in src/"]
SUCCESS CRITERIA:
  - [testable assertion 1]
  - [testable assertion 2]
CONSTRAINTS:
  - language/framework
  - style guide
  - things to NOT touch
RETURN: STATUS + SUMMARY + EVIDENCE (verbatim diffs, max 10 lines each) + ARTIFACTS.
```

## Calling Codex

```bash
# Codex-led session
cx

# Scoped worker task
cdx "GOAL: ... FILES: ... SUCCESS: ... CONSTRAINTS: ... RETURN: ..."
```

The wrapper auto-prepends the mode-aware compression hint and format enforcer. You write the GOAL block; the wrapper handles the rest.

## Examples by task type

### Single-file edit

```
cdx "GOAL: Fix off-by-one in pagination loop returning N-1 items.
FILES IN SCOPE: src/api/list.ts
SUCCESS:
  - Returns N items per page
  - All existing tests pass
CONSTRAINTS: TypeScript, do not change function signature.
RETURN: STATUS + EVIDENCE diff."
```

### Multi-file refactor

```
cdx "GOAL: Extract shared input validation into src/lib/validators.ts.
FILES IN SCOPE: src/handlers/*.ts
SUCCESS:
  - Validators module exports the 6 reused functions
  - All handlers import from it
  - No duplication remains in handlers
  - Existing tests pass
CONSTRAINTS: TypeScript, no behavior change.
RETURN: STATUS + SUMMARY listing files touched + EVIDENCE for the new module."
```

### Repo-wide scan (no edits)

```
cdx "GOAL: List every call site of the deprecated /v1/users endpoint.
FILES IN SCOPE: entire repo
SUCCESS: complete list with file:line and surrounding 3 lines.
CONSTRAINTS: read-only. Do not modify any files.
RETURN: STATUS + SUMMARY with the count + EVIDENCE block listing all sites."
```

### Generate from spec

```
cdx "GOAL: Build a CLI tool per spec at ./.scratch/spec.md.
FILES IN SCOPE: new repo at ./out/clitool/
SUCCESS:
  - Implements all commands in spec
  - Has README, package.json, tests
  - npm test passes
CONSTRAINTS: Node 20, commander.js for CLI parsing.
RETURN: STATUS + SUMMARY + ARTIFACTS (path to repo)."
```

### File transformation

```
cdx "GOAL: Reshape ./.scratch/leads.csv to match HubSpot import schema.
FILES IN SCOPE: ./.scratch/leads.csv (input), ./.scratch/leads-hubspot.csv (output)
SUCCESS:
  - Output has columns: First Name, Last Name, Email, Company, Phone, Lead Source
  - Email column validated, invalid rows logged to ./.scratch/invalid-leads.csv
CONSTRAINTS: Python preferred, pandas OK.
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

## Reading Codex's output

When Codex returns, read in this order:

1. **STATUS** first. If `blocked` or `needs decision`, stop and decide.
2. **SUMMARY** bullets. Confirm scope was met.
3. **EVIDENCE** only if you need to verify a specific change.
4. **ARTIFACTS** path only if synthesis or further work needs it.

Do NOT re-read files Codex already showed in EVIDENCE. The slice is canonical.

## Anti-patterns

- **Vague goals**: "Improve the API." Codex won't know when it's done. Always observable outcome.
- **No success criteria**: Codex guesses and you re-prompt.
- **Multiple unrelated goals in one call**: split into two calls.
- **Sending raw user prose**: translate it into the template first. Faster output, less rework.
- **Asking Codex to fetch URLs**: route to Gemini, pass results in.
- **Skipping Claude review for judgment-heavy work**: escalate for strategy, ambiguous tradeoffs, scoring, precision review, final QA, brand polish, source/tool conflicts, and high-stakes judgment.

## Mode awareness

PEAK: keep prompts tight, single goal per call, ask for shorter EVIDENCE slices.
OFFPEAK: can stack 2-3 related goals if they share file scope.

## Hand-back pattern (for subagents)

When a `builder` subagent finishes, return:

```
STATUS: done
SUMMARY:
  - [from Codex SUMMARY, verbatim]
EVIDENCE:
  - [from Codex EVIDENCE, verbatim]
ARTIFACTS:
  - [from Codex ARTIFACTS, verbatim]
NEXT: [what the parent should do, if obvious]
```

Do not re-summarize. Pass through.
