---
name: usage-mode-awareness
description: Time-aware routing mode (PEAK vs OFFPEAK). Use at session start and whenever crossing the 5am or 2pm EST boundary on weekdays. Defines threshold tables, detection logic, and manual override commands. Apply before any non-trivial task to set the right delegation aggressiveness.
---

# Usage Mode Awareness

## Why this exists

Claude usage caps and response speed shift by time of day. Anthropic's infrastructure is most loaded during US business hours. To stretch usage, the system runs in two modes that change every routing threshold.

## The two modes

### PEAK mode

- **When**: weekday 5:00 AM to 1:59 PM EST.
- **Posture**: maximum delegation. Claude does pure orchestration, almost nothing else.
- **Use**: get more done with the same Claude budget.

### OFFPEAK mode

- **When**: weekend any time, weekday 2:00 PM to 4:59 AM EST.
- **Posture**: Claude can do moderate direct work without guilt. Delegation still default for heavy lifts.
- **Use**: faster iteration, more flexibility.

## Threshold table

| Rule | PEAK | OFFPEAK |
|---|---|---|
| Default access tier | Tier 1 (summary) | Tier 2 (slice + evidence) |
| Max lines Claude reads directly | 200 | 500 |
| Max files Claude reads in a row | 2 | 4 |
| Subagent spawn threshold | 3+ tool calls | 5+ tool calls |
| Default delegation target | Always Codex/Gemini | Claude OK for medium tasks |
| Web fetch behavior | Always Gemini, summary only | Gemini, slice format allowed |
| Search depth | Single Gemini call, top 5 | Multi-pass research, top 8 |
| Verbatim quote cap (research) | 20 words | 25 words |
| EVIDENCE slice length | 10 lines | 20 lines |
| SUMMARY bullets max | 8 | 12 |
| Final reply length | Tight, deliverable + 1-2 sentences | Deliverable + up to 3 sentences |
| Reviewer subagent | Required for brand-facing | Optional |

## Detection logic

Run at session start:

```bash
# UTC time
date -u +"%Y-%m-%d %H:%M %A"
```

Convert UTC to EST. EST = UTC-5 (or UTC-4 during DST, March-November).

Apply:
1. If day is Saturday or Sunday → **OFFPEAK**.
2. Else if EST hour is in [5, 14) → **PEAK**.
3. Else → **OFFPEAK**.

If detection fails (clock error, weird timezone): default to **PEAK** (safe).

Write the result to `./.scratch/.mode`. Wrappers and subagents read this file.

## Setting the mode

```bash
# Detect and set
mkdir -p ./.scratch
HOUR_UTC=$(date -u +%H)
DAY=$(date -u +%A)

# EST conversion (assuming EDT for May; adjust for DST as needed)
HOUR_EST=$(( (HOUR_UTC - 4 + 24) % 24 ))

if [ "$DAY" = "Saturday" ] || [ "$DAY" = "Sunday" ]; then
  echo "OFFPEAK" > ./.scratch/.mode
elif [ "$HOUR_EST" -ge 5 ] && [ "$HOUR_EST" -lt 14 ]; then
  echo "PEAK" > ./.scratch/.mode
else
  echo "OFFPEAK" > ./.scratch/.mode
fi

cat ./.scratch/.mode
```

## DST handling

EST proper = UTC-5. EDT (March second Sunday → November first Sunday) = UTC-4.

For accuracy, use system timezone if available:

```bash
TZ="America/New_York" date +"%H %A"
```

This auto-handles DST.

## Response header

Header every non-trivial response with:

```
Mode: PEAK (Tue 09:14 EST)
```

or

```
Mode: OFFPEAK (Sat 22:18 EST)
```

So you always see which posture is active.

## Manual overrides

User can type:

- `/peak` or `mode: peak` → force PEAK posture.
- `/offpeak` or `mode: offpeak` → force OFFPEAK posture.
- `/auto` → re-detect from clock.

When override is set, write to `./.scratch/.mode` and skip auto-detect for the session.

## Mid-session boundary crossing

If the session crosses 5am or 2pm EST while running:
- Mode does NOT auto-switch. It stays at session-start value.
- Re-prompting (or `/auto`) re-detects.

This avoids 30 seconds of overhead per turn for clock checks. Acceptable trade.

## Why these thresholds

| Setting | Reasoning |
|---|---|
| PEAK reads cap at 200 lines | Most files under 200 lines are config/small modules. Above that, delegation pays off. |
| OFFPEAK at 500 | Most code files. Avoids over-delegation when Claude can handle directly without strain. |
| PEAK subagent at 3+ calls | Aggressive isolation of work. Main context stays at <10 tool calls per turn. |
| OFFPEAK at 5+ | Less aggressive. Direct work feels natural up to medium complexity. |
| Tier 1 default in PEAK | Maximum savings. User gets the answer; full data lives in scratch. |
| Tier 2 default in OFFPEAK | Better DX when Claude can do more directly without rate concerns. |

## Adjustments you might want

- If you find PEAK too aggressive (Claude over-delegating trivial stuff): bump line cap to 250.
- If you find OFFPEAK still burning too fast: drop OFFPEAK line cap to 350.
- If your sessions are mostly 5pm-9pm and you want a "shoulder" mode: add a third mode in this file. Defaults stay binary for simplicity.

## Quick reference

```
PEAK     5am-2pm EST weekdays    Maximum delegation
OFFPEAK  All other times         Moderate delegation
```
