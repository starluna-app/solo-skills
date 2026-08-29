---
name: sl-ios-push-to-testflight
description: >-
  Complete StarLuna iOS release workflow: commits all changes with rich architectural
  and design rationale, bumps build number monotonically via ASC, archives & exports the
  signed IPA, uploads to TestFlight with tester notes, and synchronizes App Store metadata
  (App Review notes, What's New, Promotional Text, Description tweaks). Use when the user says
  "push to testflight", "release to testflight", "ship to testflight", "commit and push testflight",
  or "run sl-ios-push-to-testflight".
---

# StarLuna iOS Release & TestFlight Workflow (`sl-ios-push-to-testflight`)

A standardized, end-to-end release pipeline for StarLuna iOS applications built on the Firebase + SwiftUI stack (e.g. `Crackit`, `Shooting Star`). This skill automates the full progression from dirty worktree to live TestFlight distribution and App Store Connect metadata synchronization while maintaining clean, auditable commit logs and metadata tracking.

> **Note on App-Specific Skills**: Applications with different backend architectures (such as `Luna Bee`, which uses Supabase/PostgreSQL/Deno) use dedicated release skills (e.g. `sl-ios-lunabee-push-to-testflight`).

---

## 🧭 Operating Principles & Architecture Separation

1. **Single Source of Truth**: All generic release workflow logic and reusable scripts reside exclusively in `solo-skills`. App repositories only maintain app-specific configurations (`.asc/app.env`, `project.yml` / `Config/Shared.xcconfig`, `ExportOptions.plist`, `metadata/`, `.asc/releases/`).
2. **Detailed Semantic Commit Logs**: Every release commit must capture not only *what* changed, but the underlying **architecture design**, **UI/UX decisions**, and **important decision rationale**.
3. **Monotonic Build Numbers**: Never guess build numbers. Always query App Store Connect via `asc builds next-build-number` (or the skill's `scripts/testflight-next-build.sh --bump`) to ensure zero build collision.
4. **Strictly Serial Archive Execution**: Follow project rules—never run `xcodebuild archive` concurrently with tests or simulator processes to prevent SQLite `build.db` lock contention.
5. **Surgical & Non-Disruptive Metadata Updates**:
   - **App Review Notes**: Inspect existing notes; append or refine instructions specifically covering new features from the latest commit range so reviewers have an exact test path.
   - **What's New / TestFlight Notes**: Clear, user-facing summary of new capabilities and fixes since the last released version.
   - **App Description**: Never make drastic rewrites. Make targeted, surgical enhancements reflecting new features and clearly document the diff.
6. **Reuses Existing Tooling**: Composes with `asc` CLI, `xcodebuild`, and centralized skill scripts (`testflight-next-build.sh`, `archive-and-export.sh`).

---

## 🛠️ The 5-Phase Workflow

```mermaid
flowchart TD
    A["Phase 1: Deep Semantic Git Commit"] --> B["Phase 2: Build Number Bump & IPA Build"]
    B --> C["Phase 3: TestFlight Upload & Distribution"]
    C --> D["Phase 4: App Review Notes & Metadata Sync"]
    D --> E["Phase 5: Release Tracking (.asc/releases/)"]
```

---

### Phase 1 — Commit All Changes with Architectural Rationale

1. Inspect modified and untracked files:
   ```bash
   git status
   git diff
   ```
2. Formulate a structured, multi-paragraph commit message:
   - **Header**: Standard conventional commit format (`feat(...)`, `fix(...)`, `refactor(...)`).
   - **Summary**: Concise bullet list of features, bug fixes, and UX updates.
   - **Architecture & Concurrency**: Detail changes to observable stores (`AppStore`), Swift 6 Sendable boundaries, repository abstractions, caching layers, and database schemas/composite keys.
   - **UI/UX & Design Tokens**: Document changes to view hierarchies, typography/color tokens (`Theme.*`), scrolling/layout containers, and accessibility affordances.
   - **Key Decisions & Trade-offs**: Note rationale for specific patterns (e.g. Firestore composite document keys to isolate per-platform state, fallback caching strategies, multimodal API integration choices).
3. Stage and commit:
   ```bash
   git add .
   git commit -m "<Structured commit message>"
   ```

---

### Phase 2 — Check Version, Auto-Bump Build Number & Build IPA

1. **Verify Environment & Config**:
   ```bash
   source .asc/app.env
   ```

2. **Query ASC & Auto-Bump Build Number**:
   Run the centralized build helper from `solo-skills` (or direct `asc` CLI) from the root of the target repository:
   ```bash
   bash ~/Projects/solo-skills/skills/sl-ios-push-to-testflight/scripts/testflight-next-build.sh --bump
   ```

3. **Serial Clean Archive & IPA Export**:
   Run strictly serially from the target repository root:
   ```bash
   bash ~/Projects/solo-skills/skills/sl-ios-push-to-testflight/scripts/archive-and-export.sh
   ```
   *Verify that `build/ipa/*.ipa` was generated and code signing matches the StarLuna LLC Team ID.*

---

### Phase 3 — TestFlight Upload & Distribution

1. **Upload and Distribute to Beta Group**:
   Publish the IPA to App Store Connect, attach What to Test notes, and distribute to internal testers (e.g. `"The Inner Circle"`):
   ```bash
   source .asc/app.env
   IPA_PATH=$(find build/ipa -name "*.ipa" | head -1)
   asc publish testflight \
     --app "$APP_ID" \
     --ipa "$IPA_PATH" \
     --group "The Inner Circle" \
     --test-notes "<Summary of changes and testing instructions>" \
     --locale "en-US"
   ```

2. **Verify Build Status on ASC**:
   ```bash
   asc builds list --app "$APP_ID" --output table | head -5
   ```

---

### Phase 4 — Update App Review Notes, What's New & Store Metadata

1. **Inspect Existing Review Details & Version Localizations**:
   ```bash
   source .asc/app.env
   VERSION_ID=$(asc versions list --app "$APP_ID" --platform IOS --output json | jq -r '.data[0].id')
   asc review details-for-version --version-id "$VERSION_ID" --pretty
   asc localizations list --version "$VERSION_ID" --pretty
   ```

2. **App Review Notes (`notes`)**:
   - Check existing demo account instructions in `metadata/review.json` or ASC.
   - Keep existing core flow (demo account credentials, project navigation).
   - Append concise instructions for testing new features since the previous release (e.g. testing multimodal image generation with reference images, project source links, editable strategy directions, and post revision persistence).
   - Push update:
     ```bash
     REVIEW_DETAIL_ID=$(asc review details-for-version --version-id "$VERSION_ID" --output json | jq -r '.data.id')
     asc review details-update --id "$REVIEW_DETAIL_ID" --notes "<Updated notes>"
     ```

3. **What's New (`whatsNew`) & Promotional Text (`promotionalText`)**:
   - Write clear, user-facing bullet points covering new features, performance improvements, and bug fixes for the current version release.
   - Update via:
     ```bash
     asc localizations update \
       --version "$VERSION_ID" \
       --locale "en-US" \
       --whats-new "<What's new text>" \
       --promotional-text "<Promotional text>"
     ```

4. **App Description (`description`)**:
   - **Safety Rule**: Do not make wholesale rewrites. Retain the established value proposition, structure, and tone.
   - Adjust feature bullet points and workflow descriptions to accurately highlight new platform support or capabilities.
   - Update via:
     ```bash
     asc localizations update \
       --version "$VERSION_ID" \
       --locale "en-US" \
       --description "<Updated description>"
     ```

---

### Phase 5 — Record & Track Release

1. Update the local release tracking document under `.asc/releases/<version>.md` with:
   - Build number and upload timestamp.
   - Commit hash and summary of shipped changes.
   - What to Test notes and metadata diffs.
2. Commit release artifacts and build bumps:
   ```bash
   git add Config/Shared.xcconfig metadata/ .asc/releases/
   git commit -m "chore(release): bump build number to <build> for TestFlight"
   ```

---

## ⚡ Quick Reference Command Matrix

| Step | Command |
|---|---|
| Auto-bump build number | `bash scripts/testflight-next-build.sh --bump` |
| Archive & Export IPA | `bash scripts/archive-and-export.sh` |
| Publish to TestFlight | `source .asc/app.env && asc publish testflight --app "$APP_ID" --ipa "$IPA" --group "The Inner Circle" --test-notes "..." --locale "en-US"` |
| Update Review Notes | `asc review details-update --id "$REVIEW_DETAIL_ID" --notes "..."` |
| Update What's New | `asc localizations update --version "$VERSION_ID" --locale "en-US" --whats-new "..."` |
| Update Description | `asc localizations update --version "$VERSION_ID" --locale "en-US" --description "..."` |
