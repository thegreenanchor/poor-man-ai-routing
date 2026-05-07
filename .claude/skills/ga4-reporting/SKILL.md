---
name: ga4-reporting
description: Pull and analyze Google Analytics 4 data via the GA4 Data API. Use for traffic reports, conversion analysis, audience insights, channel performance, landing page audits, or any task referencing GA4, "Analytics," "sessions," "conversions," or "user behavior" on a website. Routes pulls to Codex (API calls) and synthesis to Claude.
---

# GA4 Reporting

## Scope

Reading GA4 data via the Data API (`google-analytics-data`). Property must already exist and have data.

## Inputs needed

- GA4 Property ID (numeric, e.g. `321654987`)
- Service account JSON with GA4 viewer access OR OAuth token
- Date range
- Dimensions and metrics to pull

## Auth setup (one-time)

User must:
1. Create service account in Google Cloud Console.
2. Add the service account email as a Viewer in GA4 Admin → Property → Property Access Management.
3. Download the JSON key.
4. Set env var: `GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`.

If not set up: return STATUS: blocked with these steps.

## Process

### Step 1 — Frame the question

What does the user actually need? Examples:
- "Organic traffic trend last 90 days"
- "Top converting landing pages"
- "Channel comparison: organic vs paid vs direct"
- "Funnel: landing → signup → paid"
- "Devices/geos with highest conversion rate"

Translate into GA4 dimensions + metrics.

### Step 2 — Pull (Codex)

```
cdx "GOAL: Pull GA4 report for property <PROPERTY_ID>.
DIMENSIONS: <dim1>, <dim2>
METRICS: <metric1>, <metric2>
DATE RANGE: <start> to <end>
FILTERS: <if any>
OUTPUT: ./.scratch/ga4-<topic>-$(date +%Y-%m-%d).csv
CONSTRAINTS: Use python google-analytics-data SDK. GOOGLE_APPLICATION_CREDENTIALS env set.
RETURN: STATUS + SUMMARY (row count, totals) + ARTIFACTS."
```

### Step 3 — Synthesis (Claude)

Read the CSV summary (counts, totals). For deep analysis, ask Codex to compute on the CSV (averages, segments, comparisons) before pulling into context.

```
cdx "GOAL: Compute YoY change per landing page for ./.scratch/ga4-landing-pages-2026-05-06.csv.
SUCCESS: output CSV with columns: landingPage, sessions_current, sessions_prior, pct_change, sorted by pct_change desc.
RETURN: STATUS + SUMMARY (top 5 gainers, top 5 decliners) + ARTIFACTS."
```

## Common reports

### Traffic overview (channel)

Dimensions: `sessionDefaultChannelGroup`, `date`
Metrics: `sessions`, `engagedSessions`, `engagementRate`, `conversions`, `totalRevenue`

### Top landing pages

Dimensions: `landingPage`
Metrics: `sessions`, `engagedSessions`, `engagementRate`, `conversions`, `conversionRate`
Order: `sessions` desc
Limit: 50

### Source/Medium

Dimensions: `sessionSource`, `sessionMedium`
Metrics: `sessions`, `conversions`, `totalRevenue`

### Device/Geo

Dimensions: `deviceCategory`, `country` (or `region`, `city`)
Metrics: `sessions`, `engagementRate`, `conversionRate`

### Events / conversions

Dimensions: `eventName`
Metrics: `eventCount`, `eventCountPerUser`

### Funnel (using Explorations equivalent)

Use `runReport` with multiple metrics filtered by event name. Or use the Explorations API for true funnels (more complex; usually CSV export is fine).

## Code template (Python, inside Codex)

```python
from google.analytics.data_v1beta import BetaAnalyticsDataClient
from google.analytics.data_v1beta.types import (
    DateRange, Dimension, Metric, RunReportRequest
)
import csv, sys

client = BetaAnalyticsDataClient()
req = RunReportRequest(
    property=f"properties/{PROPERTY_ID}",
    dimensions=[Dimension(name=d) for d in DIMS],
    metrics=[Metric(name=m) for m in METS],
    date_ranges=[DateRange(start_date=START, end_date=END)],
    limit=10000,
)
resp = client.run_report(req)
# Write CSV
with open(OUT, "w", newline="") as f:
    w = csv.writer(f)
    w.writerow([d.name for d in resp.dimension_headers] + [m.name for m in resp.metric_headers])
    for row in resp.rows:
        w.writerow([d.value for d in row.dimension_values] + [v.value for v in row.metric_values])
```

## Date range conventions

- "last 30 days" → end = `today`, start = `30daysAgo`
- "last full month" → compute first/last of prior month
- "YoY" → two date ranges: current period + same length 1 year prior

GA4 API accepts both relative strings (`30daysAgo`) and `YYYY-MM-DD`.

## Quotas and limits

- 10,000 rows per request (use `offset` for pagination)
- 10 dimensions max per request
- 10 metrics max per request
- 25,000 requests per property per day (plenty for normal use)

## Output format options

- CSV (default, easiest for handoff to xlsx skill)
- JSON (for programmatic consumption)
- Markdown table (for inline display when small)

Synthesis stage usually wants either CSV → xlsx or markdown summary table.

## Brand context

For the properties tracked:
- WORK: usually conversion-focused (lead form submits)
- SIDE: traffic + engagement (blog, services)
- OTHER (your wellness brand): affiliate clicks, time on page
- MAIN (your main brand): similar to SIDE, plus product purchase events

## Common pitfalls

- Forgetting to filter out internal traffic. Confirm IP filter is set in GA4 admin.
- Comparing dates that include holiday spikes without context.
- Using `users` when meaning `sessions`. Default to `sessions` unless user is a clearly wanted dimension.
- Pulling too many dimensions in one request (cardinality explosion). Split.

## Anti-patterns

- Pulling raw export then summarizing in Claude context. Always: Codex pulls, Codex computes, Claude reads summary.
- Building dashboards in Claude. Hand off to BI tool or static report (xlsx skill).
- Forgetting to cite the date range in the deliverable.
