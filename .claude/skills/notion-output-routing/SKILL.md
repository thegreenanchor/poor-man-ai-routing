---
name: notion-output-routing
description: Routes every non-trivial deliverable to the right Notion destination in the user's existing PARA + brand-coded structure. Defines the routing matrix, page templates, format rules, brand-color map, and the stage-and-confirm protocol. Use whenever Claude produces an output that should land in Notion (research, drafts, reports, SOPs, project deliverables, captures). Always relevant before delivering work.
---

# Notion Output Routing

## Core principle

Every non-trivial output ends with a Notion write. Claude does not just return text and walk away. The deliverable lands in its proper place in your PARA + brand-coded Notion, formatted as native Notion blocks, with required properties set.

Default behavior: **stage and confirm**. Claude drafts the page locally, asks "Push to <DB> as draft?", waits for explicit yes, then writes via the Notion MCP.

## Brand and color map (default placeholders)

Customize these in `BRANDS.md`. Defaults:

| Brand code | Color | Suggested use |
|---|---|---|
| MAIN | PURPLE | Your main brand or primary side gig |
| WORK | BLUE | Your day-job brand |
| SIDE | GREEN | Your agency / consulting brand |
| OTHER | PINK | Additional brand or experimental |
| Cross-brand | gray | Shared / utility / cross-brand artifacts |

When a task is brand-specific and the brand is not stated, infer per the rubric below or ask.

## Brand inference (when not stated, optional)

If you run a multi-brand setup with a content funnel (top-of-funnel / middle / bottom), define the inference rubric in `BRANDS.md`. Example pattern (customize):

| Content answers... | Brand | Layer |
|---|---|---|
| "What should I use?" | (top-of-funnel brand) | Lifestyle / traffic |
| "How do I do this?" | (middle brand) | Education / tutorials |
| "Can you build this for me?" | (bottom brand) | Authority / services |

Brands outside the funnel (e.g., a day-job brand) require explicit tags from the user. Do not auto-classify into them.

**Cross-brand or unclear:** ask the user before writing.

### Optional: idea scoring grid

For content captured to Inbox where a brand recommendation should be persistent, score across 5 axes (each 0-3): Audience Intent, Monetization, Authority, Repurpose, Brand Alignment. Map sum to brand per your `BRANDS.md`. Skip if you don't run multi-brand.

## Escalation hints (optional)

If you use a content funnel, configure escalation patterns in `BRANDS.md`. The system can append a one-line "next-step" callout at the bottom of pages that land in upstream brands, suggesting a downstream piece of content. Example callout:

```
> 💡 Escalation candidate: <suggestion>
```

Skip escalation hints for project deliverables, recurring reports, and SOPs.

## Routing matrix

| Output type | Destination database | Required properties |
|---|---|---|
| Quick capture, idea, "save for later" | 📥 Inbox Database | Type=Note, Category=brand, Status=New |
| Task / action item | 📥 Inbox Database | Type=Task, Category=brand, Priority, Status=New |
| Research dump (Gemini result) | 📥 Inbox Database, then promote to Resources | Type=Resource, Category=brand. Full dump in `./.scratch/`, link to it |
| Project deliverable | 🛠️ Projects Database | Status, Priority, Category=Business, Area (relation), Goal, Next Action, Deadline |
| Recurring report (SEO, GA4, GSC, Meta Ads, Social Stats) | 📊 Metrics Database | Brand, Report Type, Date, Metric, Platform (if applicable), Value, Name |
| Marketing campaign (WORK outreach pattern) | 📁 Campaigns hub (per-campaign sub-page with 4 child DBs: Facilities, Call Log, Mailcoach Export, Email Sequence) | Per existing campaign template |
| Marketing copy / draft | 📥 Inbox Database, Tag=Draft | Type=Note, Category=brand, Tag=Draft. Promotes to Campaigns or Projects |
| SOP / process doc | 🗃️ Areas Database | Category, Tags=PARA + topic, Last Reviewed |
| Code, agent specs, prompts, templates, content files | Local file canonical (filesystem) + entry in 📂 Local Files Index | Title, Local Path, Artifact Type, Brand, Owner Agent, Status |
| Agent task | 📋 Work Queue | Task ID (YYYY-MM-DD-NNN), Brand, Priority, Assigned Agent, Required Outputs, Approver, Status |

## Database IDs

For Codex / Notion MCP calls. Pin these in handoff prompts.

```
Inbox Database:        <YOUR_INBOX_DB_ID>
                       data source: collection://<YOUR_INBOX_DS_ID>

Projects Database:     <YOUR_PROJECTS_DB_ID>
                       data source: collection://<YOUR_PROJECTS_DS_ID>

Areas Database:        <YOUR_AREAS_DB_ID>
                       data source: collection://<YOUR_AREAS_DS_ID>

Metrics Database:      <YOUR_METRICS_DB_ID>
                       data source: collection://<YOUR_METRICS_DS_ID>

Local Files Index:     <YOUR_FILES_INDEX_DB_ID>
                       data source: collection://<YOUR_FILES_INDEX_DS_ID>

Work Queue:            <YOUR_WORK_QUEUE_DB_ID>
                       data source: collection://<YOUR_WORK_QUEUE_DS_ID>

Campaigns (page hub):  <YOUR_CAMPAIGNS_PAGE_ID>
```

## Owner Agent mapping (for Local Files Index and Work Queue writes)

Subagents in this system stay generic: `orchestrator`, `researcher`, `builder`, `reviewer`. When writing to Notion DBs that have an `Owner Agent` property (Local Files Index, Work Queue), map to the existing named agents in those selects:

| Generic subagent | Notion Owner Agent option | Notes |
|---|---|---|
| researcher | <Research_Agent> | Search, OSINT, web |
| builder (code-heavy) | <Code_Agent> | Refactors, infra, structured builds |
| builder (content-heavy) | <Content_Agent> | Drafting, copy, posts |
| builder (creative) | <Creative_Agent> | Image gen, design briefs |
| reviewer (analytics) | <Analyst_Agent> | Reports, metrics analysis |
| reviewer (publishing) | <Publisher_Agent> | The actual page write |
| (orchestrator) | System | Routing decisions, no specific agent |

This preserves your existing brand vocabulary in the data layer without bloating the operational subagent count.

### Brand-funnel agent reference (optional, read-only)

If you run a tiered agent system (Strategic / Translation / Execution per brand), document agent names per tier in `BRANDS.md`. Subagents in this skill stay generic; the named agents are labels you apply when writing to Notion DBs that have an `Owner Agent` property.

Tier rules (when applicable):
- Execution agents typically don't decide escalation; only translation-tier agents do.
- Cross-tier reporting paths should be defined in `BRANDS.md`.

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
  Category: MAIN | WORK | SIDE | OTHER | General | Personal
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
  Brand: MAIN | WORK | SIDE | OTHER | Cross-brand
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
  Category: Work | WORK (multi-select)
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
  Local Path: G:\My Drive\... or ~/Documents/workspace\...
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
Marketing campaign → Campaigns hub (per existing pattern, WORK today)
Code / spec        → local file + Local Files Index entry
Agent task         → Work Queue
```
