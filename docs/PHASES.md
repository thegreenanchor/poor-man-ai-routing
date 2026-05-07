# Skill Index (by phase)

All skills live at `~/.claude/skills/<name>/SKILL.md`. Claude Code auto-loads them during escalation based on the skill description matching the task. Codex-primary sessions use the same files as routing reference material.

---

## Phase 1: Routing infrastructure (5 skills)

| Skill | Purpose |
|---|---|
| `ai-routing` | Master decision tree: Codex primary, Gemini discovery, Claude escalation/review. |
| `codex-handoff` | How to construct Codex prompts. Scoped-task template. |
| `gemini-handoff` | How to construct Gemini prompts. Search/OSINT patterns. |
| `claude-usage-protocol` | Claude escalation discipline. Anti-patterns. Tier tables. |
| `usage-mode-awareness` | PEAK/OFFPEAK detection logic + threshold table. |

---

## Phase 2: Marketing / business (10 skills)

| Skill | Covers |
|---|---|
| `seo-audit` | Technical + content SEO audits across WP, Webflow, any domain. |
| `ga4-reporting` | GA4 Data API: traffic, conversions, channels, landing pages. |
| `gsc-ops` | Search Console API: queries, pages, impressions, indexing, sitemaps. |
| `meta-ads-api` | Facebook/Instagram Marketing API: insights, campaigns, creatives, audiences. |
| `hubspot-workflows` | CRM ops beyond the HubSpot MCP: bulk imports, custom properties, sequences. |
| `mailchimp-campaigns` | Campaign creation, audience hygiene, A/B tests, reports. |
| `mailcoach-sending` | Self-hosted Mailcoach for WORK (your day-job brand) outreach. |
| `wordpress-avada` | WP + Avada/Fusion Builder via REST and WP-CLI. |
| `webflow-builds` | CMS imports, asset uploads, custom code beyond Webflow MCP. |
| `notion-systems` | Database design, bulk imports, cross-DB queries beyond Notion MCP. |

---

## Phase 3: Tech / security / ops (6 skills)

| Skill | Covers |
|---|---|
| `wsl-kali-ops` | Kali Linux on WSL2: setup, networking, common tool workflows. |
| `docker-ops` | Docker + Compose: builds, multi-service stacks, debugging. |
| `n8n-workflows` | Self-hosted n8n: workflow patterns, JSON manipulation, integrations. |
| `cybersec-recon` | Authorized recon (passive + active), pentest scoping, reporting. |
| `osint-toolkit` | Public-data OSINT on domains, companies, assets. Strict ethical rules. |
| `google-developer-console` | GCP project setup, API enables, service accounts, IAM. |

---

## Phase 4: Creative (6 skills)

| Skill | Covers |
|---|---|
| `adobe-premiere-edit` | Premiere prep: EDLs, markers, batch render configs, captions. |
| `adobe-firefly` | Firefly Services API: text-to-image, fill, expand, brand-safe gens. |
| `nano-banana` | Gemini image gen via CLI/API: fast, flexible, batch variations. |
| `notebooklm-research` | NotebookLM as research brain + automated source curation/post-processing. |
| `video-editing-pipeline` | End-to-end video: ingest → transcribe → cut plan → edit → encode → deliver. |
| `adobe-creative-cloud` | Cross-app orchestration: ExtendScript, UXP, batch processing, CC Libraries. |

---

## Anthropic-provided (already installed; do not duplicate)

These ship with Claude Code and are already available:

| Skill | Use |
|---|---|
| `docx` | Word document creation/editing. |
| `pptx` | PowerPoint slide decks. |
| `xlsx` | Excel spreadsheets. |
| `pdf` | PDF creation, extraction, manipulation. |
| `canvas-design` | Visual design (PNG/PDF posters, art). |
| `internal-comms` | Status reports, leadership updates, FAQs. |
| `ops-analyst` | Messy input → structured operational outputs. |
| `brand-guidelines` | Anthropic brand colors/typography (rare for our use). |

---

## Subagents

Live at `~/.claude/agents/<name>.md`.

| Subagent | Triggers when |
|---|---|
| `orchestrator` | Claude-side escalation planning for strategy, conflicts, or precision QA. |
| `researcher` | Search, OSINT, social, web, Google ecosystem. |
| `builder` | Code, file ops, automations, multi-file scans. |
| `reviewer` | Brand-voice, rubric, content/code review, and precision QA before delivery. |

---

## How skills get loaded

Claude Code reads the YAML frontmatter (`name`, `description`) of every `SKILL.md` during escalation. When a task description matches keywords from a skill's description, Claude auto-loads that skill's body for context. Codex-primary sessions should treat these skills as the shared routing/SOP library.

To force-load a skill: mention its name in the prompt, e.g. "Use the `seo-audit` skill."

To audit which skills are loaded in a Claude escalation session: ask Claude.

---

## Adding a skill

1. Create `~/.claude/skills/<your-skill>/SKILL.md`.
2. Add YAML frontmatter:
   ```yaml
   ---
   name: your-skill
   description: When to use this skill. Be specific so Claude/Codex can match it. Mention concrete trigger keywords.
   ---
   ```
3. Write the SOP body. Use the existing skills as a template.
4. Restart your Claude Code session (or start a fresh one) to pick it up.

---

## Updating a skill

Edit the SKILL.md. Changes take effect on next session.

For breaking changes, version the skill: copy to `<skill>-v2/SKILL.md`, update the description to clarify which is which, retire the old one when ready.
