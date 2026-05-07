---
name: notebooklm-research
description: Using Google NotebookLM as a research and synthesis layer. NotebookLM ingests sources (PDFs, docs, URLs, Drive files), grounds answers in those sources, and exports outlines, briefings, and audio overviews. Use for deep-dive research, source-grounded synthesis, and building reusable knowledge bases per topic. Trigger for "NotebookLM," "research notebook," "knowledge base from sources."
---

# NotebookLM Research

## Scope

NotebookLM is interactive (browser-based). Headless API for NotebookLM is not generally available as of mid-2026; check current state. This skill describes the workflow that combines NotebookLM (manual) with our automation pipeline (headless prep + post-processing).

## Pattern: NotebookLM as the research brain

1. **Source curation** (Codex/Gemini): assemble PDFs, articles, transcripts in `./.scratch/sources/<topic>/`.
2. **Notebook creation** (manual in NotebookLM): create a notebook, upload sources.
3. **Querying** (manual): ask NotebookLM the research questions.
4. **Output extraction** (manual): copy summary/outline/audio overview links.
5. **Post-processing** (Codex/Claude): clean up, format into deliverable.

NotebookLM's strength: source-grounded answers with citations. Ours plus Claude's strength: assembly and post-processing.

## When to use NotebookLM vs Gemini directly

| Scenario | Tool |
|---|---|
| Quick web search + summary | Gemini (`gca`) |
| Synthesize 20-100 long PDFs into one briefing | NotebookLM |
| One-off research question | Gemini |
| Reusable topic notebook for ongoing reference | NotebookLM |
| Audio overview/podcast-style summary | NotebookLM |
| Source-grounded Q&A with citations | NotebookLM |

## Source curation (pre-NotebookLM)

```
gca "TOPIC: Find authoritative sources on <topic> from <date range>.
SCOPE: Academic, regulatory, industry-leading publications.
WHAT I NEED:
  - Top 15 sources (URL, title, date, source type)
  - For PDFs: download URL
  - For long-form articles: full URL
ARTIFACTS: ./.scratch/sources/<topic>/source-list.csv
TIER: 2."
```

Then download:

```
cdx "GOAL: Download all PDFs and save HTML articles from ./.scratch/sources/<topic>/source-list.csv.
OUTPUT: ./.scratch/sources/<topic>/
NAMING: <date>-<slug>.<ext>
RETURN: STATUS + SUMMARY (downloaded count, errored) + ARTIFACTS."
```

User uploads the folder contents into a NotebookLM notebook.

## NotebookLM usage tips

Inside NotebookLM (manual steps):

1. Create notebook, name it `<topic>-<YYYY-MM>`.
2. Upload sources (max 50 sources/notebook on free; check current limits).
3. NotebookLM auto-summarizes. Read the auto-summary.
4. Use **Notes** for staging insights as you ask questions.
5. Use **Discover sources** to find related material via Google.
6. Generate **Audio Overview** for review during commute / context switching.
7. Export findings as: Briefing doc, Study guide, Timeline, FAQ.

## Reusable topic notebooks

Build evergreen notebooks per recurring research area:

| Brand / area | Notebook |
|---|---|
| WORK (your day-job brand) | "Travel nurse staffing market — ongoing" (CMS rule changes, agency M&A, pay rate trends) |
| OTHER (your wellness brand) | "Wellness affiliate landscape — ongoing" (compliance, top programs, conversion rates) |
| SIDE | "Web/marketing tech stack — ongoing" (tools roundups, AI integration patterns) |
| MAIN (your main brand) | "Digital product trends — ongoing" |

Each refresh: add new sources monthly, re-query, update outputs.

## Post-processing pattern

User pastes NotebookLM's briefing doc back into chat. Then:

```
cdx "GOAL: Reformat NotebookLM briefing at ./.scratch/notebooklm-briefing.md.
TARGETS:
  - 800-word executive summary
  - 5-bullet TL;DR for slide use
  - 3 LinkedIn post drafts (SIDE voice)
  - 1 email sequence (3 emails)
OUTPUT: ./.scratch/deliverables/<topic>/
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

Then Claude reviews briefly and runs `reviewer` subagent for brand-voice check.

## Citation handling

NotebookLM provides citations inline (e.g., `[1]`, `[2]`). Preserve them in the briefing. Strip when delivering to channels that don't support citations (LinkedIn copy), but keep a master version with citations for accuracy verification.

## Audio Overview use cases

- Pre-meeting prep (listen on commute).
- Internal team briefing (share link).
- Test if your messaging is clear (does the AI synthesis match your understanding?).

## Pitfalls

- 50-source soft cap can be hit. Curate carefully.
- NotebookLM doesn't update sources; if a source URL changes, you must re-upload.
- Audio Overviews can hallucinate small details. Don't quote them as primary source.
- Free tier rate limits.

## Anti-patterns

- Using NotebookLM for tasks Gemini search would handle in 5 seconds.
- Treating NotebookLM Notes as ground truth; always verify against the cited source.
- Building 1 notebook per project then never reusing. Reusable topic notebooks scale better.
- Skipping the source curation step; uploading random sources gives muddy answers.
