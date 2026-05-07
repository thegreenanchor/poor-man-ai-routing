---
name: adobe-firefly
description: Adobe Firefly image generation via the Firefly API and via Adobe Express integration. Use for brand-safe AI image gen (commercial-safe training data), text-to-image, generative fill, generative expand, and structure-aware variations. Trigger for "Firefly," "Adobe AI image," or when commercial safety of training data matters.
---

# Adobe Firefly

## Scope

Adobe Firefly Services API for headless image generation. Firefly is trained on Adobe Stock + public-domain content; commercially safe (per Adobe).

## Auth

- Adobe Developer Console: developer.adobe.com
- Create a project, add Firefly Services API
- Get Client ID, Client Secret
- OAuth Server-to-Server credentials (recommended for headless)
- Env: `FIREFLY_CLIENT_ID`, `FIREFLY_CLIENT_SECRET`

Token endpoint:
```
POST https://ims-na1.adobelogin.com/ims/token/v3
Body: grant_type=client_credentials&client_id=...&client_secret=...&scope=openid,AdobeID,session,additional_info,read_organizations,firefly_api,ff_apis
```

## Common operations

### Text-to-image

```
cdx "GOAL: Generate Firefly image from prompt.
PROMPT: '<prompt>'
SIZE: 1024x1024 (or specified)
N: 1 image (default)
STYLE PRESET: photo | art | graphic
CONTENT CLASS: photo | art (matters for commercial use)
OUTPUT: ./.scratch/images/firefly-<slug>-$(date +%Y-%m-%d).png
ENDPOINT: POST https://firefly-api.adobe.io/v3/images/generate
RETURN: STATUS + SUMMARY (file path, dimensions) + ARTIFACTS."
```

Sample request body:
```json
{
  "prompt": "Soft minimalist desk scene with laptop showing dashboard, plants, neutral lighting",
  "contentClass": "photo",
  "size": {"width": 1024, "height": 1024},
  "numVariations": 1,
  "promptBiasingLocaleCode": "en-US"
}
```

### Generative fill (inpaint)

Replace a masked region of an existing image.

```
cdx "GOAL: Generative fill on ./.scratch/images/source.png with mask ./.scratch/images/mask.png.
PROMPT: 'replacement description'
ENDPOINT: POST https://firefly-api.adobe.io/v3/images/fill
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

### Generative expand (outpaint)

Extend canvas with generated content.

```
cdx "GOAL: Expand ./.scratch/images/source.png to 1920x1080.
PROMPT: 'extension hint'
ENDPOINT: POST https://firefly-api.adobe.io/v3/images/expand
RETURN: STATUS + SUMMARY + ARTIFACTS."
```

### Structure / style reference

For variations matching a reference image's composition or style:

```json
{
  "prompt": "...",
  "structure": {"imageReference": {"source": {"uploadId": "..."}}, "strength": 60},
  "style": {"imageReference": {"source": {"uploadId": "..."}}, "strength": 50}
}
```

Upload images via Firefly's storage endpoints first; you get an uploadId.

## Brand application

For your brands, define style vectors:

| Brand | Style preset | Mood | Notes |
|---|---|---|---|
| WORK (your day-job brand) | photo, contentClass=photo | Confident, clean, professional | Avoid stock-y feel; healthcare authentic |
| SIDE | photo, art mix | Grounded, calm, neutral palette | Plants, textures, soft light |
| OTHER (your wellness brand) | photo | Approachable, real, supportive | Diverse, candid, not-too-perfect |
| MAIN (your main brand) | graphic | Direct, bold, value-first | Crisp icons, simple compositions |

Save the prompts that work as templates in `./.scratch/firefly-prompts/<brand>.md`.

## Prompt patterns

Effective Firefly prompts are descriptive without being over-specified.

Good:
"Soft minimalist desk scene, MacBook with dashboard visible, two small succulents, morning light from left, photographic, shallow depth of field, neutral palette, 16:9"

Less good:
"Make a desk image" (under-specified)
"PHOTOREALISTIC ULTRA HIGH DETAIL 8K HYPER REALISTIC..." (over-specified, modern Firefly handles quality without these)

## Output handling

Firefly returns a presigned URL to the generated image. Download to scratch:

```python
import requests
r = requests.post(url, headers=H, json=body)
img_url = r.json()['outputs'][0]['image']['url']
img = requests.get(img_url).content
open(out_path, 'wb').write(img)
```

## Rate limits and quotas

Firefly Services has token-based metered usage. Track via Adobe Developer Console. Set up alerts.

## Compare to Nano Banana / Gemini

Use Firefly when:
- Commercial use, brand assets where training-data provenance matters.
- Inpaint/outpaint specifically (Firefly's are strong).
- Adobe pipeline (drag .psd from Firefly Web → Photoshop, etc.).

Use Nano Banana (Gemini) when:
- Speed and cost are priorities for non-commercial or internal-use images.
- Wider creative range / less constrained outputs.
- Multimodal mix (image + text + reasoning).

## Pitfalls

- contentClass mismatch produces watermarks or refuses. `art` for illustration prompts, `photo` for realistic.
- Prompts referencing real people, copyrighted characters, or trademarks trigger filters.
- Aspect ratio caps: certain sizes only. Check current allowed sizes.
- Token expiry: Firefly tokens expire in 24h; refresh in long jobs.

## Anti-patterns

- Generating photographic likenesses of real people for commercial use.
- Using Firefly outputs without confirming the chosen contentClass aligns with use case.
- Storing generated images in scratch indefinitely; move to brand asset library when keepers.
- Re-generating instead of using inpaint for small fixes.
