---
name: webflow-builds
description: Webflow site/page/component operations beyond what the Webflow MCP covers. Use for advanced page builds, component composition at scale, asset uploads, CMS imports, custom code injection, and SEO setup. Trigger for any task involving Webflow that needs scripted volume or specific patterns.
---

# Webflow Builds

## Scope

This skill complements the connected Webflow MCP. The MCP handles individual element/component/page CRUD. This skill covers:
- Bulk CMS imports
- Component library maintenance
- Asset operations at scale
- Custom code (head/footer) injection
- Cross-page SEO setup
- Form/webhook configuration

## Inputs

- Site ID (`WEBFLOW_SITE_ID`)
- API token (`WEBFLOW_TOKEN`)
- For Designer Extension features: app must be installed on the site

## Common operations

### Bulk CMS import

```
cdx "GOAL: Import items into Webflow CMS collection <collection_id>.
INPUT: ./.scratch/cms-items.csv (columns matching collection schema)
METHOD: POST /collections/<id>/items/bulk (max 100 per call)
SUCCESS: all items created, errors logged.
OUTPUT: ./.scratch/webflow-import-results.csv
RETURN: STATUS + SUMMARY (created count, errors) + ARTIFACTS."
```

### Update field across collection items

```
cdx "GOAL: For all items in collection <collection_id> where field <X> = <Y>, set field <Z> = <W>.
METHOD: GET /collections/<id>/items paginated, filter, PATCH each.
RETURN: STATUS + SUMMARY (count updated) + ARTIFACTS."
```

### Asset upload

```
cdx "GOAL: Upload image to Webflow site <site_id>.
FILE: ./.scratch/images/hero.jpg
ENDPOINT: POST /sites/<site_id>/assets (returns presigned URL)
THEN: PUT to S3 URL with file content
RETURN: STATUS + SUMMARY (asset URL) + EVIDENCE (asset ID)."
```

### Page custom code injection

```
cdx "GOAL: Add tracking script to head of all pages on site <site_id>.
SCRIPT: ./.scratch/tracking.html
METHOD: Per-page or via site-level Custom Code (depending on need).
ENDPOINT: PATCH /pages/<page_id>/dom or via site settings.
RETURN: STATUS + SUMMARY (pages updated)."
```

### Component composition

For Webflow Components (V2 with the Designer API):
- Read component instances: GET /sites/<id>/components
- Update properties: PATCH /sites/<id>/components/<component_id>/dom

For complex builds, the Designer Extension API (run inside Webflow Designer) gives more control. This is interactive, not headless.

## Code template (Python)

```python
import os, requests
TOKEN = os.environ['WEBFLOW_TOKEN']
SITE = os.environ['WEBFLOW_SITE_ID']
HEADERS = {
    'Authorization': f'Bearer {TOKEN}',
    'accept-version': '2.0.0',
    'Content-Type': 'application/json',
}

# List collections
r = requests.get(
    f'https://api.webflow.com/v2/sites/{SITE}/collections',
    headers=HEADERS
)
```

## Publishing

After changes, sites need to be published:

```
cdx "GOAL: Publish Webflow site <site_id> to production domain.
ENDPOINT: POST /sites/<site_id>/publish with {publishToWebflowSubdomain: true, customDomains: [<list>]}
RETURN: STATUS + SUMMARY (publish queue id, domains)."
```

Publishing is queued; check status via the queue endpoint.

## CMS schema management

Adding/removing fields requires the schema endpoint:

```
cdx "GOAL: Add new field to Webflow collection <id>.
FIELD: name='Featured', slug='featured', type='Switch', required=false
ENDPOINT: POST /collections/<id>/fields
RETURN: STATUS + SUMMARY (field ID)."
```

## SEO setup at scale

For each page or CMS template:
- SEO title (auto-truncated to 60 chars in API: enforce yourself)
- SEO meta description (160 chars)
- Open Graph image
- Sitemap inclusion (toggle)
- Indexing flag

```
cdx "GOAL: Set SEO defaults for all blog post CMS items.
RULE: title = '{name} | SIDE', meta_description = first 155 chars of summary, og_image = featured_image.
METHOD: GET items, transform, PATCH each.
RETURN: STATUS + SUMMARY (count updated) + ARTIFACTS."
```

## Forms and webhooks

```
cdx "GOAL: Create webhook subscription for form submissions on site <site_id>.
ENDPOINT: POST /sites/<site_id>/webhooks
TRIGGER: form_submission
URL: <user-provided handler URL>
RETURN: STATUS + SUMMARY (webhook id)."
```

## Brand context

- SIDE: own site likely on Webflow + WP for blog. Some clients on Webflow.
- For client work: confirm site_id before any write op.

## Pitfalls

- API v1 vs v2: v1 still works but is deprecated. Always use v2 (`accept-version: 2.0.0`).
- CMS items need `cmsLocaleId` for multi-locale sites.
- Slug uniqueness enforced; if importing, dedupe slugs first.
- Asset CDN URLs change between staging/production.
- Custom code limit: per-page custom code has size limits.

## Anti-patterns

- Editing live site without staging or backup.
- Bulk operations without rate limiting (60/min default).
- Hardcoding component IDs in skills.
- Asset uploads without compression (eat bandwidth).
