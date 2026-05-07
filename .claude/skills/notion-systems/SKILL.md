---
name: notion-systems
description: Notion database design, automation, and bulk operations beyond the Notion MCP. Use for designing CRM/ops/content systems in Notion, bulk imports, cross-database queries, template generation, and reusable workspaces. Trigger when task involves Notion architecture, building a workspace, or volume operations.
---

# Notion Systems

## Scope

Complement to the connected Notion MCP. Use the MCP for:
- Single-page reads/writes
- Quick database queries
- Simple updates

Use this skill for:
- Designing new database schemas
- Bulk creating pages from CSV/JSON
- Cross-database rollups and synced views
- Template-based workspace builds
- Migration from other systems (Airtable, Coda, spreadsheets)

## Inputs

- Notion API token (`NOTION_TOKEN`, an Internal Integration token)
- Database IDs or page IDs
- Integration must be added to each database/page (Notion → Connections → Integration)

## Database design patterns

### CRM (people)

Properties:
- Name (title)
- Email (email)
- Company (relation → Companies db)
- Status (select: Lead, Qualified, Active, Lost, Customer)
- Source (select: LinkedIn, Web, Referral, Cold, Event)
- Owner (person)
- Last Contact (date)
- Next Action (text)
- Notes (text)

### Content pipeline

Properties:
- Title (title)
- Status (status: Idea, Drafting, Review, Scheduled, Published)
- Brand (select: WORK, SIDE, SIDE, MAIN)
- Channel (multi-select: Blog, LinkedIn, Email, IG, X)
- Author (person)
- Due Date (date)
- Publish Date (date)
- Keywords (multi-select)
- Outline (relation → Outlines db)

### Project ops

Properties:
- Project (title)
- Status (status: Planning, Active, Blocked, Done, Archived)
- Owner (person)
- Tasks (relation → Tasks db, rolled up: completed/total)
- Start (date), Due (date)
- Brand (select)
- Health (formula: based on due date + completion)

## Common operations

### Create database

```
cdx "GOAL: Create Notion database 'Content Pipeline' inside parent page <parent_id>.
PROPERTIES: per schema in ./.scratch/db-schema.json
ENDPOINT: POST /v1/databases
RETURN: STATUS + SUMMARY (database id, URL)."
```

### Bulk import

```
cdx "GOAL: Import rows from ./.scratch/contacts.csv into Notion database <db_id>.
MAPPING: ./.scratch/column-mapping.json (CSV column → Notion property name+type)
METHOD: For each row, POST /v1/pages with parent: database_id and properties: <mapped>.
RATE LIMIT: 3 req/sec (Notion default).
SUCCESS: every row imported, failures logged.
OUTPUT: ./.scratch/notion-import-errors-$(date +%Y-%m-%d).csv
RETURN: STATUS + SUMMARY (imported, errored) + ARTIFACTS."
```

### Cross-database query

```
cdx "GOAL: Find all Tasks where Status=Active AND Due <= today AND Project.Brand=WORK.
APPROACH: Query Tasks db with filter Status=Active AND Due on/before today; for each result, fetch related Project, filter by Brand=WORK.
ENDPOINT: POST /v1/databases/<tasks_db>/query
OUTPUT: ./.scratch/active-mna-tasks.json
RETURN: STATUS + SUMMARY (count, top 5 by due date) + ARTIFACTS."
```

### Template-based page generation

```
cdx "GOAL: Create a project page from template for each row in ./.scratch/new-projects.csv.
TEMPLATE: copy structure of template page <template_page_id>, replace {placeholders} with row values.
PARENT: database <projects_db>
RETURN: STATUS + SUMMARY (count, page URLs) + ARTIFACTS."
```

## Code template (Python)

```python
import os, requests, json, time
TOKEN = os.environ['NOTION_TOKEN']
HEADERS = {
    'Authorization': f'Bearer {TOKEN}',
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
}

# Create page in database
body = {
    'parent': {'database_id': DB_ID},
    'properties': {
        'Name': {'title': [{'text': {'content': name}}]},
        'Email': {'email': email},
        'Status': {'select': {'name': 'Lead'}},
    }
}
r = requests.post('https://api.notion.com/v1/pages', headers=HEADERS, json=body)
time.sleep(0.35)  # ~3 req/sec
```

## Reusable workspace patterns

A typical setup:

**Brand workspaces** (one per brand or one workspace with brand-tagged data):
- WORK (your day-job brand) ops
- SIDE (clients, projects, content)
- OTHER (your wellness brand) (content, partners)
- MAIN (your main brand) (products, content)

**Cross-brand databases**:
- Master content pipeline (Brand property filters views)
- Master CRM (Brand property)
- Master tasks
- Master assets library

**Templates** (reusable page templates):
- Client onboarding
- Campaign brief
- Sprint plan
- SOP template
- Meeting notes

If building a new workspace, ask which pattern applies before writing.

## Sync from other tools

### From Airtable

Airtable export → CSV per table → bulk import via this skill. Relations become text references; convert to Notion relations after import using a second pass.

### From spreadsheet

CSV → bulk import. Pre-clean data; Notion's API is strict on type matches.

### From HubSpot

Use skill `hubspot-workflows` to export, then this skill to import. Common for surfacing CRM data inside Notion ops dashboards.

## Sync to Notion (one-way scheduled)

For dashboards that pull from external systems:

```
cdx "GOAL: Sync GA4 daily metrics to Notion database <metrics_db>.
SOURCE: GA4 API (skill ga4-reporting handles the pull)
SYNC: one row per day per metric. Upsert by date.
SCHEDULE: cron daily.
RETURN: STATUS + SUMMARY + ARTIFACTS (cron file written)."
```

## Pitfalls

- Property names must match exactly (case-sensitive).
- `select` and `multi_select` options must exist or be created.
- `relation` properties: provide page IDs, not names.
- Notion API rate limit: ~3 req/sec average. Bursts get 429.
- API doesn't support all Notion features (e.g. some block types are limited).
- Database IDs must be the 32-char hex (not the URL slug).

## Anti-patterns

- Building the database schema directly via API without first prototyping in Notion UI. Easier to design visually, then export the schema.
- Storing tokens in scratch. Env only.
- Bulk operations without throttling.
- Forgetting to share the database with the integration (returns 404 mysteriously).
