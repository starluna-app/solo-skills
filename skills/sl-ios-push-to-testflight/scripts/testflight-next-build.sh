#!/usr/bin/env bash
# testflight-next-build.sh — Query ASC for next monotonic build number and auto-bump project
set -euo pipefail

REPO_DIR="${PWD}"

if [ ! -f "$REPO_DIR/.asc/app.env" ]; then
  echo "❌ Error: .asc/app.env not found in $REPO_DIR"
  exit 1
fi

source "$REPO_DIR/.asc/app.env"

echo "==> Querying App Store Connect for next monotonic build number (App ID: $APP_ID)..."
NEXT_BUILD=$(asc builds next-build-number --app "$APP_ID" --platform IOS --output json | jq -r '.nextBuildNumber')

if [ -z "$NEXT_BUILD" ] || [ "$NEXT_BUILD" = "null" ]; then
  echo "❌ Error: Failed to fetch next build number from App Store Connect."
  exit 1
fi

echo "==> Next build number: $NEXT_BUILD"

if [ "${1:-}" = "--bump" ]; then
  if [ -f "$REPO_DIR/project.yml" ]; then
    echo "==> Updating CURRENT_PROJECT_VERSION in project.yml to $NEXT_BUILD..."
    sed -i '' -E "s/(CURRENT_PROJECT_VERSION:[[:space:]]*\")[0-9]+(\")/\1$NEXT_BUILD\2/" "$REPO_DIR/project.yml"
    echo "==> Regenerating Xcode project via xcodegen..."
    (cd "$REPO_DIR" && xcodegen generate)
  elif [ -f "$REPO_DIR/Config/Shared.xcconfig" ]; then
    echo "==> Updating CURRENT_PROJECT_VERSION in Config/Shared.xcconfig to $NEXT_BUILD..."
    sed -i '' -E "s/^(CURRENT_PROJECT_VERSION[[:space:]]*=[[:space:]]*)[0-9]+/\1$NEXT_BUILD/" "$REPO_DIR/Config/Shared.xcconfig"
  fi
  echo "==> Build number bumped to $NEXT_BUILD successfully."
fi
