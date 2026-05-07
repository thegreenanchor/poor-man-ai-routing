---
name: seo-audit
description: Run technical and content SEO audits for WordPress, Webflow, or arbitrary domains. Use when task involves "SEO audit," "site audit," "ranking analysis," "keyword gap," "Core Web Vitals," or any diagnostic on a domain's organic search health. Combines Gemini for SERP/competitor data, Codex for crawl/parse, and skills `gsc-ops` and `ga4-reporting` for first-party data.
---

# SEO Audit

## Scope

Technical, on-page, and content SEO. Not link building (that's manual relationship work).

## Audit structure (the 5 layers)

1. **Technical**: indexability, crawl errors, sitemap, robots, redirects, schema, Core Web Vitals.
2. **On-page**: titles, meta, H1, internal links, image alt, content depth.
3. **Content**: keyword targeting, search intent match, freshness, gaps vs competitors.
4. **Off-page**: domain authority signals, mentions, brand presence (light pass; not link-builder territory).
5. **First-party data**: GSC impressions/clicks/CTR, GA4 organic sessions, conversions.

## Inputs needed

Ask user upfront if missing:
- Domain (`example.com`)
- GSC access (skill `gsc-ops`)
- GA4 access (skill `ga4-reporting`)
- 2-3 competitor domains
- Primary keyword cluster (or "discover from current rankings")

## Process

### Step 1 — Crawl (Codex)

```
cdx "GOAL: Crawl <domain>, output structured JSON of every URL with status, title, meta description, H1, canonical, hreflang, schema types found, word count.
FILES IN SCOPE: ./.scratch/crawl-<domain>-$(date +%Y-%m-%d).json
SUCCESS:
  - All discoverable URLs included
  - Status codes captured
  - Errors listed in separate file
CONSTRAINTS: Use Python with httpx + selectolax or equivalent. Respect robots.txt. Rate limit to 5 req/sec.
RETURN: STATUS + SUMMARY (counts: 200/3xx/4xx/5xx, total URLs) + ARTIFACTS."
```

### Step 2 — SERP and competitor data (Gemini)

```
gca "TOPIC: SERP analysis for <primary keywords> in <geo> as of $(date +%Y-%m).
SCOPE: Top 10 results per keyword.
WHAT I NEED:
  - Domains in top 10 per keyword
  - Page title + URL of top 3
  - Featured snippet present? Source domain?
  - PAA questions visible
TIER: 2."
```

### Step 3 — Core Web Vitals

```
cdx "GOAL: Pull Core Web Vitals (LCP, INP, CLS) for top 10 URLs from PageSpeed Insights API.
INPUT: ./.scratch/top-urls.txt
OUTPUT: ./.scratch/cwv-<domain>-$(date +%Y-%m-%d).csv
CONSTRAINTS: Need PSI API key in env $PSI_API_KEY.
RETURN: STATUS + SUMMARY (avg LCP, %% URLs passing) + ARTIFACTS."
```

### Step 4 — GSC pull

Use skill `gsc-ops` (separate skill). Pull last 90 days: queries, pages, impressions, clicks, CTR, position.

### Step 5 — GA4 pull

Use skill `ga4-reporting`. Pull organic sessions, engaged sessions, conversions, top landing pages, last 90 days.

### Step 6 — Synthesis (Claude)

Combine the 5 inputs into the audit deliverable. Sections:

```
1. Executive summary (3-5 bullets, top issues + biggest opportunities)
2. Technical findings (table: issue → severity → URLs affected → fix)
3. On-page findings (same table format)
4. Content gaps (keywords competitors rank for that we don't)
5. Performance dashboard (CWV, GSC, GA4 highlights)
6. 30-day priority queue (specific tasks, ranked by impact/effort)
```

Format: WordPress-friendly markdown if delivering inside WP, else .docx via the `docx` skill.

## Severity scoring

- **P0** = blocking indexing or major rankings loss (noindex on important pages, robots blocking, redirect loops, 5xx errors).
- **P1** = significant rankings impact (missing/duplicate titles, missing schema on key pages, slow CWV).
- **P2** = optimization opportunity (thin content, weak internal linking, missing alt text).
- **P3** = nice to have.

## Common findings checklist

- [ ] robots.txt exists, doesn't block important paths
- [ ] XML sitemap exists, submitted to GSC
- [ ] All target pages return 200
- [ ] Canonical tags present and correct
- [ ] Titles unique, 50-60 chars
- [ ] Meta descriptions unique, 150-160 chars
- [ ] One H1 per page, contains target keyword
- [ ] Schema.org markup on relevant types (Article, Product, LocalBusiness, FAQPage)
- [ ] Image alt text present and descriptive
- [ ] LCP < 2.5s, INP < 200ms, CLS < 0.1 on top URLs
- [ ] No render-blocking JS/CSS above the fold
- [ ] Internal linking to important pages from homepage and key hubs
- [ ] No orphaned pages (pages with 0 internal inbound links)
- [ ] Hreflang correct if multilingual

## Tooling notes

- **Crawl**: Python httpx + selectolax. Or Screaming Frog if user prefers GUI (Codex can't drive GUIs; user runs it manually).
- **Schema validation**: Google's Rich Results Test API or schema.org validator.
- **CWV**: PageSpeed Insights API.
- **SERP**: Gemini search.
- **First-party**: GSC + GA4 APIs (separate skills).

## Brand voice for delivery

For SIDE clients: grounded, practical, problem-solver. Findings framed as "set this up the right way." Long-term system thinking.

For WORK: not typical scope, but if needed → confident, professional, value-clear.

## Common pitfalls

- Reporting issues without fixes. Always: finding → fix → owner → ETA.
- Burying the lead. Top 3 P0 issues go in executive summary.
- Comparing against irrelevant competitors. Stick to organic SERP overlap.
- Treating CWV as the only technical signal. It's one of many.
