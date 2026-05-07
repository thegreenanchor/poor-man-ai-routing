---
name: hubspot-workflows
description: HubSpot CRM operations beyond what the HubSpot MCP covers. Use for bulk imports/exports, custom property creation, advanced filtering, list segmentation logic, sequence enrollments, and reports that need API-level access. The HubSpot MCP handles common CRUD; this skill covers the gaps and structures bigger operations.
---

# HubSpot Workflows

## Scope

This skill complements the connected HubSpot MCP. Use the MCP for:
- Single-record CRUD (contacts, companies, deals)
- Standard searches
- Property reads

Use this skill for:
- Bulk imports/exports (>100 records)
- Custom property/object creation
- Workflow API operations
- Sequence management
- Report queries beyond MCP's scope

## Inputs

- HubSpot Private App access token (`HUBSPOT_TOKEN` env)
- Portal ID (for some endpoints)

## Common operations

### Bulk contact import

For >100 contacts, MCP is slow. Use Codex with the batch API:

```
cdx "GOAL: Import contacts from ./.scratch/leads-clean.csv into HubSpot.
COLUMNS REQUIRED: email, firstname, lastname (others optional)
SUCCESS:
  - All valid rows imported
  - Duplicate emails handled per HubSpot default (update existing)
  - Invalid rows logged to ./.scratch/import-errors.csv
CONSTRAINTS: Use HubSpot batch endpoint /crm/v3/objects/contacts/batch/upsert. Batch size 100.
RETURN: STATUS + SUMMARY (imported, updated, errored) + ARTIFACTS."
```

### Bulk export

```
cdx "GOAL: Export all contacts in HubSpot list <list_id> to CSV.
PROPERTIES: email, firstname, lastname, company, jobtitle, phone, lifecyclestage, hs_lead_status
OUTPUT: ./.scratch/hubspot-list-<id>-$(date +%Y-%m-%d).csv
CONSTRAINTS: Use /crm/v3/lists/<id>/memberships/join paginated.
RETURN: STATUS + SUMMARY (row count) + ARTIFACTS."
```

### Create custom property

```
cdx "GOAL: Create custom contact property 'mna_specialty_interest'.
TYPE: enumeration
OPTIONS: ['ICU','OR','ER','LD','NICU','PICU','MedSurg','Other']
GROUP: contactinformation
LABEL: 'Specialty Interest'
FORM_FIELD: true
RETURN: STATUS + SUMMARY (property URL in HubSpot UI)."
```

### Workflow enrollment

```
cdx "GOAL: Enroll contact <contact_id> in workflow <workflow_id>.
ENDPOINT: /automation/v2/workflows/<workflow_id>/enrollments/contacts/<vid>
RETURN: STATUS."
```

### Advanced search (CRM Search API)

```
cdx "GOAL: Find contacts where lifecyclestage=lead AND createdate within last 30 days AND lead_source=organic_search.
PROPERTIES TO RETURN: email, firstname, lastname, lead_score, last_activity_date
OUTPUT: ./.scratch/search-recent-organic-leads.csv
CONSTRAINTS: Use /crm/v3/objects/contacts/search with filterGroups.
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

## Code template (Python)

```python
import os, requests, csv

TOKEN = os.environ['HUBSPOT_TOKEN']
HEADERS = {'Authorization': f'Bearer {TOKEN}', 'Content-Type': 'application/json'}

# Search example
body = {
    "filterGroups": [{
        "filters": [
            {"propertyName": "lifecyclestage", "operator": "EQ", "value": "lead"},
            {"propertyName": "createdate", "operator": "GTE", "value": "1746489600000"}
        ]
    }],
    "properties": ["email","firstname","lastname"],
    "limit": 100
}
r = requests.post(
    'https://api.hubapi.com/crm/v3/objects/contacts/search',
    headers=HEADERS, json=body
)
```

## WORK (your day-job brand) specifics

For WORK outreach (your day-job pipeline):
- Contact lifecyclestage flow: subscriber → lead → marketingqualifiedlead → salesqualifiedlead → opportunity → customer
- Custom properties he likely uses: specialty, license_state, years_experience, current_employer
- Sequences: tied to BD outreach (LinkedIn → email → phone)
- Lists: probably segmented by specialty + state

If working on WORK specifics and the property names aren't confirmed, return DECISIONS NEEDED.

## Sequence enrollment (one-to-many)

```
cdx "GOAL: Enroll contacts in HubSpot sequence <sequence_id>.
INPUT: list of contact IDs in ./.scratch/contact-ids.txt
ENDPOINT: /automation/v3/sequences/enrollments
SUCCESS: each contact's enrollment status logged
OUTPUT: ./.scratch/sequence-enrollment-results.csv
CONSTRAINTS: Sequences API requires the sequence to be active. Skip already-enrolled contacts.
RETURN: STATUS + SUMMARY (enrolled, skipped, errored) + ARTIFACTS."
```

## Reports

For dashboard-style reports, use HubSpot's Reports API:

```
cdx "GOAL: Pull HubSpot report <report_id> data for last 30 days.
OUTPUT: ./.scratch/hubspot-report-<id>.json
RETURN: STATUS + SUMMARY (key numbers from report) + ARTIFACTS."
```

## Rate limits

- 100 requests / 10 seconds per private app
- 250,000 requests/day Pro, 500,000 Enterprise
- Use batch endpoints whenever possible (1 batch request = 1 against rate limit)

## Pitfalls

- HubSpot timestamps are milliseconds since epoch (not seconds). Convert.
- Search API returns max 200 properties; if you need all, use individual gets.
- Workflow enrollment for `enrollmentTrigger != API` workflows is restricted.
- Property internal names ≠ labels. Always use internal names in API calls.

## Anti-patterns

- Loop-update contacts when batch upsert is available.
- Re-pulling the same data instead of caching to scratch.
- Hard-coding portal-specific IDs in skills (keep them as input args).
- Auto-enrolling without confirmation when it triggers external sends.
