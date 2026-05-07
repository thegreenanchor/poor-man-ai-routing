---
name: n8n-workflows
description: Building, exporting, and maintaining n8n automation workflows. Use for designing connectors between tools (HubSpot, Notion, Slack, Mailcoach, GA4, etc.), bulk workflow imports, workflow JSON manipulation, and self-hosted n8n setup. Trigger for any n8n, automation pipeline, or no-code workflow task.
---

# n8n Workflows

## Scope

n8n self-hosted (Docker preferred) or n8n.cloud. Workflow JSON manipulation, REST API ops, common integration patterns.

## Self-hosted setup

See skill `docker-ops` for the compose file.

After first start:
- http://localhost:5678
- Create owner account (first-run only)
- Settings → API → generate API key for headless use

## Inputs

- n8n base URL (`N8N_URL`)
- API key (`N8N_API_KEY`)
- For self-hosted: webhook URL (`N8N_WEBHOOK_URL`)

## API operations

### List workflows

```
cdx "GOAL: List all workflows in n8n at <N8N_URL>.
ENDPOINT: GET /api/v1/workflows
HEADERS: X-N8N-API-KEY: <key>
OUTPUT: ./.scratch/n8n-workflows-$(date +%Y-%m-%d).json
RETURN: STATUS + SUMMARY (count, active count, names) + ARTIFACTS."
```

### Export workflow

```
cdx "GOAL: Export n8n workflow <id>.
ENDPOINT: GET /api/v1/workflows/<id>
OUTPUT: ./.scratch/workflows/<name>-$(date +%Y-%m-%d).json
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

### Import workflow

```
cdx "GOAL: Import workflow JSON to n8n.
SOURCE: ./.scratch/workflow.json
ENDPOINT: POST /api/v1/workflows
RETURN: STATUS + SUMMARY (new id, URL)."
```

### Activate/deactivate

```bash
curl -X POST "$N8N_URL/api/v1/workflows/$ID/activate" -H "X-N8N-API-KEY: $KEY"
curl -X POST "$N8N_URL/api/v1/workflows/$ID/deactivate" -H "X-N8N-API-KEY: $KEY"
```

## Common workflow patterns

### Lead → CRM → email

Trigger: webhook (form submission) or HTTP polling (Webflow form, WordPress form).
Steps:
1. Webhook (or HTTP) trigger
2. Set: clean/normalize fields
3. HubSpot: Create or Update Contact (skill `hubspot-workflows`)
4. Mailcoach: Add Subscriber to list with tags (skill `mailcoach-sending`)
5. Slack: Notify #leads channel
6. Respond to webhook (200 OK)

### Daily report

Trigger: Cron (8am EST daily).
Steps:
1. Cron trigger
2. GA4: Pull yesterday's metrics (HTTP node hitting GA4 Data API)
3. GSC: Pull yesterday's clicks/impressions
4. Function: Format markdown report
5. Slack: Post to channel
6. Notion: Append row to metrics database

### CRM sync (HubSpot ↔ Notion)

Trigger: Cron (every 30 min).
Steps:
1. HubSpot: List contacts updated since last run (use cursor variable)
2. Loop: For each contact
3. Notion: Find existing page by HubSpot ID property
4. Notion: Update or Create page
5. Set last-run cursor

### Content pipeline trigger

Trigger: Notion change (poll database for status changes).
Steps:
1. Notion poll
2. Filter: Status = Scheduled
3. Switch by Channel
   - Blog: HTTP to WP REST API to schedule post
   - LinkedIn: HTTP to LinkedIn API (or buffer integration)
   - Email: Mailchimp/Mailcoach create campaign
4. Notion: Update Status to Published, Publish Date to now

## JSON workflow manipulation

n8n exports are JSON. For bulk edits (e.g., updating credentials, env-specific URLs):

```
cdx "GOAL: For all n8n workflow JSONs in ./.scratch/workflows/, replace dev URLs with production URLs.
MAP: ./.scratch/url-replacements.json
SUCCESS: each workflow updated, originals backed up to ./.scratch/workflows-backup/.
RETURN: STATUS + SUMMARY (count modified)."
```

## Credential management

n8n stores credentials encrypted. Cannot be exported in plaintext via API. For new env:
1. Export workflows (no credentials)
2. Import on new env
3. Re-create credentials in UI
4. Reattach to nodes

For automation, define credentials via env vars where node supports it (e.g., HTTP Request node with header auth via expression).

## Brand-specific recipes

### WORK (your day-job brand): nurse outreach pipeline

LinkedIn lead form → HubSpot → Mailcoach (specialty/state-tagged sequence) → Slack notify BD owner.

### SIDE: client report builder

Cron monthly → pull GA4/GSC/HubSpot per client → render markdown via template → save to Notion + email PDF to client.

### OTHER (your wellness brand): affiliate link tracker

Webhook from affiliate dashboards → log to Notion (clicks/conversions) → weekly Slack digest.

### MAIN (your main brand): product launch

Notion status change to "Launched" → trigger:
- WP create post
- Mailchimp send to launch segment
- Social: LinkedIn + X post via buffer/zapier
- Slack notify

## Pitfalls

- API key requires Pro+ self-host or paid n8n.cloud. Free self-host doesn't have API.
- Webhooks require public URL (use ngrok or Cloudflare tunnel for dev).
- Workflow JSON has `nodes` and `connections` arrays. Edit both consistently.
- Function nodes (deprecated) → use Code node.
- Variables: workflow-level vs environment-level. Env vars set in Docker/host.

## Anti-patterns

- Putting credentials in workflow JSON.
- Long workflows (>30 nodes). Split into sub-workflows triggered via Execute Workflow.
- No error branches. Always handle the IF-error path.
- Polling when webhooks are available. Webhooks are cheaper.
