---
name: osint-toolkit
description: Open-source intelligence gathering on people, companies, domains, and digital assets. Public sources only. Use for "background check" (public), "company research," "domain investigation," "social presence," "digital footprint" tasks. Coordinates Gemini for search, Codex for tool runs, and respects strict ethical boundaries.
---

# OSINT Toolkit

## Hard ethical rules

OSINT operates on **public data** only. Never:
- Bypass logins, paywalls, CAPTCHAs.
- Scrape data behind authentication.
- Compile lists of personal information beyond what the task requires.
- Gather facial images.
- Use breach data for unauthorized access.
- Investigate individuals without a clear legitimate purpose.

If a task crosses these lines, return STATUS: blocked and ask for context (e.g., is this for an authorized investigation, due diligence, etc.).

## Use cases

- Pre-sales due diligence on a prospect company.
- Vendor evaluation.
- Domain ownership history.
- Brand monitoring.
- Threat intel on a domain (is it a phishing copycat of mine?).
- Self-audit (what's public about me?).

## Domain OSINT

```
cdx "GOAL: OSINT on domain <domain>.
PASSIVE ACTIONS:
  1. WHOIS (current + historical via WhoisXML or domaintools if API key set)
  2. DNS records (A, AAAA, MX, NS, TXT, CAA)
  3. Subdomain enumeration (subfinder, crt.sh API)
  4. Certificate transparency log
  5. Wayback Machine snapshots: oldest, key milestones, recent
  6. BuiltWith / Wappalyzer-style tech stack detection
  7. Public S3/Azure/GCS bucket discovery (e.g. <domain>-backups, <domain>-data) – fingerprint only, do not retrieve contents
OUTPUT: ./.scratch/osint/<domain>-$(date +%Y-%m-%d)/
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

Plus Gemini for context:

```
gca "TOPIC: Recent news, regulatory, or breach mentions of <domain>.
SCOPE: Last 12 months.
TIER: 2."
```

## Company OSINT

```
gca "TOPIC: Public OSINT on <Company Name>.
WHAT I NEED:
  - Official site URL
  - LinkedIn URL + employee count band
  - Industry, HQ, size band, founding year (Crunchbase or About page)
  - Funding (if applicable, Crunchbase / news)
  - Recent news (last 12 months, top 5)
  - Key people (leadership listed publicly)
  - Tech stack (BuiltWith)
TIER: 2."
```

Plus:

```
cdx "GOAL: WHOIS, DNS, subdomain enumeration on official domain.
[same as domain OSINT]"
```

## Person OSINT (use with caution)

Only for self-audit OR explicit authorization (e.g. background check on hire candidate with consent, executive due diligence).

```
gca "TOPIC: Public professional footprint of <person name + identifying context>.
WHAT I NEED:
  - LinkedIn profile URL
  - Public X/Twitter handle if discoverable
  - Public GitHub if developer
  - Public published works (articles, talks)
  - Company affiliation
SCOPE: Public profiles only. No contact information beyond public business email if listed.
TIER: 2."
```

If task requires non-professional details (home address, phone, family), return STATUS: blocked.

## Digital asset OSINT

For checking if your own assets are exposed:

```
cdx "GOAL: Self-audit on <my domain>.
ACTIONS:
  - Public S3/blob discovery
  - Exposed config files (.env, .git/config, server-status, phpinfo)
  - GitHub leak search for <domain> (use github-search-leaks tool or gh CLI)
  - Pastebin/leak-site mentions (Gemini search)
  - HaveIBeenPwned domain breach summary
RETURN: STATUS + SUMMARY (issues found, severity) + ARTIFACTS."
```

## Breach intel

```
gca "TOPIC: HaveIBeenPwned breach summary for domain <domain>.
SCOPE: Public summary endpoint.
WHAT I NEED:
  - Breaches affecting accounts on this domain
  - Date, type of data exposed
  - Recommendation: where to verify with users
TIER: 1."
```

Do not use breach data to attempt logins.

## Image OSINT (defensive only)

For checking if your brand imagery is being misused:

```
gca "TOPIC: Reverse image search on ./.scratch/brand-logo.png.
SCOPE: Public web.
WHAT I NEED:
  - URLs where this image appears
  - Sites NOT under our control
TIER: 2."
```

Never use this to identify individuals.

## Reporting structure

```
1. Subject (domain / company / asset)
2. Scope and Sources Used
3. Findings:
   - Asset Map (domains, subdomains, IPs, services)
   - Tech Stack
   - Public Mentions (news, social)
   - Exposure Indicators (breach data, public buckets, leaks)
4. Risk Assessment (if defensive scope)
5. Recommendations (if applicable)
6. References (URLs, dates)
```

## Privacy / GDPR considerations

When OSINT touches EU residents:
- Document legitimate interest basis.
- Limit data retention.
- Don't combine sources to deanonymize.
- Cite sources for all claims.

## Common pitfalls

- Combining anonymous data points to deanonymize. Even from public sources, this can violate GDPR.
- Treating screenshots from old archive snapshots as current state.
- Over-reliance on tools that hallucinate (some breach search APIs return false positives).
- Citing "sources" without verifying the source still exists.

## Anti-patterns

- Compiling personal info dossiers without explicit authorization.
- Storing OSINT findings beyond task lifetime without retention policy.
- Using OSINT data for unauthorized actions (credential stuffing, social engineering targeting).
- Mixing offensive and defensive contexts; this skill is reconnaissance, not exploitation.
