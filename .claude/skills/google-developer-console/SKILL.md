---
name: google-developer-console
description: Google Cloud / Developer Console operations: project setup, API enablement, service account management, OAuth client setup, IAM, and quotas. Use when task involves "GCP project," "service account," "API key," "OAuth credentials," or any Google API access setup that supports other skills (GA4, GSC, Drive, etc.).
---

# Google Developer Console

## Scope

GCP project administration, primarily for enabling APIs and minting credentials that the marketing/analytics skills consume.

## Tools

- Web UI: console.cloud.google.com
- CLI: `gcloud` (install: https://cloud.google.com/sdk/docs/install)
- API: Cloud Resource Manager + IAM APIs (rare; UI/CLI usually sufficient)

## Common tasks

### Create a project (one-time per environment)

```bash
# In gcloud
PROJECT_ID="myproject-prod-$(date +%s)"
gcloud projects create "$PROJECT_ID" --name="My Project (Prod)"
gcloud config set project "$PROJECT_ID"

# Link billing (required for most APIs)
gcloud billing accounts list
gcloud billing projects link "$PROJECT_ID" --billing-account=<billing-account-id>
```

### Enable APIs

For the stack assumed here, common enables:

```bash
gcloud services enable \
  analyticsdata.googleapis.com \
  searchconsole.googleapis.com \
  drive.googleapis.com \
  sheets.googleapis.com \
  gmail.googleapis.com \
  calendar-json.googleapis.com \
  pagespeedonline.googleapis.com \
  generativelanguage.googleapis.com \
  aiplatform.googleapis.com
```

### Service account (server-to-server auth)

```bash
SA_NAME="data-pipeline"
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="Data Pipeline Service Account"

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant roles (minimal: API user, no admin)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageConsumer"

# Create JSON key (store securely; do NOT commit)
gcloud iam service-accounts keys create ./.scratch/sa-key.json \
  --iam-account="$SA_EMAIL"
```

For specific resources (GA4, GSC, Drive), the SA email also needs to be added at the resource level (not just the project).

### OAuth 2.0 client (user-consent flows)

For applications that act on a user's behalf (e.g., posting to user's Drive):

```bash
# OAuth clients aren't easily made via gcloud; use UI:
# Console → APIs & Services → Credentials → Create credentials → OAuth client ID
# Application type: Web app or Desktop
# Authorized redirect URIs: as needed
```

Save client_id and client_secret to env vars; do not commit.

### API key (public APIs, no user data)

For PageSpeed Insights, Maps, etc.:

```bash
gcloud services api-keys create --display-name="PSI key"
# Restrict by API and HTTP referrer / IP for safety
```

## IAM patterns

### Roles

- `roles/viewer` — read-only across project. Too broad in most cases.
- `roles/serviceusage.serviceUsageConsumer` — required to call enabled APIs as the service account.
- `roles/storage.objectViewer` — read GCS buckets.
- Plus resource-specific roles (BigQuery, etc.) only as needed.

Principle: minimal roles. Add granularly per use case.

### Service account impersonation

For users to act as a service account temporarily:

```bash
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --member="user:[your email]" \
  --role="roles/iam.serviceAccountTokenCreator"

# Then user can:
gcloud auth application-default login --impersonate-service-account="$SA_EMAIL"
```

Better than handing out the JSON key for personal use.

## Quota management

Quotas are per-project, per-API. View at:
- Console → IAM & Admin → Quotas
- Or: `gcloud services list --enabled` then check each API's quota page

Common quota issues:
- GA4 Data API: 25k requests/property/day
- Search Console: 1200/min/project
- Drive: varies by tier

If hitting quotas: split projects, request increases via console.

## Setup workflows for each skill

### For ga4-reporting

1. Enable `analyticsdata.googleapis.com`.
2. Create service account.
3. In GA4 Admin → Property Access Management, add SA email as Viewer.
4. Set `GOOGLE_APPLICATION_CREDENTIALS` to JSON key path.

### For gsc-ops

1. Enable `searchconsole.googleapis.com`.
2. Create service account.
3. In GSC → Settings → Users and permissions, add SA email as Owner or Full User for the property.
4. Set env.

### For Gemini API (Nano Banana, etc.)

1. Enable `generativelanguage.googleapis.com`.
2. Create API key (restricted).
3. Set `GOOGLE_API_KEY` env.

## Multi-environment pattern

For your brands:

```
mna-prod-XXXXXX        — WORK (your day-job brand) production data pulls
greenanchor-clients-XX — multi-tenant for client analytics
tga-prod-XXXXXX        — OTHER (your wellness brand)
shl-prod-XXXXXX        — MAIN (your main brand)
sandbox-XXXXXX         — experiments, throwaway
```

One project per brand keeps quotas, billing, and access clean. Avoid one-project-for-everything; quota collisions get nasty.

## Audit and rotation

Quarterly: review service accounts, API keys, OAuth clients. Rotate keys older than 90 days.

```bash
# List service account keys
gcloud iam service-accounts keys list --iam-account="$SA_EMAIL"

# Delete old key
gcloud iam service-accounts keys delete <KEY_ID> --iam-account="$SA_EMAIL"
```

## Common pitfalls

- Forgetting to add SA to the resource (GA4 property, GSC site). API call returns 403; the message is unhelpful.
- API not enabled. First call returns 403 with "API has not been enabled for project."
- Billing not linked. Many APIs refuse without billing even within free tier.
- Region-specific: some APIs limited per region (Vertex AI). Check.
- Default SA used for everything. Bad blast radius if compromised.

## Anti-patterns

- Committing JSON keys to git.
- Granting `roles/owner` to a SA.
- Using one SA across all environments.
- Not setting up org policy / VPC service controls for sensitive data (out of scope here, but flag for client work).
