---
name: obsidian-output-routing
description: Routes every non-trivial deliverable to the correct destination in the Obsidian wiki vault. Defines the routing matrix, page type templates, stage-and-confirm protocol, pre-write duplicate checks, and brand tagging rules. Use whenever Claude produces an output that should be written to the vault (research, drafts, reports, SOPs, project deliverables, captures, session logs). Always consult before any vault write.
---

# Obsidian Output Routing

## Vault Root
`C:\Users\moveb\iCloudDrive\iCloud~md~obsidian\nameless`

Wiki root: `Wiki/`
Sources drop zone: `Sources/_inbox/`
Secure files: `Secure/`

---

## Stage-and-Confirm Protocol (default)

1. Claude drafts output to `./.scratch/obsidian-stage/<topic>-<date>.md` with frontmatter + body
2. Claude shows: destination path, page type, brand, and 2-sentence preview
3. Claude asks: `Write to Wiki/<folder>/<page>.md? (yes / no / change path / edit)`
4. On `yes`: run the Pre-Write Duplicate Check below, then write or merge as appropriate
5. On `no`: stays in scratch; user can hand back with edits

Override commands:
- `direct-write` -> skip staging this session
- `stage` -> return to default

---

## Pre-Write Duplicate Check

Approval permits writing, but never bypasses duplicate detection. Before moving staged content into the vault or creating any new wiki page:

1. Search `Wiki/index.md` for the same or similar title.
2. Search `Wiki/` for matching source URLs, aliases, names, companies, projects, and distinctive claims.
3. Compare relevant frontmatter fields such as `source`, `url`, `aliases`, `company`, `project`, `domain`, and `date`.
4. If a likely duplicate exists, merge useful new information into the canonical page instead of creating a new page.
5. Record the merge or new-page decision in `Wiki/log.md`.

---

## Routing Matrix

| Output type | Vault destination | Page type |
|---|---|---|
| Quick capture, idea | `Sources/_inbox/<topic>.md` -> trigger INGEST | Source |
| Task / action item | Append to `Wiki/Projects/<project>.md` ## Tasks | Project |
| Research dump | `Sources/_inbox/<topic>.md` -> INGEST to `Wiki/Concepts/` or `Wiki/Synthesis/` | Concept or Synthesis |
| Project deliverable | `Wiki/Projects/<project>.md` | Project |
| Recurring report (GA4, GSC, Meta Ads) | `Wiki/Synthesis/<Report Type>-YYYY-MM-DD.md` | Synthesis |
| Marketing copy / draft | `Sources/_inbox/<topic>-draft.md` -> INGEST | Source |
| SOP / process doc | `Wiki/Concepts/<process>.md` | Concept |
| Code, agent specs, prompts | Local file + append to `Wiki/Synthesis/Local Files Index.md` | Synthesis |
| Agent task log | Append to `Wiki/Synthesis/Work Queue.md` | Synthesis |
| Outbound email / message draft | Append to `Wiki/People/<person>.md` ## Notes | Person |
| Session log (ai-session-save) | `Wiki/Logs/Session-YYYY-MM-DD.md` | Log |
| Contact intel / MSP outreach | `Wiki/People/<person>.md` or `Wiki/Companies/<company>.md` | Person / Company |
| Brand page update | `Wiki/Brands/<Brand>.md` | Brand |
| Health / fitness note | `Wiki/Health & Fitness/<topic>.md` | Concept |

---

## Brand Tagging

Every wiki page that is brand-specific must include `domain:` in frontmatter.

| Code | Brand | Color |
|---|---|---|
| `MNA` | MNA Healthcare | BLUE |
| `TGA` | The Green Anchor | GREEN |
| `SHL` | Side Hustle Labs | PURPLE |
| `TGAH` | TGA Health | PINK |
| `PERSONAL` | Personal / fitness / learning | - |
| `CROSS` | Spans multiple brands | - |

If brand is unstated and the task is brand-specific, ask before writing.

Brand inference (when not stated):
- "What should I use?" -> TGAH
- "How do I do this?" -> SHL
- "Can you build this for me?" -> TGA
- MNA Healthcare is never auto-inferred - always tag explicitly

---

## Page Type Frontmatter

Follow WIKI-SCHEMA.md exactly. Quick reference:

**Person:**
```yaml
---
name:
company:
role:
domain:
relationship:   # client | contact | collaborator | vendor | lead | personal
email:
linkedin:
last-updated:
sources: []
tags: [person]
---
```

**Company:**
```yaml
---
name:
industry:
domain:
relationship:   # client | vendor | competitor | partner | prospect
website:
last-updated:
sources: []
tags: [company]
---
```

**Project:**
```yaml
---
title:
company:
domain:
status:         # active | closed | prospecting | on-hold
stage:
value:
lead:
start-date:
last-updated:
sources: []
tags: [project]
---
```

**Concept / SOP:**
```yaml
---
concept:
domain:
confidence:     # established | emerging | speculative
last-updated:
sources: []
tags: [concept]
---
```

**Synthesis / Report:**
```yaml
---
title:
covers: []
domain:
query:
last-updated:
tags: [synthesis]
---
```

**Log (session):**
```yaml
---
type: log
date: YYYY-MM-DD
session-id:
agents: []
domain:
tags: [log]
---
```

---

## Oversized Outputs

Parent page in destination folder -> child pages as separate `.md` files linked via `[[wikilink]]`. Code blocks and large data stay in scratch with a wikilink from the parent page.

---

## After Writing

If the page is new: append one line to `Wiki/index.md`:
```
- [[Page Name]] - one-line description - `domain` - updated YYYY-MM-DD
```

If it is a INGEST-worthy source: drop to `Sources/_inbox/` and note that an INGEST operation should be run via Codex to process it into the wiki.
