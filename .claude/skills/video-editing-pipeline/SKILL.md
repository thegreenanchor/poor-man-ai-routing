---
name: video-editing-pipeline
description: End-to-end video editing pipeline from raw footage to multi-platform delivery. Coordinates the headless steps (transcribe, cut planning, caption gen, encoding) with the GUI steps (Premiere edit, color, audio polish). Use to plan and execute video projects beyond a single tool's scope. Trigger for "video pipeline," "produce a video," "edit and publish."
---

# Video Editing Pipeline

## Pipeline phases

```
1. Plan        → outline, target deliverables, timeline
2. Ingest      → footage organized, proxies generated
3. Transcribe  → text + timecodes from speech
4. Cut plan    → highlight selection, EDL/markers, paper edit
5. Edit        → Premiere (skill `adobe-premiere-edit`)
6. Captions    → SRT generation, burn-in or sidecar
7. Color       → grade in Premiere/Lumetri or DaVinci
8. Audio       → mix, normalize, music bed
9. Encode      → AME or ffmpeg to platform specs
10. Deliver    → upload, schedule, distribute
```

Steps 1, 3, 4, 6, 9, 10 are scriptable. Steps 2, 5, 7, 8 are GUI-driven.

## Phase 1: Plan

Pre-shoot:

```
cdx "GOAL: Generate shot list for video project '<title>'.
INPUT: ./.scratch/scripts/<title>-script.md
OUTPUT: ./.scratch/shotlist-<title>.csv (cols: scene, shot_n, type, duration_est, notes)
RETURN: STATUS + SUMMARY (scene count, total est duration) + ARTIFACTS."
```

Deliverables matrix per project:

| Master | Variants |
|---|---|
| 16:9 1080p YouTube | 9:16 Reels (60s, 30s, 15s), 1:1 IG (60s), 9:16 Shorts |
| 16:9 4K master archive | All web variants downscaled |

## Phase 2: Ingest

```
cdx "GOAL: Organize footage from ./raw-footage/ into project structure.
ACTIONS:
  - Identify camera/scene from filename or sidecar metadata
  - Sort into bins: A-Cam, B-Cam, Drone, Audio
  - Generate proxies (1/4 res H.264) into ./proxies/
TOOLS: ffmpeg, exiftool
RETURN: STATUS + SUMMARY (clip count, proxy size, duration total) + ARTIFACTS (CSV manifest)."
```

ffmpeg proxy command:
```bash
ffmpeg -i input.mxf -c:v libx264 -preset fast -crf 23 -vf "scale=iw/4:ih/4" -c:a aac proxy.mp4
```

## Phase 3: Transcribe

```
cdx "GOAL: Transcribe ./.scratch/audio/master-mix.wav with speaker diarization.
TOOL: whisper (large-v3) or whisperx for diarization
OUTPUT: ./.scratch/transcripts/<title>.json (segments: start, end, text, speaker)
RETURN: STATUS + SUMMARY (duration, word count, speakers) + ARTIFACTS."
```

Local whisperx:
```bash
whisperx audio.wav --model large-v3 --diarize --output_format json
```

## Phase 4: Cut plan

```
cdx "GOAL: From ./.scratch/transcripts/<title>.json, build paper edit.
RULES:
  - Identify natural beats (topic shifts, pauses > 1.5s)
  - Mark dead air / fillers for trimming
  - Tag highlight segments (15-90s self-contained)
OUTPUT:
  - ./.scratch/edits/<title>-paperedit.md (human-readable)
  - ./.scratch/edits/<title>-markers.csv (Premiere import)
RETURN: STATUS + SUMMARY (segment count, highlights, total trim suggested) + ARTIFACTS."
```

## Phase 5: Edit (Premiere)

Manual. See skill `adobe-premiere-edit` for prep files Premiere consumes.

## Phase 6: Captions

```
cdx "GOAL: Convert transcript to SRT and burn-style caption layer.
INPUT: ./.scratch/transcripts/<title>.json
OUTPUTS:
  - ./.scratch/captions/<title>.srt (sidecar)
  - ./.scratch/captions/<title>-burnin.ass (styled, for ffmpeg burn-in)
RULES:
  - Max 2 lines, 42 chars/line
  - Display 1-6s
  - Brand-styled font/colors per ./.scratch/brand-styles/<brand>.json
RETURN: STATUS + SUMMARY (cue count) + ARTIFACTS."
```

Burn-in via ffmpeg:
```bash
ffmpeg -i input.mp4 -vf "ass=captions.ass" -c:a copy output.mp4
```

## Phase 7: Color

Manual in Premiere Lumetri or Resolve. Pre-set looks per brand:

| Brand | Look |
|---|---|
| WORK | Clean editorial, balanced contrast, slight warm |
| SIDE | Neutral, true-to-life, soft greens emphasized |
| OTHER (your wellness brand) | Soft warm, lifted shadows, healthy tones |
| MAIN (your main brand) | Punchy, contrasty, saturated brand accent |

Save Lumetri presets per brand. Reuse.

## Phase 8: Audio

Manual. Targets:
- Dialogue: -16 LUFS integrated, peaks under -1 dBTP
- Music bed: -20 to -24 LUFS, ducks under dialogue
- Loudness normalization to platform spec at delivery (YouTube: -14, IG: -16, broadcast: -23)

## Phase 9: Encode

```
cdx "GOAL: Encode master to platform variants.
INPUT: ./.scratch/master/<title>-master.mov
OUTPUTS: ./.scratch/deliverables/<title>/
VARIANTS:
  - youtube-1080p.mp4 (1920x1080, H.264, CRF 18, AAC 256k)
  - reels-90s.mp4 (1080x1920, crop center, H.264, CRF 20, AAC 192k)
  - reels-30s.mp4 (1080x1920, trimmed to first 30s)
  - linkedin-1080p.mp4 (1920x1080, H.264, CRF 19)
  - shorts-60s.mp4 (1080x1920, trimmed)
TOOL: ffmpeg
RETURN: STATUS + SUMMARY (file sizes, durations) + ARTIFACTS."
```

ffmpeg crop center for vertical:
```bash
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" -c:v libx264 -crf 20 -c:a aac -b:a 192k vertical.mp4
```

## Phase 10: Deliver

For each platform, an upload step. Most aren't easily headless without API access.

| Platform | API headless? | Method |
|---|---|---|
| YouTube | Yes | YouTube Data API v3 (videos.insert) |
| Instagram | Limited | Meta Graph API (Reels publishing) |
| LinkedIn | Yes | LinkedIn API (organic post with media) |
| TikTok | Limited | TikTok Content Posting API |
| X | Yes | X API |
| Web/CDN | Yes | direct upload |

For programmatic posting: skill `n8n-workflows` is a clean home (uses platform integrations).

For human posting: deliverables CSV with caption + thumbnail per variant; user uploads.

## Brand-specific pipelines

### OTHER (your wellness brand) (high volume short-form)

- Source: long-form podcast or interview
- Paper edit picks 3-8 highlights per episode
- Caption-heavy (90% of viewers watch muted)
- Vertical-first
- Burn-in captions (no sidecar)
- Brand color accent on captions

### SIDE (case studies, tutorials)

- Source: client-shot or screen recordings
- Polished narration
- Lower-thirds for context
- Mix of horizontal (LinkedIn, YouTube) and vertical (Reels)

### MAIN (your main brand) (educational shorts)

- Source: voiceover + b-roll + screen captures
- Punchy edit, fast cuts
- Big text overlays for hooks
- Vertical-first

### WORK (rare; recruitment-style)

- Source: nurse interviews
- Authentic, restrained edit
- Subtitles for accessibility

## Pitfalls

- Skipping proxies on 4K source. Edit becomes painful.
- Mismatched frame rates. Standardize at ingest.
- Forgetting captions when uploading. Many platforms auto-generate badly.
- Loudness not normalized to platform; gets dinged.

## Anti-patterns

- Doing 9 platforms at once. Pick 2-3 highest leverage.
- No archive. Save master + project file in versioned cloud storage.
- Re-editing in Premiere when paper edit could've cut work.
- Manual upload when API publishing is reliable.
