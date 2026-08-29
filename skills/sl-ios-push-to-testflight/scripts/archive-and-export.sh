#!/usr/bin/env bash
# archive-and-export.sh — Clean, build Release archive, and export signed IPA for TestFlight
set -euo pipefail

REPO_DIR="${PWD}"

if [ ! -f "$REPO_DIR/.asc/app.env" ]; then
  echo "❌ Error: .asc/app.env not found in $REPO_DIR"
  exit 1
fi

source "$REPO_DIR/.asc/app.env"

SCHEME="${SCHEME:-}"
if [ -z "$SCHEME" ]; then
  echo "❌ Error: SCHEME is not set in .asc/app.env"
  exit 1
fi

ARCHIVE_PATH="$REPO_DIR/build/${SCHEME}.xcarchive"
EXPORT_PATH="$REPO_DIR/build/ipa"
EXPORT_OPTIONS="$REPO_DIR/ExportOptions.plist"

if [ ! -f "$EXPORT_OPTIONS" ]; then
  echo "❌ Error: ExportOptions.plist not found in $REPO_DIR"
  exit 1
fi

echo "==> Cleaning old build artifacts in $REPO_DIR/build..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"
mkdir -p "$REPO_DIR/build" "$EXPORT_PATH"

if [ -f "$REPO_DIR/project.yml" ]; then
  echo "==> Running xcodegen generate..."
  (cd "$REPO_DIR" && xcodegen generate)
fi

# Detect project or workspace
PROJECT_ARG=()
if [ -d "$REPO_DIR/${SCHEME}.xcworkspace" ]; then
  PROJECT_ARG=(-workspace "$REPO_DIR/${SCHEME}.xcworkspace")
elif ls "$REPO_DIR"/*.xcodeproj 1> /dev/null 2>&1; then
  XCODEPROJ=$(ls -d "$REPO_DIR"/*.xcodeproj | head -1)
  PROJECT_ARG=(-project "$XCODEPROJ")
fi

echo "==> Building archive for $SCHEME (Release)..."
xcodebuild \
  "${PROJECT_ARG[@]}" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  archive \
  -quiet

echo "==> Exporting IPA using $EXPORT_OPTIONS..."
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -quiet

IPA_FILE=$(find "$EXPORT_PATH" -name "*.ipa" | head -1)
if [ -n "$IPA_FILE" ] && [ -f "$IPA_FILE" ]; then
  echo "==> Exported IPA successfully: $IPA_FILE"
  ls -la "$IPA_FILE"
else
  echo "❌ Error: No IPA generated in $EXPORT_PATH"
  exit 1
fi
