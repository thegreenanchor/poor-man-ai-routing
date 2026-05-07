---
name: meta-ads-api
description: Meta (Facebook/Instagram) Marketing API operations. Pull ad performance data, audit creatives, retrieve audiences, build reports across campaigns/adsets/ads. Use for any task involving Meta Ads, Facebook Ads, Instagram Ads, or referencing campaign metrics like CPA, ROAS, CPM, CTR within Meta. Routes API calls to Codex; analysis to Claude.
---

# Meta Ads API

## Scope

Read and (where needed) manage Meta Ads via the Marketing API v19.0+. Account must be set up with a registered app, system user token, or user access token with `ads_read` (and `ads_management` for writes).

## Inputs

- Ad Account ID (`act_XXXXXXXXX`)
- Access token (`META_ACCESS_TOKEN` env var)
- API version (default `v20.0`, update yearly)

## Common operations

### Pull insights (performance data)

```
cdx "GOAL: Pull Meta Ads insights for account <act_id>.
LEVEL: ad | adset | campaign
FIELDS: impressions, reach, clicks, ctr, cpm, spend, actions (for conversions), cost_per_action_type
DATE RANGE: <start>..<end>
BREAKDOWNS: <if any: age, gender, placement, region>
OUTPUT: ./.scratch/meta-insights-<level>-$(date +%Y-%m-%d).csv
RETURN: STATUS + SUMMARY (totals: spend, impressions, clicks) + ARTIFACTS."
```

### List active campaigns

```
cdx "GOAL: List all active campaigns in <act_id> with: id, name, objective, status, daily_budget, lifetime_budget, created_time.
OUTPUT: ./.scratch/meta-campaigns-active-$(date +%Y-%m-%d).csv
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

### Pull creatives

```
cdx "GOAL: For each ad in <act_id> with status=ACTIVE, pull creative: id, name, image_url or video_id, body, title, link, call_to_action_type.
OUTPUT: ./.scratch/meta-creatives-$(date +%Y-%m-%d).csv plus thumbnails to ./.scratch/images/meta/
RETURN: STATUS + SUMMARY (creative count, image count) + ARTIFACTS."
```

### Pull custom audiences

```
cdx "GOAL: List custom audiences in <act_id>: id, name, approximate_count, retention_days, customer_file_source, time_created.
OUTPUT: ./.scratch/meta-audiences-$(date +%Y-%m-%d).csv
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

## Code template (Python with `facebook_business` SDK)

```python
from facebook_business.api import FacebookAdsApi
from facebook_business.adobjects.adaccount import AdAccount
import csv, os

FacebookAdsApi.init(access_token=os.environ['META_ACCESS_TOKEN'])
account = AdAccount(f"act_{ACCOUNT_ID}")

insights = account.get_insights(
    fields=['campaign_name','spend','impressions','clicks','ctr','cpm','actions'],
    params={
        'level': 'campaign',
        'time_range': {'since': '2026-04-01', 'until': '2026-04-30'},
        'limit': 1000,
    }
)
# Iterate pages; write CSV
```

## Reporting templates

### ROAS by campaign

Fields: `spend`, `actions` (filtered to `purchase` or `offsite_conversion.fb_pixel_purchase`), `action_values` (revenue).
Compute: `revenue / spend = ROAS`.

### Funnel by adset

Fields per adset: `impressions → clicks → landing_page_views → leads/purchases`.
Compute: CTR, LP-view rate, conversion rate.

### Creative fatigue check

Pull insights with `breakdown: hourly_stats_aggregated_by_advertiser_time_zone` not useful; use date breakdown over time, watch for CTR decay > 30% week-over-week.

### Audience overlap

Use Audience Overlap report endpoint for custom audiences sharing populations.

## Writes (use sparingly)

For pause/enable, budget changes, etc., use:

```python
from facebook_business.adobjects.campaign import Campaign
Campaign(CAMPAIGN_ID).api_update(params={'status': 'PAUSED'})
```

Always confirm with user before any write that affects spend or live ads.

## Compliance notes

- Conversions API server-side events: separate setup, not covered here. Ask user if needed.
- Ad creative review: Meta auto-rejects sometimes. If a creative is in `DISAPPROVED` state, the issue is in Ads Manager, not API.
- Spend caps: respect account-level limits.

## Brand context

For your operations:
- WORK (your day-job brand): B2B-ish via Meta is harder. Usually awareness or recruitment funnel.
- OTHER (your wellness brand): D2C affiliate. Conversion-focused. Watch ROAS.
- MAIN (your main brand): D2C product/info. Watch CPA + LTV.
- SIDE: agency clients, ad accounts vary.

## Common pitfalls

- Treating `clicks` as `link_clicks`. Use `inline_link_clicks` for actual link clicks.
- Forgetting attribution window. Default Meta is 7-day click + 1-day view. Document on every report.
- Pulling `impressions` from ad-set when really wanting deduplicated reach. Use `reach`.
- API version drift. Update version yearly when Meta deprecates old ones.

## Anti-patterns

- Building dashboards in Claude. Codex pulls, writes CSV, hand off to xlsx skill or external BI.
- Auto-pausing ads on metrics without user confirmation.
- Storing access tokens in scratch files. Always env vars.
