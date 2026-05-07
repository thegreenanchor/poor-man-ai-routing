---
name: adobe-premiere-edit
description: Adobe Premiere Pro editing workflows. Premiere is a GUI app, so this skill produces edit decision lists, batch script files, project templates, and prep work that gets imported, plus delivery specs. Use for video editing planning, EDL/XML generation, batch render setup, motion graphics templates, and Premiere project organization. Trigger for "Premiere," "video edit," "cut down," "EDL," "render queue."
---

# Adobe Premiere Pro Edit

## Scope

Premiere is GUI-driven. Headless ops are limited. This skill generates inputs Premiere consumes and outputs that fit Premiere's import/export pipeline.

## What Codex/Gemini can produce for Premiere

- **EDL** (.edl) — Edit Decision Lists. Premiere imports.
- **Final Cut Pro XML** (.fcpxml or .xml) — richer than EDL; Premiere imports.
- **Markers CSV** — for batch import into a sequence.
- **CSV → batch transcript** — to drive caption/title placement.
- **Render queue / AME presets** — XML for Adobe Media Encoder.
- **Project structure manifests** — folder/bin layouts to set up before Premiere opens.
- **Motion Graphics Template (.mogrt) variations** — Premiere reads .mogrt; harder to script but doable.

## Workflow patterns

### 1. Long-form to short clips (podcast → social)

Pre-Premiere prep:

```
gca "TOPIC: Transcribe ./.scratch/podcast-ep42.mp3 with timestamps and speaker tags.
OUTPUT: ./.scratch/transcripts/ep42.json (with start, end, text, speaker per segment)
TIER: artifact only."
```

Then:

```
cdx "GOAL: From ./.scratch/transcripts/ep42.json, identify top 8 highlight segments (15-90s each) suitable for social cuts.
CRITERIA:
  - Self-contained (no mid-thought start/end)
  - Hook in first 3s
  - Energy/insight density
OUTPUT:
  - ./.scratch/edits/ep42-highlights.csv (cols: clip_n, start_tc, end_tc, hook, key_quote)
  - ./.scratch/edits/ep42-markers.csv (Premiere marker import format)
RETURN: STATUS + SUMMARY (8 highlights summarized) + ARTIFACTS."
```

User imports `ep42-markers.csv` into Premiere via Window → Markers → Import.

### 2. Batch render via Adobe Media Encoder

AME ingests `.epr` (Encoder Preset) files and a watch folder.

```
cdx "GOAL: Generate AME watch-folder config for social deliverables.
DELIVERABLES:
  - 9:16 1080x1920 Reels (mp4 H.264 high)
  - 1:1 1080x1080 IG feed
  - 16:9 1920x1080 LinkedIn
WATCH FOLDER: D:/renders/watch
OUTPUT FOLDER: D:/renders/output
EPR PRESETS: ./.scratch/ame-presets/*.epr (use templates if available, generate XML otherwise)
RETURN: STATUS + SUMMARY (configs written) + ARTIFACTS."
```

User then drops sequences into the watch folder; AME picks them up.

### 3. Project skeleton

Before opening Premiere:

```
cdx "GOAL: Create folder/bin structure for new edit project '<name>'.
LAYOUT:
  /Project/
    /00_Footage/
      /A-Cam/
      /B-Cam/
      /Drone/
      /Audio/
        /Interview/
        /Music/
        /SFX/
    /01_Stills/
    /02_GFX/
      /Lower Thirds/
      /Titles/
    /03_Sequences/
      /WIP/
      /Approved/
    /04_Renders/
      /Drafts/
      /Finals/
    /99_Archive/
  /Project/.dropbox-ignore
RETURN: STATUS + SUMMARY (paths created)."
```

Set as Project Scratch Disks in Premiere → Project Settings → Scratch Disks.

### 4. Caption SRT generation

```
cdx "GOAL: Convert ./.scratch/transcripts/ep42.json to SRT.
OUTPUT: ./.scratch/captions/ep42.srt
RULES:
  - Max 2 lines per cue
  - Max 42 chars per line
  - Min 1s display, max 6s
RETURN: STATUS + SUMMARY (cue count, total duration) + ARTIFACTS."
```

Premiere imports SRT via File → Import.

## EDL/XML import format quick reference

EDL (CMX 3600):
```
TITLE: My Edit
FCM: NON-DROP FRAME

001  AX       V     C        00:00:00:00 00:00:05:12 00:00:00:00 00:00:05:12
* FROM CLIP NAME: clip-001
```

FCPXML is richer (include audio levels, effects, motion, color). For complex builds, prefer FCPXML.

## Motion Graphics Templates (.mogrt)

Generated in After Effects with the Essential Graphics panel. Can be parameterized (text, colors, dimensions). Once exported, the .mogrt drops into a Premiere project and shows as a customizable graphic.

Codex can't author .mogrt directly. It can:
- Generate input data (CSV/JSON of titles, credits, lower-thirds copy) for Premiere's ESS Graphics import.
- Produce After Effects ExtendScript (.jsx) to build .mogrt source projects programmatically.

## Brand context

For your video output:
- OTHER (your wellness brand): short-form wellness clips, captioned for IG/Reels.
- MAIN (your main brand): tutorial cuts, voiceover-driven.
- SIDE: client deliverables, varies.
- WORK: rare; if used, recruitment-style.

Caption style and lower-third templates should be saved per-brand as .mogrt and reused.

## Render specs (common deliverables)

| Platform | Spec |
|---|---|
| Instagram Reels | 1080x1920, H.264, 30fps, max 90s |
| Instagram Feed (1:1) | 1080x1080, H.264, 30fps |
| Instagram Feed (4:5) | 1080x1350, H.264, 30fps |
| TikTok | 1080x1920, H.264, 30 or 60fps |
| YouTube Shorts | 1080x1920, H.264 |
| YouTube standard | 1920x1080, H.264, 30/60fps |
| LinkedIn | 1920x1080, H.264, max 10min recommended |
| X (Twitter) | 1920x1080, H.264, max 140s |

## Pitfalls

- Mismatched timecode/frame rate between source and sequence. Premiere will warn; act on it.
- Proxy workflow not set; 4K editing without proxies is brutal.
- Audio sample rate mismatches cause clicks; standardize at 48kHz.
- Captions exported as burned-in (open) when platform also wants closed (.srt sidecar).

## Anti-patterns

- Editing in source resolution when delivery is web-targeted; pick sequence settings for delivery.
- No version control on project files (manual `_v01`, `_v02` saves help; Adobe Auto-Save fills the gap).
- Rendering full final passes before review; render proofs (lower bitrate) for client review.
- Manual SRT typing when transcripts are available.
