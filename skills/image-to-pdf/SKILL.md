---
name: image-to-pdf
description: Convert one or more images into a single multi-page PDF document without rasterization loss. Supports natural-sorting multiple images (e.g. image-1, image-2, image-3) in exact page sequence. Use when the user asks to "convert images to PDF", "merge PNGs/JPGs into PDF", or create a single PDF from an image directory.
---

# Image to PDF Converter

Converts one or multiple images into a single, high-fidelity PDF. Prioritizes lossless direct embedding using `img2pdf` to avoid unnecessary re-rasterization and compression artifacts.

## Default Workflow

1. Identify input image paths and target output PDF path.
2. If given a directory, natural-sort the image files so `image-2.png` appears before `image-10.png`:
   - `image-1.png` (Page 1)
   - `image-2.png` (Page 2)
   - `image-3.png` (Page 3)
3. Execute the bundled conversion script.
4. Verify page count, integrity, and file dimensions.

## Command Execution

### Explicit File Sequence:
```bash
python3 skills/image-to-pdf/scripts/images_to_pdf.py \
  --output output.pdf \
  image-1.png image-2.png image-3.png
```

### Directory Input (Natural Sorting):
```bash
python3 skills/image-to-pdf/scripts/images_to_pdf.py \
  --output output.pdf \
  --input-dir ./images
```

## Supported Formats
- `.png`
- `.jpg` / `.jpeg`
- `.webp`
- `.tif` / `.tiff`

## Dependencies
If `img2pdf` is missing in the current Python environment:
```bash
python3 -m pip install img2pdf
```

## Quality Verification
Verify generated PDF:
```bash
file output.pdf
# Inspect page count via Python:
python3 -c "import pypdf; print('Pages:', len(pypdf.PdfReader('output.pdf').pages))" 2>/dev/null || true
```

## Important Rules
- Input order determines exact page sequence.
- When an explicit list is provided, preserve exact user ordering.
- When a directory is provided, always use natural sorting.
- Never overwrite existing PDF files unless explicitly directed (`--overwrite`).
- For printable assets, preserve original DPI and dimensions without stretching.
