---
name: obsidian-output-routing
description: Routes every non-trivial deliverable to the correct destination in the Obsidian wiki vault. Defines the routing matrix, page type templates, stage-and-confirm protocol, pre-write duplicate checks, and brand tagging rules. Use whenever Claude produces an output that should be written to the vault (research, drafts, reports, SOPs, project deliverables, captures, session logs). Always consult before any vault write.
---

# Obsidian Output Routing

This Obsidian system adapts Andrej Karpathy's LLM Wiki pattern: raw sources are captured and archived, then the agents compile them into durable Markdown wiki pages instead of re-reading raw documents for every query.

Reference: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

## Vault Root
`C:\Users\moveb\iCloudDrive\iCloud~md~obsidian\nameless`

Wiki root: `Wiki/`
Sources drop zone: `Sources/_inbox/`
Secure files: `Secure/`

Core rule: every non-trivial task performed by any CLI AI must be written back to the LLM Wiki in the correct domain before final delivery.

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

## Mandatory Task Logging

Every non-trivial work item needs two records:
1. **Operating memory** on the canonical page.
2. **Audit trail** in `Wiki/log.md`.

Canonical page routing:
- Project work -> `Wiki/Projects/<project>.md`
- Content calendar/campaign work -> `Wiki/Campaigns/<campaign>.md`
- Individual content item -> `Wiki/Content/<item>.md`
- Company/contact context -> `Wiki/Companies/` or `Wiki/People/`
- Unknown or cross-cutting work -> `Wiki/Synthesis/Work Queue.md`

Append to the most relevant section:
- `## Next Actions` for tasks
- `## Decisions` for choices made
- `## Notes` for context
- `## History` for completed milestones
- `## Content Calendar` for linked content items

Update frontmatter:
- `last-updated: YYYY-MM-DD`
- `domain: MNA | TGA | PPH | SHL | TGAH | PERSONAL | CROSS`
- Notebook Navigator tags such as `area/tga`, `employer/mna-healthcare`, `client/pink-party-house`, and `status/active`

Use `Wiki/Synthesis/Work Queue.md` only when the correct canonical page cannot be identified safely.

---

## Routing Matrix

| Output type | Vault destination | Page type |
|---|---|---|
| Quick capture, idea | `Sources/_inbox/<topic>.md` -> trigger INGEST | Source |
| Task / action item | Append to `Wiki/Projects/<project>.md` ## Tasks | Project |
| Content calendar | `Wiki/Campaigns/<campaign>.md` | Campaign |
| Content item | `Wiki/Content/<item>.md` | Content |
| Research dump | `Sources/_inbox/<topic>.md` -> INGEST to `Wiki/Concepts/` or `Wiki/Synthesis/` | Concept or Synthesis |
| Project deliverable | `Wiki/Projects/<project>.md` | Project |
| Recurring report (GA4, GSC, Meta Ads) | `Wiki/Synthesis/<Report Type>-YYYY-MM-DD.md` | Synthesis |
| Marketing copy / draft | `Sources/_inbox/<topic>-draft.md` -> INGEST | Source |
| SOP / process doc | `Wiki/Concepts/<process>.md` | Concept |
| Code, agent specs, prompts | Local file + append to `Wiki/Synthesis/Local Files Index.md` | Synthesis |
| Uncategorized task log | Append to `Wiki/Synthesis/Work Queue.md` | Synthesis |
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
| `MNA` | MNA Healthcare, employer/work context | BLUE |
| `TGA` | The Green Anchor, active brand | GREEN |
| `PPH` | Pink Party House Co., TGA client | PINK |
| `SHL` | Side Hustle Labs, back-burner | PURPLE |
| `TGAH` | TGA Health / tgahealth.shop, n8n surface | PINK |
| `PERSONAL` | Personal / fitness / learning | - |
| `CROSS` | Spans multiple brands | - |

If brand is unstated and the task is brand-specific, ask before writing.

Domain inference:
- MNA, travel nurse staffing, Pulse CRM, Mailcoach outreach, PA NCF -> `MNA`, tag `employer/mna-healthcare`
- The Green Anchor, joseinarcadia, thegreenxnchor, thegreenanchor.com -> `TGA`, tag `brand/the-green-anchor`
- Pink Party House, pinkbouncehousebroward.com -> `PPH`, tags `area/tga`, `brand/the-green-anchor`, `client/pink-party-house`
- tgahealth.shop or n8n public webhook surface -> `TGAH` or `CROSS` depending on whether the work is site-specific or infrastructure-wide
- Side Hustle Labs, OSINT ideas -> `SHL`, but treat as back-burner unless user explicitly reactivates
- Personal learning, travel, health -> `PERSONAL`
- AI routing, LLM Wiki, shared tooling -> `CROSS`

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
