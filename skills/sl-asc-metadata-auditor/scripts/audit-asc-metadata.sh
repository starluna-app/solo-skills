#!/usr/bin/env bash
# Audit live App Store Connect metadata, character lengths, and review details.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APP_ENV=".asc/app.env"

if [[ ! -f "$APP_ENV" ]]; then
  echo "❌ Error: $APP_ENV not found in current directory." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$APP_ENV"

: "${APP_ID:?APP_ID must be set in .asc/app.env}"

echo "=================================================="
echo "🔍 StarLuna ASC Metadata & Review Notes Audit"
echo "App ID: $APP_ID ($APP_NAME)"
echo "=================================================="

# 1. Fetch Version
VERSION_JSON="$(asc versions list --app "$APP_ID" --platform IOS --output json)"
LATEST_VERSION_ID="$(echo "$VERSION_JSON" | jq -r '.data[0].id')"
LATEST_VERSION_STR="$(echo "$VERSION_JSON" | jq -r '.data[0].attributes.versionString')"
LATEST_STATE="$(echo "$VERSION_JSON" | jq -r '.data[0].attributes.appStoreState')"

echo
echo "📦 App Store Version: $LATEST_VERSION_STR ($LATEST_VERSION_ID) - State: $LATEST_STATE"

# 2. Fetch Localization
LOC_JSON="$(asc localizations list --version "$LATEST_VERSION_ID" --output json)"
PROMO="$(echo "$LOC_JSON" | jq -r '.data[0].attributes.promotionalText // ""')"
DESC="$(echo "$LOC_JSON" | jq -r '.data[0].attributes.description // ""')"
WHATS_NEW="$(echo "$LOC_JSON" | jq -r '.data[0].attributes.whatsNew // ""')"
KEYWORDS="$(echo "$LOC_JSON" | jq -r '.data[0].attributes.keywords // ""')"

PROMO_LEN=${#PROMO}
DESC_LEN=${#DESC}
WHATS_NEW_LEN=${#WHATS_NEW}
KEYWORDS_LEN=${#KEYWORDS}

echo
echo "📊 Character Length Validations:"
echo "  • Promotional Text : $PROMO_LEN / 170 chars $( [[ $PROMO_LEN -le 170 ]] && echo '✅' || echo '❌ EXCEEDS LIMIT' )"
echo "  • Description      : $DESC_LEN / 4000 chars $( [[ $DESC_LEN -le 4000 ]] && echo '✅' || echo '❌ EXCEEDS LIMIT' )"
echo "  • What's New       : $WHATS_NEW_LEN / 4000 chars $( [[ $WHATS_NEW_LEN -le 4000 ]] && echo '✅' || echo '❌ EXCEEDS LIMIT' )"
echo "  • Keywords         : $KEYWORDS_LEN / 100 chars $( [[ $KEYWORDS_LEN -le 100 ]] && echo '✅' || echo '❌ EXCEEDS LIMIT' )"

# 3. Fetch App Review Details
REVIEW_JSON="$(asc review details-for-version --version-id "$LATEST_VERSION_ID" --output json)"
DEMO_REQ="$(echo "$REVIEW_JSON" | jq -r '.data.attributes.demoAccountRequired')"
DEMO_USER="$(echo "$REVIEW_JSON" | jq -r '.data.attributes.demoAccountName // ""')"
DEMO_PASS="$(echo "$REVIEW_JSON" | jq -r '.data.attributes.demoAccountPassword // ""')"
NOTES="$(echo "$REVIEW_JSON" | jq -r '.data.attributes.notes // ""')"
NOTES_LEN=${#NOTES}

echo
echo "🛡️ App Review Details Validation:"
echo "  • Demo Account Required : $DEMO_REQ"
echo "  • Demo Username         : $DEMO_USER $( [[ -n "$DEMO_USER" ]] && echo '✅' || echo '❌ MISSING' )"
echo "  • Demo Password Set     : $( [[ -n "$DEMO_PASS" ]] && echo '✅ (Protected)' || echo '❌ MISSING' )"
echo "  • Review Notes Length   : $NOTES_LEN / 4000 chars $( [[ $NOTES_LEN -le 4000 ]] && echo '✅' || echo '❌ EXCEEDS LIMIT' )"

echo
echo "=================================================="
echo "✅ Audit completed successfully."
echo "=================================================="
