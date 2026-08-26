---
name: official-resource-image-pipeline
description: Use when creating StarLuna/LunaBee official resource images from an idea: gather the content goal, write and review one image prompt, generate a versioned PNG only after approval, store the prompt manifest, upload the approved image to the UAT official-resources Supabase bucket, insert or update the curated resources row, preserve hidden prompt provenance, and verify the iOS Resources screen can view/download it.
---

# Official Resource Image Pipeline

Use this for official StarLuna/LunaBee resources that should appear in the iOS Resources screen, especially image-first PNG resources and one-page printable designs. This is a prompt-first workflow: do not generate images, PDFs, or database rows until the user has approved the prompt and target metadata.

## Start

1. Read project guidance before edits: `README.md`, `CLAUDE.md`, `docs/engineering/supabase-contract.md`, and `docs/plan/resource-template-generation-pipelines.md`.
2. Ask the user what content they want to create if they did not already specify it. Capture:
   - Topic / title idea
   - Audience age or grade
   - Desired format: PNG, one-time PDF, or reproducible template PDF
   - Category slug, if known
   - App name, dynamic one-line slogan, and URL to place in the footer
3. If the user gives enough detail, choose sensible defaults:
   - App name: `LunaBee`
   - Slogan: generate a short, content-specific one-line slogan matching the resource's purpose
   - URL: `starluna.app`
   - Page: US Letter portrait
   - Target print spec: 300 DPI, `2550 x 3300`
   - Initial file format: PNG unless the user asks for PDF
4. Create one prompt and show it to the user. Stop there until approved.

## Prompt Rules

Prompts must be specific enough for image generation models but honest about model limits. Include the requested print size in the prompt, then verify the actual output dimensions after generation.

Every prompt should include:
- US Letter portrait or chosen page size.
- Full-page printable intent.
- Large, crisp, highly readable text.
- Important content at least 0.5 inches from the edge.
- A light footer with app name, one content-specific one-line slogan, and URL.
- Footer guidance: subtle, small, airy, not a heavy brand banner, and not visually competing with the resource.
- Negative constraints: no QR codes, no external logos, no watermarks, no fake app UI, no tiny decorative text, no clutter.
- Clear English unless the user asks for another language.

## Versioning and Files

Use stable versioned slugs and never overwrite older approved versions unless explicitly requested.

Pattern:
```text
<topic-slug>-v1.png
<topic-slug>-v2.png
```

Local storage:
```text
tools/resource-gen/prompts/approved/<slug>.json
tools/resource-gen/output/images/<category>/<slug>.png
tools/resource-gen/output/pdfs/<category>/<slug>.pdf
```

## Generation & Verification

After prompt approval, generate the versioned image, save under the output path, and validate:
- `file <path>` confirms valid PNG/PDF.
- Dimensions recorded in manifest.
- Footer is quiet and readable.
- Quick Look preview on iOS Simulator confirms valid rendering and download.
