---
name: sl-ai-core-engine
description: Standardized management, version tagging, testing, and multi-app submodule synchronization workflow for StarLuna's shared in-house multi-model AI Engine (starluna-app/ai-core). Use when adding models to ai-core, updating fallback cascades or schema repair logic, releasing a new ai-core version, or updating an iOS app backend (Crackit, Strats, Shooting Star) to consume ai-core updates.
---

# StarLuna Shared Multi-Model AI Engine (`ai-core`) Management

This skill governs the development, versioning, testing, and multi-app submodule synchronization for `@starluna/ai-core` (`https://github.com/starluna-app/ai-core.git`).

---

## 🏛️ Architecture Overview

The `ai-core` module provides a provider-agnostic, multi-model execution layer used across all StarLuna Firebase Cloud Functions backends:

```
┌─────────────────────────────────────────────────────────────┐
│                 Client App Function Handlers                │
│    (Strats / Crackit / Shooting Star Business Pipelines)    │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│            @starluna/ai-core (functions/src/ai-core)        │
│                                                             │
│  ┌────────────────────┐  ┌───────────────────────────────┐  │
│  │   Model Registry   │  │       AIEngine (Router)       │  │
│  │ (Manifests & Tiers)│  │ (Fallback, Backoff, Telemetry)│  │
│  └────────────────────┘  └───────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │     Dual-Layer Schema Parser (Auto-Repair Prompts)    │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  GoogleGenAIProvider (Vertex AI & AI Studio Adapters) │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
  ┌────────────────────────┐      ┌────────────────────────┐
  │ Google Cloud Vertex AI │      │    Google AI Studio    │
  │ (Enterprise Production)│      │     (Dev / Free Tier)  │
  └────────────────────────┘      └────────────────────────┘
```

---

## 🛠️ Day-to-Day Workflow

### 1. Developing & Modifying `ai-core`

Always perform core AI engine modifications inside the standalone repo:
```bash
cd /Users/sl/Projects/ai-core
```

1. **Implement Changes**:
   - Add new models / aliases in `src/registry.ts`.
   - Update schema sanitization or repair logic in `src/schema.ts`.
   - Update retry / exponential backoff / fallback logic in `src/router.ts`.
   - Enhance provider implementations in `src/providers/`.
2. **Run Validation & Unit Tests**:
   ```bash
   npm test
   ```
   *All tests in `src/*.test.ts` must pass with zero failures.*
3. **Bump Version & Tag**:
   ```bash
   # Update version in package.json (e.g. 1.1.0)
   git add .
   git commit -m "feat(ai-core): add support for next-gen models and enhanced schema repair"
   git tag v1.1.0
   ```

---

### 2. Integrating / Updating `ai-core` in an App Backend

Each StarLuna app backend (`finance-ios`, `founder-ios`, `marketing-ios`) consumes `ai-core` as a Git submodule inside `functions/src/ai-core`.

#### First-Time App Setup (Adding Submodule)
Inside the consumer repo:
```bash
cd functions/src
git submodule add https://github.com/starluna-app/ai-core.git ai-core
```

Ensure `functions/package.json` includes the prebuild hook:
```json
"scripts": {
  "prebuild": "git submodule update --init --recursive 2>/dev/null || true",
  "build": "tsc"
}
```

#### Updating an App to a New Tag or Commit
Inside the consumer app repo:
```bash
# Navigate to the submodule
cd functions/src/ai-core

# Fetch latest tags and checkout the desired version
git fetch --tags
git checkout v1.1.0   # or specific commit hash / branch

# Return to repo root, build, and test
cd ../..
npm run build
npm test

# Stage the updated submodule pointer
git add functions/src/ai-core
git commit -m "chore(ai-core): update ai-core to v1.1.0"
```

---

## 📋 Submodule Pre-Flight Checklist

Before deploying any Firebase Functions backend:
1. `functions/src/ai-core/package.json` exists on disk.
2. `npm run build` (`tsc`) compiles cleanly into `functions/lib/`.
3. Backend unit tests pass (`npm test`).
