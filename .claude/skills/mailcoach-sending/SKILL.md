---
name: mailcoach-sending
description: Mailcoach (self-hosted email platform) operations via its REST API. Used at WORK (your day-job brand) for outreach and newsletter sending. Covers campaign creation, list management, sending, and reporting. Use when task references Mailcoach or WORK (your day-job brand) email operations.
---

# Mailcoach Sending

## Scope

Mailcoach is Spatie's self-hosted email tool, common for higher-volume outreach without Mailchimp pricing. WORK (your day-job brand) uses it.

API docs: https://mailcoach.app/docs/api

## Inputs

- Mailcoach instance URL (`MAILCOACH_URL`, e.g. `https://mail.mna.example.com`)
- API token (`MAILCOACH_TOKEN`)
- Email list UUID (`MAILCOACH_LIST_UUID`)

## Common operations

### Create campaign

```
cdx "GOAL: Create Mailcoach campaign.
ENDPOINT: POST /api/campaigns
BODY:
  name: '<internal name>'
  subject: '<subject>'
  email_list_uuid: '<list uuid>'
  html: <html content from file>
  from_email: '<from>'
  from_name: '<from name>'
  reply_to_email: '<reply>'
SUCCESS: campaign returned with uuid in draft.
RETURN: STATUS + SUMMARY (campaign uuid, edit URL)."
```

### Send campaign

Two-step: validate first, then send.

```
cdx "GOAL: Send Mailcoach campaign <uuid>.
STEP 1: GET /api/campaigns/<uuid> -> verify status: draft, html present, list assigned.
STEP 2: POST /api/campaigns/<uuid>/send
RETURN: STATUS + SUMMARY (sent_to, sent_at)."
```

User must explicitly approve in the prompt before sending.

### Add subscriber

```
cdx "GOAL: Add subscriber to list <list uuid>.
ENDPOINT: POST /api/email-lists/<list uuid>/subscribers
BODY: email, first_name, last_name, extra_attributes (JSON), tags (array)
RETURN: STATUS + SUMMARY (subscriber uuid, double opt-in status)."
```

### Bulk import subscribers

```
cdx "GOAL: Bulk import subscribers from ./.scratch/contacts.csv to Mailcoach list <list uuid>.
ENDPOINT: POST /api/email-lists/<list uuid>/subscribers (loop, with rate limiting)
SUCCESS: each row imported, errors logged.
OUTPUT: ./.scratch/mailcoach-import-results-$(date +%Y-%m-%d).csv
CONSTRAINTS: Rate limit 60 req/min. Use exponential backoff on 429.
RETURN: STATUS + SUMMARY (imported, errored, skipped) + ARTIFACTS."
```

### Tag-based segmentation

```
cdx "GOAL: Tag subscribers in list <list uuid> matching criteria.
CRITERIA: <criteria>
ACTION: add tag '<tag name>'
ENDPOINT: POST /api/subscribers/<uuid>/tags
RETURN: STATUS + SUMMARY (count tagged)."
```

### Reports

```
cdx "GOAL: Pull Mailcoach campaign stats for <uuid>.
ENDPOINT: GET /api/campaigns/<uuid>/statistics
METRICS: sent_to_number_of_subscribers, open_count, unique_open_count, click_count, unique_click_count, unsubscribe_count, bounce_count, complaint_count.
RETURN: STATUS + SUMMARY (open rate, click rate, unsubscribe rate, bounce rate)."
```

## Code template (Python)

```python
import os, requests, csv

URL = os.environ['MAILCOACH_URL'].rstrip('/')
TOKEN = os.environ['MAILCOACH_TOKEN']
HEADERS = {'Authorization': f'Bearer {TOKEN}', 'Accept': 'application/json'}

# Add subscriber
r = requests.post(
    f'{URL}/api/email-lists/{LIST_UUID}/subscribers',
    headers=HEADERS,
    json={'email': 'x@y.com', 'first_name': '[your name]', 'tags': ['icu','tx']}
)
```

## WORK (your day-job brand) playbook

Typical sequence:
1. Lead lands from LinkedIn or web form → HubSpot record created.
2. HubSpot workflow exports new leads to CSV daily (or via Zapier).
3. Daily import job pushes new leads to Mailcoach with appropriate tags (specialty, state, source).
4. Mailcoach automation sends sequenced touches based on tags.

If building this pipeline: skill `n8n-workflows` is a clean home for the connector logic.

## Brand voice for WORK

Confident, professional, human. Not hypey. Subject lines lead with value: "Open ICU contracts in [state] this month — [pay range]" beats "Don't miss out!".

Always run copy through `reviewer` subagent before send.

## Compliance

- CAN-SPAM compliant (Mailcoach handles unsubscribe link if list is configured).
- Physical mailing address in every send.
- Opt-in confirmation if double opt-in is enabled (`/api/email-lists/<uuid>` shows config).
- For nurse contacts: many states have additional outreach restrictions on licensed professionals. Verify with WORK legal before scaled outreach.

## Pitfalls

- Mailcoach 429s harder than Mailchimp. Rate limit yourself.
- Tags are case-sensitive.
- "Open" tracking requires HTML pixel, can be blocked. Open rate is directional.
- Bounces are pruned automatically only if soft-bounce threshold is hit.

## Anti-patterns

- Auto-sending without user explicit "send" confirmation.
- Importing without dedup against existing list (creates duplicates).
- Storing tokens in scratch files. Env only.
