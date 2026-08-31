#!/usr/bin/env bash
set -euo pipefail

# Usage: update-app-ai-core.sh <app-repo-path> [version-tag-or-branch]
APP_PATH="${1:-.}"
TARGET_REF="${2:-main}"

echo "🔄 Updating ai-core submodule in: ${APP_PATH} -> ${TARGET_REF}"

if [ ! -d "${APP_PATH}/functions/src/ai-core" ]; then
  echo "❌ Error: ${APP_PATH}/functions/src/ai-core does not exist. Adding submodule..."
  mkdir -p "${APP_PATH}/functions/src"
  git -C "${APP_PATH}" submodule add https://github.com/starluna-app/ai-core.git functions/src/ai-core
fi

git -C "${APP_PATH}/functions/src/ai-core" fetch --all --tags
git -C "${APP_PATH}/functions/src/ai-core" checkout "${TARGET_REF}"

echo "🔨 Testing compilation in ${APP_PATH}/functions..."
cd "${APP_PATH}/functions"
npm run build

echo "✅ ai-core successfully updated and compiled in ${APP_PATH}"
