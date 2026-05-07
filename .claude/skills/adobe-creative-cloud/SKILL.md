---
name: adobe-creative-cloud
description: Adobe Creative Cloud orchestration across Photoshop, Illustrator, InDesign, After Effects, Premiere, Lightroom, Express. Use for cross-app workflows, scripting via ExtendScript / UXP / CEP, batch processing, and asset library management. Trigger when a task spans multiple Adobe apps, references Creative Cloud Libraries, or involves bulk Photoshop/Illustrator/InDesign automation.
---

# Adobe Creative Cloud Orchestration

## Scope

Working across the Adobe stack. Most apps are GUI-driven, but most also support headless or scripted automation.

## Scripting layers

| Layer | Apps | Use for |
|---|---|---|
| ExtendScript (.jsx) | All older Adobe | Legacy automation, batch ops, heavy lifts |
| CEP / HTML extensions | Premiere, AE, Photoshop, etc. | Custom panels (deprecated, on the way out) |
| UXP (Unified Extensibility Platform) | Photoshop, InDesign | Modern, JS-based, the future |
| Adobe APIs (Firefly Services, etc.) | Cloud-hosted gens | True headless |
| Action Recorder + Actions | Photoshop, Illustrator | GUI-recordable repeats |
| Data Merge / Variables | InDesign, Illustrator | Bulk doc generation from CSV |

## Common cross-app workflows

### 1. Photoshop batch resize + watermark

```
cdx "GOAL: Generate ExtendScript that batch-processes ./.scratch/images/source/*.{jpg,png}.
ACTIONS PER IMAGE:
  - Open
  - Resize to 1920x1080 (longest side, maintain aspect)
  - Add watermark layer from ./.scratch/brand/watermark.png at bottom-right, 60% opacity
  - Export as JPEG quality 85 to ./.scratch/images/processed/
  - Close without saving
OUTPUT: ./.scratch/scripts/batch-resize.jsx
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

User runs in Photoshop: File → Scripts → Browse → select `batch-resize.jsx`.

### 2. InDesign Data Merge for templates

```
cdx "GOAL: Prepare InDesign data merge package.
INPUTS:
  - Template: ./.scratch/templates/business-card.indt (existing)
  - Data: ./.scratch/data/team-roster.csv (cols: name, title, email, phone, photo_path)
OUTPUTS:
  - Tagged CSV ready for Data Merge palette
  - Per-row PDFs preview (optional, generate via batch script)
RETURN: STATUS + SUMMARY (row count) + ARTIFACTS."
```

User: open .indt, Window → Utilities → Data Merge → load CSV → preview → export.

### 3. Illustrator batch SVG → PNG

```
cdx "GOAL: Convert all .ai files in ./.scratch/illustrations/ to PNG (multiple sizes).
SIZES: 256, 512, 1024, 2048
TOOL: Illustrator ExtendScript (or rsvg-convert if SVG export already done)
OUTPUT: ./.scratch/illustrations-png/<name>-<size>.png
RETURN: STATUS + SUMMARY (count) + ARTIFACTS."
```

### 4. Lightroom batch metadata + export

```
cdx "GOAL: Lightroom batch script.
TASKS:
  - Apply preset 'Brand-WORK-Web' to all photos in collection 'October Shoot'
  - Add keywords: 'mna,2026,nurse,recruitment'
  - Export 1920px JPEG at 80% to ./.scratch/exports/
TOOL: Lightroom SDK Lua scripting (advanced) OR manual via batch with action recorder
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

Lightroom SDK is Lua. For most users, Action recording inside Lightroom is faster than scripting.

### 5. After Effects template (.aep) variations

```
cdx "GOAL: Render N variations of After Effects composition with text overrides.
TEMPLATE: ./.scratch/aep/title-card.aep
DATA: ./.scratch/data/title-variations.csv (cols: title, subtitle, brand)
OUTPUT: ./.scratch/aep-renders/<row>.mp4
TOOL: aerender (CLI) with .jsx pre-render script that reads CSV and updates text layers per pass
RETURN: STATUS + SUMMARY (renders generated, errored) + ARTIFACTS."
```

aerender invocation:
```bash
aerender -project title-card.aep -comp "TitleCard" -RStemplate "Best Settings" -OMtemplate "H.264 - Match Render Settings - 15 Mbps" -output renders/out_[#####].mp4
```

## Creative Cloud Libraries

CC Libraries store assets accessible across apps. Programmatic access is limited; UI is primary.

For brand asset organization:

| Library | Purpose |
|---|---|
| WORK — Brand | Logos, color swatches, fonts (linked), templates |
| WORK — Photography | Approved shots |
| SIDE — Brand | Same |
| etc. | One per brand |

Drag from Library panel into any Adobe app.

## Adobe Express integration

Adobe Express has its own API for templated graphics:
- Templates accessible via Express API (limited; check current state)
- Brand kits sync with CC Libraries
- Quick-edit links for non-designer users

For the stack assumed here: Express is the "fast brand-compliant graphic" tool. Reuse templates per brand.

## Scripting tips

### ExtendScript .jsx skeleton

```javascript
#target photoshop
app.bringToFront();

var folder = Folder.selectDialog("Select source folder");
var files = folder.getFiles(/\.(jpg|png)$/i);

for (var i = 0; i < files.length; i++) {
    var doc = open(files[i]);
    // ... operations ...
    var saveFile = new File(files[i].path + "/processed/" + files[i].name);
    doc.saveAs(saveFile, new JPEGSaveOptions(), true);
    doc.close(SaveOptions.DONOTSAVECHANGES);
}
```

### UXP plugin skeleton (Photoshop modern)

UXP plugins are JS + JSX-like UI, packaged. More complex to set up but the path forward.

For one-offs: stick with ExtendScript. For reusable in-app tools: UXP.

## Cross-app data flow

```
Lightroom (raw → adjusted)
  ↓ export
Photoshop (composite, retouch)
  ↓ smart object link
Illustrator (vector overlays)
  ↓ embed/place
InDesign (layout, typography)
  ↓ export PDF/InDesign Server
Distribution
```

Lock layers and use linked smart objects so updates propagate.

## Brand kit hygiene

Per brand, maintain:
- Color palette (CC Library swatches)
- Typography (linked fonts via Adobe Fonts)
- Logo lockups (CC Library)
- Photography style guide (Lightroom presets, sample images)
- Templates (.psd, .ai, .indt, .aep, .indl saved per type)

Update yearly. Audit drift quarterly.

## Pitfalls

- ExtendScript debugging is grim. Use ExtendScript Toolkit (deprecated) or VS Code with Adobe extensions.
- Fonts not synced via Creative Cloud → broken docs on other machines.
- Linked assets at absolute paths break on machine moves; use relative or CC Library.
- Adobe app updates sometimes break .jsx; maintain.

## Anti-patterns

- Doing in Photoshop what After Effects does better (or vice versa).
- Recreating brand assets per project instead of pulling from CC Library.
- Manual repetitive ops with no script attempt.
- Storing project files locally with no cloud backup.
