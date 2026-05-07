---
name: cybersec-recon
description: Cybersecurity reconnaissance workflows for authorized targets only. Covers passive recon (no traffic to target) and active recon (traffic, requires authorization). Coordinates with Kali tools, OSINT, and reporting. Trigger for "recon," "footprinting," "attack surface," "vulnerability assessment," "pentest scope" tasks. Strict legal scope.
---

# Cybersec Recon

## Hard legal rules

This skill operates ONLY on:
- Targets the user owns (verify with WHOIS or signed scope).
- Targets with written authorization in scope.
- Public bug bounty programs in scope (verify on HackerOne, Bugcrowd, Intigriti).
- Lab environments (HackTheBox, TryHackMe, OffSec ranges).

Before starting any active recon, the orchestrator must confirm the authorization basis. If unclear, return STATUS: blocked and ask.

## Recon types

### Passive (no traffic to target)

OSINT: WHOIS, DNS history, GitHub leaks, breach databases, archive snapshots, certificate transparency, news/social mentions. See skill `osint-toolkit`.

No legal exposure (data is public).

### Active (traffic to target)

Port scans, service enumeration, web crawling, vulnerability probing. **Authorization required.**

## Phases

1. **Scope confirmation**: targets, what's in/out, time window, methods allowed, points of contact.
2. **Passive recon**: OSINT chain, attack surface mapping.
3. **Active recon** (if authorized): port scans, service detection, version mapping.
4. **Vulnerability assessment** (if authorized): tool-driven scans (Nessus, OpenVAS, web app scanners).
5. **Reporting**: findings + severity + remediation.

## Passive recon chain

```
cdx "GOAL: Passive OSINT on <domain>.
INPUTS: <domain>
ACTIONS:
  1. WHOIS lookup
  2. DNS records (A, AAAA, MX, NS, TXT, CAA, CNAME enumeration)
  3. Subdomain enumeration via cert transparency (crt.sh)
  4. GitHub search for organization/domain
  5. Archive.org snapshots (oldest, key milestones)
  6. theHarvester emails/subdomains
TOOLS: whois, dig, subfinder, amass passive, theHarvester, crt.sh API
OUTPUT: ./.scratch/recon/<domain>/passive-$(date +%Y-%m-%d)/
RETURN: STATUS + SUMMARY (subdomain count, email count, key findings) + ARTIFACTS."
```

Plus a Gemini call:

```
gca "TOPIC: Public mentions of <domain> + breach database hits.
SCOPE: HaveIBeenPwned (public summary), GitHub code search, public S3 buckets, leaked credentials sites (public discussion only, do not retrieve credentials).
WHAT I NEED:
  - Breach summary (which breaches, exposure types)
  - Public mentions in security news
TIER: 2."
```

## Active recon chain (only if authorized)

```
cdx "GOAL: Active recon against authorized scope <scope>.
PHASES:
  1. Host discovery: nmap -sn -PE -PA <range> | nmap -Pn for filtered hosts
  2. Port scan: nmap -sS -p- --min-rate 1000 -oA ./.scratch/recon/full
  3. Service detection: nmap -sV -sC -p<open ports> -oA ./.scratch/recon/services
  4. Web service enumeration: for each web port, run gobuster, whatweb
TIME WINDOW: <start> to <end>
RATE LIMIT: --max-rate 5000 (adjust per scope agreement)
OUTPUT: ./.scratch/recon/<target>/active-$(date +%Y-%m-%d)/
RETURN: STATUS + SUMMARY (live hosts, open ports, services, surprising findings) + ARTIFACTS."
```

## Vulnerability assessment

For depth: Nessus, OpenVAS, Nuclei, ZAP. All require authorization and care.

```
cdx "GOAL: Run nuclei against <scope> with safe templates only.
SCOPE: <list>
TEMPLATES: -t cves/ -t exposures/ -t vulnerabilities/ (excluding intrusive)
RATE LIMIT: -rl 50
OUTPUT: ./.scratch/nuclei-$(date +%Y-%m-%d).json
RETURN: STATUS + SUMMARY (findings by severity) + ARTIFACTS."
```

Never run intrusive templates (those that exploit) without explicit scope confirmation.

## Reporting structure

```
1. Executive Summary (3-5 bullets, top risks + posture)
2. Scope and Methodology
3. Findings (per finding):
   - Title
   - Severity (CVSS or qualitative)
   - Affected hosts/URLs
   - Description
   - Evidence (sanitized)
   - Risk
   - Remediation
   - References (CWE, CVE, vendor docs)
4. Recommendations (strategic, ranked)
5. Appendix (tool outputs, sanitized)
```

Use skill `docx` for Word delivery, or `pdf` for PDF.

## Tooling map

| Need | Tool | Type |
|---|---|---|
| WHOIS | whois | passive |
| DNS | dig, host | passive |
| Subdomain enum | subfinder, amass, crt.sh | passive |
| Cert transparency | crt.sh, certspotter | passive |
| Email/leak | theHarvester, HIBP | passive |
| Port scan | nmap, masscan | active |
| Service detect | nmap -sV, whatweb | active |
| Web app | nikto, ZAP, Burp, gobuster | active |
| Vuln scan | Nessus, OpenVAS, nuclei | active |
| WordPress | wpscan | active |
| API testing | Burp, Postman, custom | active |

## Common pitfalls

- Scope creep: scanning subdomains not in scope.
- Logging tool output without sanitization (leaks creds in some cases).
- Running aggressive scans during business hours on production.
- Reporting findings without remediation guidance.
- CVSS scoring without vendor context.

## Brand context

Your cybersec work, by default,: appears to be skill-development / consulting curiosity rather than active client engagements. Default assumption: lab environments + own systems. Always reconfirm before active scans.

## Anti-patterns

- Running active recon to "see what happens" without scope.
- Storing raw scan output in long-term storage without redaction.
- Reusing scope from one engagement on another.
- Treating tool output as ground truth without validation (false positives common).
