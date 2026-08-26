#!/bin/bash

# iOS Batch Image to HEIC Converter
# Usage: bash batch-convert-heic.sh [directory] [quality:0-100, default 85]

SOURCE_DIR="${1:-.}"
QUALITY="${2:-85}"

if ! command -v magick &> /dev/null; then
    echo "❌ ImageMagick is not installed"
    echo "Install via: brew install imagemagick"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ Directory does not exist: $SOURCE_DIR"
    exit 1
fi

echo "📦 iOS Image to HEIC Batch Converter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📂 Source Directory: $SOURCE_DIR"
echo "🎨 Quality:          $QUALITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

COUNT=0
FAILED=0

for png_file in "$SOURCE_DIR"/*.png; do
    if [ -f "$png_file" ]; then
        filename=$(basename "$png_file")
        heic_file="${png_file%.png}.heic"

        echo -n "⏳ Converting: $filename ... "

        if magick "$png_file" -quality "$QUALITY" "$heic_file" 2>/dev/null; then
            png_size=$(du -h "$png_file" | cut -f1)
            heic_size=$(du -h "$heic_file" | cut -f1)
            echo "✅ ($png_size → $heic_size)"
            COUNT=$((COUNT + 1))
        else
            echo "❌ Failed"
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $COUNT -eq 0 ]; then
    if [ $FAILED -eq 0 ]; then
        echo "⚠️  No PNG files found"
    else
        echo "❌ Conversion failed: $FAILED files"
    fi
    exit 1
else
    echo "✅ Complete!"
    echo "   Successfully converted: $COUNT files"
    if [ $FAILED -gt 0 ]; then
        echo "   Failed: $FAILED files"
    fi
fi
