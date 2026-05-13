> **ARCHIVED 2026-05-13** - Replaced by `obsidian-output-routing`. Kept for reference only.
> Do not use for new deliverables. Re-enable only if Notion is re-added as a destination.

---
name: notion-output-routing
description: Routes every non-trivial deliverable to the right Notion destination in the user's existing PARA + brand-coded structure. Defines the routing matrix, page templates, format rules, brand-color map, and the stage-and-confirm protocol. Use whenever Claude produces an output that should land in Notion (research, drafts, reports, SOPs, project deliverables, captures). Always relevant before delivering work.
---

# Notion Output Routing

## Core principle

Every non-trivial output ends with a Notion write. Claude does not just return text and walk away. The deliverable lands in its proper place in Jose's PARA + brand-coded Notion, formatted as native Notion blocks, with required properties set.

Default behavior: **stage and confirm**. Claude drafts the page locally, asks "Push to <DB> as draft?", waits for explicit yes, then writes via the Notion MCP.

## Brand and color map

| Brand | Code | Hub color (Local Files Index, Work Queue) | Inbox category |
|---|---|---|---|
| Side Hustle Labs | SHL | PURPLE | SHL (purple) |
| MNA Healthcare | MNA | BLUE | MNA (blue) |
| The Green Anchor (agency) | TGA | GREEN | TGA (green) |
| TGA Health (wellness) | TGAH | PINK | TGAH (pink) |
| Cross-brand or shared | (varies) | Shared / Cross-brand | General |

## Brand inference (when not stated)

For TGA-ecosystem content (TGAH / SHL / TGA), infer brand from the question the content answers:

| Content answers... | Brand | Layer |
|---|---|---|
| "What should I use?" | TGAH | Traffic / wellness lifestyle |
| "How do I do this?" | SHL | Trust / education / templates / tutorials |
| "Can you build this for me?" | TGA | Authority / agency / system architecture |

Ambiguous cases: route to **SHL Framework Strategist** first as the default decoder, then escalate up (to TGA) or down (to TGAH) based on what the content actually does.

**MNA Healthcare is outside this funnel.** MNA is the user's day-job staffing brand, not part of the TGA ecosystem. MNA work always requires explicit `MNA` tag from the user. Do not auto-classify into MNA.

**Cross-brand or unclear:** ask the user before writing.

### Optional: idea scoring grid

For content captured to Inbox where a brand recommendation should be persistent, score across 5 axes (each 0-3): Audience Intent, Monetization, Authority, Repurpose, Brand Alignment. Sum maps to brand:
- 0-6 -> TGAH
- 7-11 -> SHL
- 12-15 -> TGA

Use only when scoring adds value (e.g., quarterly content planning). Skip for routine captures.

## Escalation hints

When a deliverable lands in TGAH or SHL, append a one-line escalation suggestion to the page:

| From | To | Pattern |
|---|---|---|
| TGAH | SHL | "Wellness routine post -> SHL template post: 'How I built my [routine] in Notion'" |
| SHL | TGA | "Notion tutorial -> TGA case study: 'The [topic] architecture behind my [outcome]'" |
| TGAH | TGA (rare) | Skip direct, route through SHL first |

Escalation is a hint for the human, not auto-execution. Drop it as a callout block at the bottom of the page:

```
> 💡 Escalation candidate: <suggestion>
```

Skip escalation hints for MNA, Cross-brand, project deliverables, recurring reports, and SOPs.

## Routing matrix

| Output type | Destination database | Required properties |
|---|---|---|
| Quick capture, idea, "save for later" | 📥 Inbox Database | Type=Note, Category=brand, Status=New |
| Task / action item | 📥 Inbox Database | Type=Task, Category=brand, Priority, Status=New |
| Research dump (Gemini result) | 📥 Inbox Database, then promote to Resources | Type=Resource, Category=brand. Full dump in `./.scratch/`, link to it |
| Project deliverable | 🛠️ Projects Database | Status, Priority, Category=Business, Area (relation), Goal, Next Action, Deadline |
| Recurring report (SEO, GA4, GSC, Meta Ads, Social Stats) | 📊 Metrics Database | Brand, Report Type, Date, Metric, Platform (if applicable), Value, Name |
| Marketing campaign (MNA outreach pattern) | 📁 Campaigns hub (per-campaign sub-page with 4 child DBs: Facilities, Call Log, Mailcoach Export, Email Sequence) | Per existing campaign template |
| Marketing copy / draft | 📥 Inbox Database, Tag=Draft | Type=Note, Category=brand, Tag=Draft. Promotes to Campaigns or Projects |
| SOP / process doc | 🗃️ Areas Database | Category, Tags=PARA + topic, Last Reviewed |
| Code, agent specs, prompts, templates, content files | Local file canonical (filesystem) + entry in 📂 Local Files Index | Title, Local Path, Artifact Type, Brand, Owner Agent, Status |
| Agent task | 📋 Work Queue | Task ID (YYYY-MM-DD-NNN), Brand, Priority, Assigned Agent, Required Outputs, Approver, Status |

## Database IDs

For Codex / Notion MCP calls. Pin these in handoff prompts.

```
Inbox Database:        3026f335-ffee-80db-a612-cf1a5e2c3e94
                       data source: collection://3026f335-ffee-80f2-8fe4-000b6a0b22fd

Projects Database:     685be4d0-1a4a-4126-9de4-d220f70cf816
                       data source: collection://9569abed-5d93-4455-b027-a437f7222308

Areas Database:        fe279daa-1a86-4cf0-8d03-b3281d7ef9eb
                       data source: collection://f28b0108-8280-4e94-8271-a55e886ef5db

Metrics Database:      0e184296-833c-43b2-9cfa-36cd536e7e89
                       data source: collection://4d38eb0c-7c11-49a5-afcd-6f0ca7a97ffb

Local Files Index:     ad07184079fe436baad7c98b511d2588
                       data source: collection://24186229-37b1-49b5-8a30-b394d763562c

Work Queue:            50bce5aab8814eb8b84563b482f5ab12
                       data source: collection://73664bf1-e6a4-4a93-ac1e-cc97093552bc

Campaigns (page hub):  b7eae8de-6a42-41bb-9c6a-68269c53509b
```

## Owner Agent mapping (for Local Files Index and Work Queue writes)

Subagents in this system stay generic: `orchestrator`, `researcher`, `builder`, `reviewer`. When writing to Notion DBs that have an `Owner Agent` property (Local Files Index, Work Queue), map to the existing named agents in those selects:

| Generic subagent | Notion Owner Agent option | Notes |
|---|---|---|
| researcher | Research_Strategist_Agent | Search, OSINT, web |
| builder (code-heavy) | Content_Architect_Agent | Refactors, infra, structured builds |
| builder (content-heavy) | Main_Content_Intelligence_Agent | Drafting, copy, posts |
| builder (creative) | Creative_Generator_Agent | Image gen, design briefs, mogrt prep |
| reviewer (analytics) | Performance_Analyst_Agent | Reports, metrics analysis |
| reviewer (Notion publishing) | Notion_Automator_Agent | The actual page write |
| (orchestrator) | System | Routing decisions, no specific agent |

This preserves your existing brand vocabulary in the data layer without bloating the operational subagent count.

### Brand-funnel agent reference (read-only, for context)

Your richer tiered hierarchy from the Raw Hub Chat is preserved here for reference. Subagents do not implement these directly; they're labels you can apply to specific deliverables when writing.

**TGAH (🟩 traffic):** Wellness Content Strategist, Blog Production Agent, Affiliate Optimization Agent, Visual Content Agent, Trend Scanner Agent.

**SHL (🟦 trust):** Framework Strategist, Template Builder Agent, Email System Agent, Guide Author Agent, Research Synthesizer.

**TGA (🟪 authority):** Systems Architect, Case Study Builder, Client Translation Agent, Offer Alignment Agent, Momentum Indicator Agent.

**Tier rules** (when assigning Owner Agent or routing escalation):
- TGAH execution agents do NOT report directly to Systems Architect. Translation goes through SHL Framework Strategist.
- Execution agents (Tier 3) do not decide escalation. Only Framework Strategist + Flywheel Coordinator do.
- Affiliate Optimization Agent cannot initiate TGA content (prevents authority brand from going product-heavy).

Use these labels in page properties, callouts, or notes when relevant. Do not spawn separate Claude subagents for them.

## Stage-and-confirm protocol

Default for every Notion write. Steps:

1. Claude drafts the page in Notion-block-friendly markdown to `./.scratch/notion-stage/<topic>-<date>.md`.
2. Claude reads back the destination DB, brand, properties, and a 2-sentence preview.
3. Claude asks: `Push to <DB Name> as draft? (yes / no / change destination / change brand / edit)`
4. On `yes`: Claude (or `notion-publisher` step inside reviewer) calls `notion-create-pages` via MCP.
5. On `no`: stays in scratch. User can hand it back later with edits.
6. Returns the Notion page URL.

Override commands the user can type:
- `direct-write` → skip staging this session (fast mode)
- `stage` → return to default

## Notion-block format rules

Markdown that maps cleanly to native Notion:

- `#`, `##`, `###` → H1, H2, H3 (do not use bold-as-heading)
- `-` lists → bulleted blocks
- `1.` lists → numbered blocks
- ```` ``` ```` with language tag → code blocks (e.g. ```` ```python ````)
- `> 💡 …` → callout blocks
- `> [!toggle] Title` → toggle blocks (Notion-flavored extension; expand if Notion MCP supports)
- `| col | col |` tables → inline tables (small) or relate to a DB (structured data)
- `**bold**`, `*italic*` → inline formatting
- Links: `[text](https://url)` (always full URL, no markdown reference style)

What NOT to use:
- HTML tags (Notion strips most)
- Em dashes (user preference; use `-` or `:` instead)
- Mixed list types in the same block

## Page templates by destination

### 📥 Inbox capture (Note / Task / Resource)

```
Title: <short note title>
Properties:
  Note (title): <Title>
  Type: Note | Task | Resource
  Category: SHL | MNA | TGA | TGAH | General | Personal
  Priority: High | Medium | Low | None
  Status: New
  Notes: <one-line context>

Content:
<full text of the capture>

If Resource, append:
## Source
- URL: <url>
- Date retrieved: <date>
- Scratch path: <./.scratch/...>
```

### 🛠️ Project deliverable

```
Title: <Project name>
Properties:
  Name (title): <Project Name>
  Goal: <one-sentence objective>
  Next Action: <immediate next step>
  Status: Not Started | In Progress | Completed
  Priority: High | Medium | Low
  Progress: 0% | 25% | 50% | 75% | 100%
  Category: Business | Personal | Health | Finance | Relationships
  Area: <link to Area>
  Start Date: <date>
  Deadline: <date>
  Owner 1: <person>

Content:
## Overview
<context>

## Plan
<numbered steps>

## Deliverables
<list with linked artifacts>

## Notes
<anything else>
```

### 📊 Metrics report row

One row per metric per period. For multi-metric reports, write multiple rows or a parent page with linked rows.

```
Properties:
  Name (title): <Brand> <Report Type> <YYYY-MM-DD>
  Brand: SHL | MNA | TGA | TGAH | Cross-brand
  Report Type: SEO Audit | GA4 Report | GSC Report | Meta Ads Report | Social Stats | Custom
  Date: <date>
  Platform: <if applicable>
  Metric: <metric name>
  Value: <number>

Content (parent summary page if multi-row):
## Period
<date range>

## Summary
<5 bullets>

## Linked rows
<list of metric rows>

## Source data
- ./.scratch/<artifact>.csv
```

### 🗃️ Areas (SOP / process doc)

```
Title: <SOP name>
Properties:
  Name (title): <SOP Name>
  Category: Work | MNA (multi-select)
  Category 1: Business | Personal | etc.
  Tags: PARA + topic
  Last Reviewed: <today>

Content:
## Purpose
<one sentence>

## Process
1. Step
2. Step

## Inputs / outputs / decision points
<as needed>

## Reference
<links>
```

### 📂 Local Files Index entry

Use when output is a code/agent/template file. The file lives canonically in `~/Documents/workspace/businesses/<brand>/...`. Notion stores the metadata.

```
Properties:
  Title: <File title>
  Local Path: G:\My Drive\... or C:\Users\moveb\Documents\workspace\...
  Artifact Type: System Doc | Agent Spec | Contract | Prompt | Content | Template | Research | Ops | Integration
  Brand: PURPLE | BLUE | GREEN | PINK | Shared | System | Integration
  Owner Agent: Main_Content_Intelligence_Agent | Research_Strategist_Agent | Content_Architect_Agent | Creative_Generator_Agent | Performance_Analyst_Agent | Notion_Automator_Agent | System
  Status: Draft | Active | Deprecated | Archived
  Last Updated: <date>
  Notes: <one-line>
```

### 📋 Work Queue task

```
Properties:
  Task ID (title): <YYYY-MM-DD>-<NNN>
  Brand: PURPLE | BLUE | GREEN | PINK | Cross-brand
  Priority: High | Medium | Low
  Assigned Agent: <agent name>
  Required Outputs: <local paths or descriptions>
  Approver: Systems Architect | Offer Alignment Director | None
  Status: Queued | In Progress | Review | Done
  Notes: <context>
```

## Oversized output handling (Option B confirmed)

If a deliverable exceeds ~200 lines or 10 sections:

1. Create a **parent page** in the destination DB with the standard properties and a top-level summary (≤300 words).
2. For each major section, create a **child page** under the parent, linked from the parent's "Sections" list.
3. Code blocks and large data tables stay in `./.scratch/` filesystem; parent page links to them.
4. Properties (Brand, Status, etc.) live on the parent. Children inherit context but may have their own Status if needed.

Use `notion-create-pages` (MCP) with parent page id once parent exists.

## Codex handoff for the Notion write step

When the reviewer subagent confirms a deliverable is ready to push, the actual MCP write goes via Codex (heavier I/O work belongs there per usage protocol):

```
cdx "GOAL: Create Notion page in <DB Name> (id <db_id>) with properties from ./.scratch/notion-stage/<file>.md frontmatter and content from the body.
DESTINATION: <db_id>
PROPERTIES (from frontmatter):
  <properties>
CONTENT BODY: from the file's body section, formatted as Notion-flavored markdown.
SUCCESS:
  - Page created
  - Returns page URL
  - All required properties set
RETURN: STATUS + EVIDENCE (page URL) + ARTIFACTS (the staged file)."
```

For bulk writes (e.g., 50 metric rows from a GA4 pull), Codex loops via the Notion MCP `notion-create-pages` endpoint with rate limiting.

## Anti-patterns

- **Free-floating pages with no parent.** Every page lands in a database or under a known parent.
- **Skipping required properties.** Better to default a Status field than omit it.
- **Em dashes in Notion content** (user preference, also signals AI-generated).
- **Walls of text without headings.** Notion blocks expect structure; readability suffers.
- **Inline screenshots/binaries.** Generated images live on filesystem. Notion gets a link.
- **Direct write without staging** (unless user invoked `direct-write` for the session).

## Quick reference

```
Quick note         → Inbox / Note
Task               → Inbox / Task → Projects on action
Research dump      → Inbox / Resource (full dump in scratch)
Project work       → Projects (linked to Area)
Recurring report   → Metrics (with Brand + Report Type)
SOP                → Areas (with PARA tag)
Marketing draft    → Inbox / Note + Tag=Draft
Marketing campaign → Campaigns hub (per existing pattern, MNA today)
Code / spec        → local file + Local Files Index entry
Agent task         → Work Queue
```
