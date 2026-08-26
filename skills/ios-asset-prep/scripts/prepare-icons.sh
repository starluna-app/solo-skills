#!/bin/bash
#
# prepare-icons.sh — Batch transparency cutout & resizing for iOS icons
#
# Workflow:
#   1. Use rembg + BiRefNet for clean alpha matting (true RGBA)
#   2. Use sips to scale to target square dimensions (default 512x512)
#   3. Output transparent PNGs ready for Xcode Assets.xcassets
#
# Usage:
#   bash prepare-icons.sh <source_dir> <output_dir> [size=512] [prefix=icon_]
#

set -e

SRC_DIR="${1:-}"
OUT_DIR="${2:-}"
SIZE="${3:-512}"
PREFIX="${4:-icon_}"

REMBG_BIN="${REMBG_BIN:-$HOME/.venv/rembg/bin/rembg}"
MODEL="${MODEL:-birefnet-general}"
EDGE_REFINE="${EDGE_REFINE:-5}"

if [ -z "$SRC_DIR" ] || [ -z "$OUT_DIR" ]; then
  echo "Usage: bash $(basename "$0") <source_dir> <output_dir> [size=512] [prefix=icon_]"
  exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "❌ Source directory does not exist: $SRC_DIR"
  exit 1
fi

if [ ! -x "$REMBG_BIN" ]; then
  echo "❌ Cannot find rembg at: $REMBG_BIN"
  echo ""
  echo "Please install rembg first:"
  echo "  python3 -m venv ~/.venv/rembg"
  echo "  ~/.venv/rembg/bin/pip install \"rembg[cli]\" Pillow onnxruntime"
  echo ""
  echo "Or set REMBG_BIN to your existing rembg binary."
  exit 1
fi

mkdir -p "$OUT_DIR"

echo "🎨 iOS Icon Preparation Pipeline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 Source:    $SRC_DIR"
echo "📂 Output:    $OUT_DIR"
echo "📏 Size:      ${SIZE}×${SIZE}"
echo "🏷  Prefix:    ${PREFIX}*.png"
echo "🤖 Model:     $MODEL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

OK=0
FAIL=0
SKIP=0

shopt -s nullglob
for src in "$SRC_DIR"/${PREFIX}*.png; do
  base=$(basename "$src")
  out_name="${base// /_}"
  out="$OUT_DIR/$out_name"

  if [ -f "$out" ] && [ "$out" -nt "$src" ]; then
    echo "⏭  Skip (already exists): $base"
    SKIP=$((SKIP + 1))
    continue
  fi

  echo -n "🔧 $base ... "

  if "$REMBG_BIN" i -m "$MODEL" -ae "$EDGE_REFINE" "$src" "$out" 2>/dev/null \
     && sips -z "$SIZE" "$SIZE" "$out" --out "$out" >/dev/null 2>&1; then
    if sips -g hasAlpha "$out" 2>/dev/null | grep -q "hasAlpha: yes"; then
      size=$(du -h "$out" | cut -f1)
      echo "✅ ($size, RGBA)"
      OK=$((OK + 1))
    else
      echo "⚠️  Generated but missing alpha"
      FAIL=$((FAIL + 1))
    fi
  else
    echo "❌ Failed"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Success: $OK   ⏭  Skipped: $SKIP   ❌ Failed: $FAIL"
echo ""

if [ "$OK" -eq 0 ] && [ "$SKIP" -eq 0 ]; then
  echo "⚠️  No matching files found for ${PREFIX}*.png"
  exit 1
fi
