---
name: mailchimp-campaigns
description: Mailchimp Marketing API operations. Create/update campaigns, manage audiences and segments, run reports, automate list maintenance. Use when task references Mailchimp, Mailchimp campaigns, audience hygiene, or list segmentation. The WORK (your day-job brand) brand may use Mailcoach instead; check before defaulting to Mailchimp.
---

# Mailchimp Campaigns

## Scope

API operations on Mailchimp Marketing API v3.0. Suitable for SIDE clients, OTHER (your wellness brand), MAIN (your main brand) (any brand on Mailchimp).

For Mailcoach (likely used at WORK (your day-job brand)), see skill `mailcoach-sending`.

## Inputs

- API key (`MAILCHIMP_API_KEY` env, format `xxxxxxxx-usX`)
- Server prefix (the `usX` from the key)
- Audience (list) ID (`MAILCHIMP_LIST_ID`)

## Common operations

### Create campaign

```
cdx "GOAL: Create Mailchimp regular campaign.
LIST_ID: <list_id>
SUBJECT: '<subject>'
FROM_NAME: '<name>'
REPLY_TO: '<email>'
TITLE: '<internal title>'
TEMPLATE: html at ./.scratch/email-html.html (already prepared)
SUCCESS: campaign created in draft state, returns campaign_id.
ENDPOINT: POST /campaigns; then PUT /campaigns/<id>/content
RETURN: STATUS + SUMMARY (campaign_id, edit URL) + ARTIFACTS."
```

### Send campaign (after review)

```
cdx "GOAL: Send Mailchimp campaign <campaign_id>.
PRECHECK: campaign must be in 'save' status, content set, list assigned.
ENDPOINT: POST /campaigns/<campaign_id>/actions/send
RETURN: STATUS + SUMMARY (send time, recipient count)."
```

Note: do not auto-send. User must explicitly confirm in the prompt.

### Audience hygiene

```
cdx "GOAL: Identify cleanup candidates in Mailchimp list <list_id>.
CRITERIA:
  - Status = unsubscribed
  - OR Status = cleaned (bounced)
  - OR EMAIL_TYPE invalid
  - OR last_changed > 12 months ago AND no opens/clicks ever
OUTPUT: ./.scratch/mc-cleanup-candidates-$(date +%Y-%m-%d).csv
RETURN: STATUS + SUMMARY (count by category) + ARTIFACTS."
```

### Segmentation

```
cdx "GOAL: Create static segment in Mailchimp list <list_id>.
NAME: '<segment name>'
EMAIL LIST: ./.scratch/segment-emails.txt (one per line)
ENDPOINT: POST /lists/<list_id>/segments with options.static_segment
RETURN: STATUS + SUMMARY (segment_id, member count)."
```

### Reports

```
cdx "GOAL: Pull Mailchimp campaign report for <campaign_id>.
METRICS: emails_sent, opens.unique_opens, opens.open_rate, clicks.unique_subscriber_clicks, clicks.click_rate, unsubscribed, bounces.hard_bounces, bounces.soft_bounces.
ENDPOINT: GET /reports/<campaign_id>
RETURN: STATUS + SUMMARY (formatted metrics) + ARTIFACTS (json dump)."
```

## Code template (Python)

```python
import os, requests
DC = os.environ['MAILCHIMP_API_KEY'].split('-')[1]  # us21 etc.
KEY = os.environ['MAILCHIMP_API_KEY']
BASE = f'https://{DC}.api.mailchimp.com/3.0'

r = requests.get(f'{BASE}/lists/{LIST_ID}/members',
    auth=('any', KEY),
    params={'count': 1000, 'status': 'subscribed'})
```

## A/B test (variate campaign)

```
cdx "GOAL: Create variate (A/B) campaign in Mailchimp.
TYPE: variate
LIST_ID: <list_id>
TEST_SETTINGS:
  winner_criteria: opens
  wait_time: 240 (minutes)
  test_size: 25 (percent)
  combinations: 2 (subject lines)
SUBJECT_VARIANTS: ['<A>', '<B>']
RETURN: STATUS + SUMMARY (campaign_id)."
```

## Templates

If using Mailchimp's classic template editor, content goes in `template.id` + section overrides. For HTML drag-and-drop or pasted HTML, use the `html` field on the content endpoint.

## Brand voice

Per brand:
- SIDE: grounded, practical. Subjects under 50 chars. Preheader benefits-focused.
- OTHER (your wellness brand): supportive, realistic. Avoid hype subjects. Approachable.
- MAIN (your main brand): direct, value-first. Subject = the value, not curiosity.

Always run final copy through `reviewer` subagent before send.

## Compliance

- Audience must be opt-in (CAN-SPAM and GDPR).
- Unsubscribe link required (Mailchimp adds automatically).
- Physical address in footer (Mailchimp adds from list defaults).
- For EU recipients: confirm GDPR consent stored on each subscriber.

## Pitfalls

- Send time UTC-based by default; user time zone scheduling needs `send_time` in ISO format.
- List_id ≠ web_id ≠ unique_id. List_id is the API one (10-char alphanumeric).
- Hard bounces auto-clean. Soft bounces are retried.
- Sending to a recently-imported segment without cool-down can trip spam filters.

## Anti-patterns

- Auto-sending campaigns from script without review. Always send to draft, alert user.
- Storing the API key in plaintext config. Env vars only.
- Creating segments in code when a saved segment already exists.
