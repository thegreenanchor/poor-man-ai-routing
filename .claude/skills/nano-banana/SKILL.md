---
name: nano-banana
description: Image generation via Google's image model (commonly called Nano Banana / Imagen / Gemini image gen) through the Gemini CLI or API. Use for fast, flexible image gen where speed and creative range matter more than commercial-safety guarantees. Trigger for "image gen," "generate hero image," "make a graphic," when not specifically Firefly.
---

# Nano Banana (Gemini Image Gen)

## Scope

Image generation via Google's Gemini-family image models, accessible through:
- Gemini CLI (preferred for headless via `gca` wrapper)
- Gemini API directly (for code that needs structured returns)
- Vertex AI (for high-volume/enterprise)

"Nano Banana" is the colloquial name for Google's image model family. Actual model identifiers: `imagen-3.0-generate-002`, `gemini-2.5-flash-image-preview`, etc. (verify current names; they change).

## Auth

- Google Cloud project with `generativelanguage.googleapis.com` enabled (see skill `google-developer-console`).
- API key: `GOOGLE_API_KEY` env var.
- For Vertex: service account with `aiplatform.user` role.

## Calling via gca (preferred)

```
gca "TOPIC: Generate image via Nano Banana.
PROMPT: '<prompt>'
SIZE: 1024x1024 (or specified)
ASPECT: 1:1 | 16:9 | 9:16 | 4:5
STYLE NOTES: <if any>
OUTPUT: ./.scratch/images/nb-<slug>-$(date +%Y-%m-%d).png
TIER: artifact only."
```

The `gca` wrapper enforces format and writes to `./.scratch/`.

## Calling directly (for batch / structured)

```
cdx "GOAL: Generate 5 image variations via Gemini image API.
PROMPT TEMPLATE: '<prompt with {variant} placeholder>'
VARIANTS: ['warm tone', 'cool tone', 'high key', 'low key', 'neutral']
OUTPUT: ./.scratch/images/nb-batch-$(date +%Y-%m-%d)/
ENDPOINT: POST /v1beta/models/<model>:generateContent
RETURN: STATUS + SUMMARY (5 files) + ARTIFACTS."
```

Code template:

```python
import google.generativeai as genai, base64, os
genai.configure(api_key=os.environ['GOOGLE_API_KEY'])

# Imagen-style call (verify current API shape)
model = genai.GenerativeModel('imagen-3.0-generate-002')
resp = model.generate_content([
    {"text": "Soft minimalist desk scene with laptop, plants, neutral lighting, 16:9, photographic"},
])
# Decode and save
img_b64 = resp.parts[0].inline_data.data
open(out_path, 'wb').write(base64.b64decode(img_b64))
```

## Prompt patterns

Nano Banana handles longer, more creative prompts better than older models.

Effective:
- "Editorial-style photograph of [subject], [setting], [lighting], [mood], [composition], shot on [camera/lens style]"
- "Minimalist illustration, [subject], flat colors, geometric, [palette], [aspect]"
- "Cinematic still, [scene], [grading], anamorphic, shallow depth"

Less effective:
- Tag-soup prompts (`masterpiece, 8k, ultradetailed`)
- Over-stuffing with adjectives
- Conflicting style directives

## Brand application

| Brand | Default prompt prefix |
|---|---|
| WORK (your day-job brand) | "Editorial healthcare photography, authentic, professional, soft natural light, real environments, ..." |
| SIDE | "Calm minimalist scene, neutral palette, plants, natural texture, photographic, ..." |
| OTHER (your wellness brand) | "Approachable wellness photography, real people, candid, soft warm light, diverse, ..." |
| MAIN (your main brand) | "Bold flat illustration, geometric, high contrast, simple composition, brand colors, ..." |

Save proven prompts in `./.scratch/nb-prompts/<brand>.md`.

## Output handling

Files write to `./.scratch/images/`. For keepers, move to brand asset library:

```bash
# Suggested layout
~/brand-assets/
  mna/
    images/{type}/{date}-{slug}.png
  green-anchor/
  tga-health/
  side-hustle-labs/
```

## Combining with Firefly

Use both:
- Nano Banana for ideation, variations, internal use.
- Firefly for final commercial deliverables where training-data provenance matters.

Pipeline: draft 10 Nano Banana variations → pick 1-2 → re-render in Firefly with tightened prompt for final.

## Variation strategies

Generate diverse outputs without re-prompting from scratch:
1. Same prompt, different seed → minor variations.
2. Same prompt, swap one descriptor → controlled variation.
3. Same prompt, different aspect ratio → reuse for multi-platform.

## Pitfalls

- Real-person likenesses: usually refused. Avoid named real people.
- Brand/IP: refuses logos, characters, copyrighted designs.
- Text in images: Nano Banana is improving but still error-prone for long text. Generate without text, add type in Photoshop / Express.
- Realism: photoreal humans can have artifact issues (hands, eyes). Inpaint or pick another generation.

## Anti-patterns

- Generating dozens of images then never reviewing. Set a 3-pass rule: generate 5, pick 1, refine.
- Skipping the brand asset library; everything stays in scratch and gets lost.
- Using prompt templates that drift from brand voice over time. Audit monthly.
