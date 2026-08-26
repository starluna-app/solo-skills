---
name: app-store-screenshot-polisher
description: Polish raw iOS App Store screenshots into upload-ready 6.9-inch marketing screenshots using an image-generation / editing model. Use when converting simulator or raw screenshots into App Store Connect compliant screenshots, adding tasteful captions, background treatment, preserving real app UI, and processing one screenshot first for review before batching the rest.
---

# App Store Screenshot Polisher

Use this skill to turn raw iPhone screenshots into polished App Store assets while keeping the real product UI truthful and legible.

## Core Rules

- Process **one screenshot first** and ask for user review before converting the rest.
- Preserve the actual app UI. Do not invent screens, fake data, buttons, prices, ratings, or unverified claims.
- Output the exact target canvas for App Store iPhone 6.9": **1320 x 2868 PNG**.
- Keep every critical UI label crisp and readable after treatment.
- Use clean, warm, and professional styling: calm backgrounds, elegant typography, light mode.
- Avoid dark mode, noisy gradients, tiny fonts, fake notification badges, or sensitive personal data.
- Use short caption copy: one clear benefit, usually 3–7 words.
- If the raw screenshot already includes device chrome, do not add a second full device frame.

## Workflow

1. Verify input screenshot dimensions and orientation.
2. Select the screen role from the App Store plan (e.g. Home dashboard, AI Assistant, Calendar, Wins & Progress, Resources, Paywall).
3. Draft a concise image-edit prompt for the image editing tool/model.
4. Generate exactly one polished PNG.
5. Validate:
   - Final canvas size is exactly 1320 x 2868.
   - Screen UI text remains uncorrupted and sharp.
   - Captions do not obstruct critical interface elements.
   - No App Store policy violations or misleading claims are introduced.
6. Present the generated screenshot to the user and await approval before batching remaining screens.

## Prompt Template

```text
Create an App Store-ready iPhone 6.9-inch screenshot composition from the provided raw app screenshot.

Output: 1320 x 2868 PNG.

Preserve the app screenshot exactly: keep all UI, text, icons, dates, prices, and layout truthful and readable. Do not invent app features or alter the real screen contents.

Design direction: polished, warm, premium productivity app. Light mode only. Refined typography, calm background, tasteful screenshot presentation.

Caption: "<CAPTION>"

Composition requirements:
- Make the real screenshot the primary visual element.
- Caption should be prominent for App Store browsing but must not obstruct app UI.
- Add subtle depth and clean background styling; no clutter, no fake UI, no extra badges.
- Keep safe margins for App Store cropping and phone notches.
- The result must feel professionally designed, not like an unformatted simulator capture.
```

## Validation Checklist

- [ ] PNG canvas is exactly 1320 x 2868.
- [ ] Raw app UI remains accurate and legible.
- [ ] Caption is brief and benefit-focused.
- [ ] Visual style is warm, uncluttered, and on-brand.
- [ ] No unsubstantiated claims ("#1", "best", "guaranteed").
- [ ] Only one test asset processed before batch approval.
