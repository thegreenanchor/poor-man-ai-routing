---
name: gsc-ops
description: Google Search Console operations via the Search Console API. Pull queries, pages, CTR, position data; submit sitemaps; inspect URLs; check coverage. Use when task references GSC, "Search Console," "search queries," "impressions," "indexing status," or "sitemap submission" for a verified property.
---

# GSC Ops

## Scope

Read and manage Google Search Console programmatically. Property must be verified by the user.

## Inputs

- Property URL (`https://example.com/` or `sc-domain:example.com`)
- Service account email added to GSC property as Owner or Full User
- `GOOGLE_APPLICATION_CREDENTIALS` env set

## Common operations

### Pull search analytics

Codex call:
```
cdx "GOAL: Pull GSC Search Analytics for <property>.
DIMENSIONS: query, page, country, device (whichever requested)
DATE RANGE: <start> to <end>
ROW LIMIT: 25000
OUTPUT: ./.scratch/gsc-<topic>-$(date +%Y-%m-%d).csv
CONSTRAINTS: Use python googleapiclient with searchconsole v1.
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

### Inspect URL (live indexing status)

```
cdx "GOAL: Use GSC URL Inspection API on these URLs: <list>.
OUTPUT: ./.scratch/gsc-inspect-$(date +%Y-%m-%d).json
For each: indexingState, crawlState, lastCrawlTime, robotsTxtState, canonical, mobileUsability.
RETURN: STATUS + SUMMARY (counts of indexed/notIndexed/blocked) + ARTIFACTS."
```

### Submit sitemap

```
cdx "GOAL: Submit sitemap https://<domain>/sitemap.xml to GSC for property <property>.
RETURN: STATUS + SUMMARY (response from API)."
```

### Coverage report

```
cdx "GOAL: List all sitemaps registered for <property>, plus per-sitemap stats: lastSubmitted, lastDownloaded, errors, warnings, contents.submitted, contents.indexed.
OUTPUT: ./.scratch/gsc-coverage-$(date +%Y-%m-%d).json
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

## Code template (Python)

```python
from googleapiclient.discovery import build
from google.oauth2 import service_account

SCOPES = ['https://www.googleapis.com/auth/webmasters.readonly']
creds = service_account.Credentials.from_service_account_file(
    KEY_PATH, scopes=SCOPES
)
service = build('searchconsole', 'v1', credentials=creds)

# Search analytics
req = {
    'startDate': '2026-02-01',
    'endDate': '2026-04-30',
    'dimensions': ['query', 'page'],
    'rowLimit': 25000
}
resp = service.searchanalytics().query(siteUrl=PROPERTY, body=req).execute()
# resp['rows'] has: keys (dimensions), clicks, impressions, ctr, position
```

## Standard reports

### Top queries (last 90 days)

```python
{
    'startDate': '90daysAgo',
    'endDate': 'today',
    'dimensions': ['query'],
    'rowLimit': 1000,
    'orderBy': [{'fieldName': 'clicks', 'sortOrder': 'DESCENDING'}]
}
```

### Pages with high impressions, low CTR (ranking but not converting)

Pull dimensions `page`, sort by impressions, post-process: filter ctr < 2% AND impressions > 100. These are title/meta optimization opportunities.

### Position decay (queries dropping over time)

Two date ranges: last 30 days vs prior 30 days. Same query dimension. Compare position. Sort by position increase desc → these are losing rankings.

### Indexed vs submitted gap

Coverage report: `submitted - indexed = gap`. If gap is large, inspect a sample to diagnose.

## Quotas

- 50 queries per second per property
- 1200 per minute per Cloud project
- Plenty for standard reports

## Synthesis pattern

For an SEO audit deliverable, GSC data feeds:

1. **Top queries table** (top 50 by clicks, last 90 days)
2. **Opportunity queries** (high impressions, low CTR, position 4-15)
3. **Page-level performance** (top pages by clicks, CTR distribution)
4. **Indexing health** (% of submitted URLs indexed)
5. **Mobile usability errors** if any

Synthesis sits in `seo-audit` skill.

## Related skills

- `seo-audit` — uses gsc-ops as input
- `ga4-reporting` — first-party traffic data, complementary

## Pitfalls

- GSC data has 16-month retention. Anything older requires backed-up exports.
- Aggregated data sampling: very high-volume properties get sampled. The API still works, just note totals.
- "Position" is averaged across impressions. Treat as directional.
- Domain property (`sc-domain:example.com`) vs URL property (`https://example.com/`) return different scopes. Pick one.
