---
name: ios-asset-prep
description: iOS/macOS Image Asset Preparation Workflow. Two core paths — (1) Photos/Backgrounds: PNG → HEIC compression to reduce app bundle size; (2) Icons/Stickers: restore or cut out backgrounds to recover genuine transparent alpha channels, resize appropriately, and integrate cleanly into Xcode Asset Catalog (.xcassets). Use when handling iOS assets, HEIC conversion, transparent PNGs, icon cutout, rembg, BiRefNet, Asset Catalog integration, or App Thinning.
---

# iOS Asset Preparation Workflow: HEIC Compression & Transparent Icons

A structured guide for iOS/macOS developers to optimize bundle sizes and prepare pixel-perfect transparent assets.

---

## Decision Tree: Which Path Should I Take?

```text
Image Type?
├── Background / Photos / Large Illustrations (No transparency needed)
│   └── Path A: HEIC Compression       → Reduces file size by 50–70%
│
└── Icons / Badges / Stickers / Characters (Requires transparent background)
    ├── Check if alpha channel exists: sips -g hasAlpha image.png
    │   ├── hasAlpha: yes → Path B: Direct resize + Add to Asset Catalog
    │   └── hasAlpha: no  → Path C: AI cutout to recover true alpha (Most common trap)
    └── NEVER save transparent icons as HEIC (actool strips alpha channels during compilation)
```

---

## ⚠️ Critical Rule: Visually "White" is NOT Always Transparent

macOS Preview and QuickLook render images on a white background by default. If an icon has a solid white background without an alpha channel, it looks transparent in Preview because white blends into white.

However, once deployed into an iOS app on a non-white or dark background, a solid white square will appear.

### Verification Commands:

```bash
sips -g hasAlpha icon_example.png
# hasAlpha: yes  → True alpha channel present (RGBA)
# hasAlpha: no   → RGB only (colorType=2), lacks alpha channel; requires cutout

file icon_example.png
# "8-bit/color RGB"   → No alpha
# "8-bit/color RGBA"  → Has alpha
```

> **AI Image Generation Trap**: Tools like Midjourney, DALL·E, and SDXL frequently output solid white RGB PNGs rather than RGBA transparent PNGs.

---

## Path A: HEIC Compression (Backgrounds / Large Photos)

### Best For:
- Fullscreen background illustrations (onboarding, card textures, watercolor themes).
- Large images where app download size is a priority.

### DO NOT USE FOR:
- ❌ **Icons or badges requiring transparency**: Xcode's `actool` strips HEIC alpha channels during compilation, resulting in white bounding boxes.
- ❌ Assets with existing vector originals (PDF/SVG).

### Conversion Commands:

```bash
# Using macOS native sips
for f in *.png; do
  sips -s format heic "$f" --out "${f%.png}.heic"
done

# Using ImageMagick
brew install imagemagick
mogrify -format heic -quality 85 *.png
```

You can also use the bundled script [scripts/batch-convert-heic.sh](scripts/batch-convert-heic.sh).

---

## Path B: Icons with Existing True Alpha Channel

```bash
# 1. Resize to target dimensions (e.g. 512x512)
sips -z 512 512 icon_x.png --out icon_x_512.png

# 2. Verify alpha channel was preserved
sips -g hasAlpha icon_x_512.png

# 3. Add to Assets.xcassets
```

---

## Path C: Recovering Alpha with AI Cutout (`rembg` + `BiRefNet`)

For watercolor illustrations, soft badges, and detailed icons, `rembg` with the `BiRefNet` model is the state-of-the-art solution for preserving soft translucent edges and delicate highlights.

### 1. Install `rembg` (One-time setup):

```bash
python3 -m venv ~/.venv/rembg
~/.venv/rembg/bin/pip install "rembg[cli]" Pillow onnxruntime
```

### 2. Single Image Test:

```bash
~/.venv/rembg/bin/rembg i \
  -m birefnet-general \
  -ae 5 \
  input.png \
  output.png
```

### 3. Batch Processing Script:

Execute the bundled script [scripts/prepare-icons.sh](scripts/prepare-icons.sh):

```bash
bash skills/ios-asset-prep/scripts/prepare-icons.sh <source_dir> <output_dir> [size=512] [prefix=icon_]
```

### 4. Replace into Asset Catalog:

```bash
SRC=/path/to/transparent_512
ASSETS=/path/to/YourApp/Assets.xcassets

cd "$ASSETS"
for d in event_icon_*.imageset; do
  name="${d%.imageset}"
  short="${name#event_icon_}"
  src="$SRC/icon_${short}.png"
  if [ -f "$src" ]; then
    cp "$src" "$d/${name}.png"
    cat > "$d/Contents.json" <<EOF
{
  "images" : [
    { "filename" : "${name}.png", "idiom" : "universal" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF
  fi
done
```

---

## Verification Checklist

- [ ] Transparent icons verified with `sips -g hasAlpha` → `hasAlpha: yes`.
- [ ] No transparent icons stored as `.heic`.
- [ ] All assets placed inside `Assets.xcassets` (not loose files in project root).
- [ ] Tested on simulator with non-white background.
- [ ] Color profiles preserved (check with `sips -g profile`).
