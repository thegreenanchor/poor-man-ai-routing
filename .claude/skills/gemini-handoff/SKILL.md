---
name: gemini-handoff
description: How to construct Gemini CLI prompts. Use whenever delegating search, OSINT, social monitoring, web research, large doc scans, Google ecosystem operations, or image generation (Nano Banana) to Gemini via the `gca` wrapper. Defines the question template, copyright rules, and OSINT boundaries.
---

# Gemini Handoff

## When to use Gemini

- Web search (general, news, technical, competitive).
- OSINT (companies, domains, public profiles).
- Social monitoring (LinkedIn, X, Reddit, YouTube comments — public only).
- Google ecosystem (Google Analytics, Search Console, Drive, NotebookLM).
- Large doc scans (PDFs, transcripts, long articles).
- Image generation (Nano Banana / Imagen via Gemini CLI).
- Multi-modal queries (image + question, video transcript questions).

## When NOT to use Gemini

- Code generation → Codex.
- File edits → Codex.
- Brand-voice final polish and other judgment-heavy decisions → Claude review when precision matters.
- Anything requiring private data or login-walled content → ask user.

## The question template

```
TOPIC: [one sentence]
SCOPE: [time range, geography, sources to favor/exclude]
WHAT I NEED:
  - [specific outputs]
  - [specific outputs]
TIER: [1 = summary | 2 = slice with verbatim quotes]
```

## Calling Gemini

```bash
gca "TOPIC: ... SCOPE: ... WHAT I NEED: ..."
```

Wrapper applies mode-aware compression and format enforcement.

## Examples by task type

### Competitor scan

```
gca "TOPIC: Pricing pages for [CompetitorA], [CompetitorB], [CompetitorC] in travel nurse staffing.
SCOPE: As of $(date +%Y-%m).
WHAT I NEED:
  - Each company's tier names + monthly/contract pricing
  - Verbatim quote of any 'starting at' or 'from' price
  - URL of their pricing page
TIER: 2."
```

### Topic research

```
gca "TOPIC: Latest CMS Medicare staffing reimbursement rules affecting travel nurses.
SCOPE: Last 6 months.
WHAT I NEED:
  - Top 5 most cited or recent (last 3 months) sources
  - Verbatim 1-sentence summary of each rule change
  - CMS publication dates
TIER: 2."
```

### OSINT on a prospect

```
gca "TOPIC: Public OSINT on [Company Name].
SCOPE: Public sources only.
WHAT I NEED:
  - Domain WHOIS basics (registrar, age)
  - LinkedIn page (URL, employee count band)
  - Recent news mentions (last 90 days, top 3)
  - Tech stack from BuiltWith if available
TIER: 1."
```

### Social monitoring

```
gca "TOPIC: Public mentions of '@MNAHealthcare' or 'WORK (your day-job brand)' on LinkedIn, X, Reddit.
SCOPE: Last 30 days.
WHAT I NEED:
  - Top 10 mentions, ranked by engagement
  - URL + verbatim snippet (max 25 words)
  - Sentiment (pos/neg/neutral)
TIER: 2."
```

### Large doc scan

```
gca "TOPIC: Read ./.scratch/cms-rule-2026.pdf. Find all sections that affect agency staffing reimbursement.
SCOPE: This document only.
WHAT I NEED:
  - Section numbers + verbatim 2-line excerpt of each
  - One-sentence plain-English explanation per section
TIER: 2."
```

### Image generation (Nano Banana)

```
gca "TOPIC: Generate hero image for SIDE landing page.
PROMPT: 'Soft minimalist desk scene with laptop showing dashboard, plants, neutral lighting, photographic, 16:9.'
WHAT I NEED:
  - PNG output to ./.scratch/images/green-anchor-hero-$(date +%Y-%m-%d).png
  - 1920x1080
TIER: artifact only."
```

## Reading Gemini's output

1. **STATUS** first.
2. **SUMMARY** bullets.
3. **SOURCES** for citation needs.
4. **EVIDENCE** for verbatim quotes if you need to repeat them.
5. **ARTIFACTS** path only when full dump is needed.

The full research file lives in `./.scratch/`. Read it only if synthesis requires more than the summary.

## Copyright safety

- Verbatim quotes capped at 25 words.
- One quote per source preferred.
- Always cite (URL + date).
- Never reproduce song lyrics. Even if user asks.
- Compress, don't paraphrase. Paraphrase = displacive summary risk.

## OSINT boundaries

Gemini hard-stops on:
- Login-walled content.
- Private data.
- Facial image collection.
- CAPTCHA bypass.
- Anything requiring credentials.

If a request crosses these lines, Gemini returns STATUS: blocked. Re-route to user manual action.

## Anti-patterns

- **Open-ended research questions**: "Tell me about marketing." Use precise scope.
- **Asking Gemini to write the deliverable**: Gemini researches; the session lead writes/synthesizes, with Claude review when judgment is needed.
- **Re-running searches** Codex could have synthesized from the existing dump.
- **Skipping `gca` and calling `gemini` directly**: loses format enforcement.

## Mode awareness

PEAK: top 5 sources, 20-word quote cap, 8-bullet summary.
OFFPEAK: top 8 sources, 25-word quote cap, 12-bullet summary.
