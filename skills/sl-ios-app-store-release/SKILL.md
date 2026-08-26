---
name: sl-ios-app-store-release
description: End-to-end iOS App Store release workflow, taking an Xcode project to "Submit for Review". Features human-in-the-loop decision gates, automated metadata/pricing/age-rating push via asc CLI, and drives xcodebuild archive → IPA export → upload to App Store Connect / TestFlight. Use when releasing to the App Store, uploading iOS apps, managing App Store Connect releases, TestFlight beta distribution, or resolving review rejections.
---

# iOS App Store Release Workflow (v1.0 First Release & Subsequent Builds)

Shipping an Xcode project to the App Store involves 10+ distinct phases. This skill breaks the process into structured phases, highlighting automated CLI steps, required human decisions, and Apple web UI requirements.

---

## 🎯 Design Principles

1. **Gather Upfront, Then Execute**: Collect all key values (bundle ID, app name, ASO keywords, pricing tier, territories) before modifying code or configs.
2. **Automate via API & CLI**: Push metadata, categories, age ratings, pricing schedules, and review contact info via `asc` CLI rather than manual web UI clicks.
3. **Gated Human-in-the-Loop Decisions**: App Store screenshots, App Privacy submission, territory initialization, and final Submit for Review are human-confirmed steps.
4. **Independent Release Tracking**: Track each release in `.asc/releases/<version>.md` with a clean index in `.asc/releases/README.md`.
5. **Never Auto-Submit Without Confirmation**: Uploading to TestFlight ≠ Submitting for App Store Review.

---

## Internal TestFlight Fast-Path (Subsequent Builds)

For internal testing iterations where metadata updates are not needed, follow the streamlined path: **Context preflight → Get safe ASC build number → Archive → Export → Upload to internal TestFlight group → Wait for `VALID`**.

Run the preflight check:
```bash
bash skills/sl-ios-app-store-release/scripts/testflight-preflight.sh <MARKETING_VERSION>
```

---

## 📋 Release Tracking Structure

```text
<project>/.asc/
├── app.env                 # Project config & ASC API auth references
├── artifacts/              # Archive and IPA output directory
│   ├── <scheme>.xcarchive
│   └── <scheme>.ipa
└── releases/
    ├── README.md           # Index: Latest = 1.0; lists historical releases
    ├── 1.0.md              # v1.0 progress tracking checklist
    └── 1.1.md              # v1.1 progress tracking checklist
```

---

## 🚀 The 7 Release Phases

### Phase 0: Project & ASC Preflight Initialization
```bash
bash skills/sl-ios-app-store-release/scripts/release-init.sh <VERSION> <BUILD>
```
- Verify working tree is clean and synced with remote.
- Confirm Developer Team ID and Admin API key credentials.

### Phase 1: Preflight Questions & Consent
- Confirm version number, bundle ID, and incremental build number.
- Confirm backend schema/migration deployment status.

### Phase 2: Metadata & Asset Validation
```bash
bash skills/sl-ios-app-store-release/scripts/validate-readiness.sh
```
- App icon: 1024x1024 PNG, **no alpha channel**.
- Privacy strings present in `Info.plist`.
- App Store screenshots: 6.9" (1320x2868) and 6.5" (1284x2778).

### Phase 3: Archive & IPA Export
```bash
bash skills/sl-ios-app-store-release/scripts/archive-and-export.sh <SCHEME>
```
- Runs `xcodebuild archive` in Release configuration.
- Exports IPA with `ExportOptions.plist`.

### Phase 4: Validate & Upload to TestFlight
```bash
bash skills/sl-ios-app-store-release/scripts/upload-ipa.sh <APP_ID> <IPA_PATH>
```
- Executes `asc xcode validate`.
- Uploads to App Store Connect and monitors Apple processing status until `VALID`.

### Phase 5: Push Metadata & Version Info
```bash
bash skills/sl-ios-app-store-release/scripts/push-all-metadata.sh <APP_ID> <VERSION>
```
- Synchronizes localized description, keywords, support URL, and marketing URL.

### Phase 6: Submit for Review (Human Confirmed)
```bash
bash skills/sl-ios-app-store-release/scripts/submit-for-review.sh <APP_ID> <VERSION>
```
- Runs final strict submission validation.
- Submits for Apple App Review only upon explicit user confirmation.

---

## 📚 References & Troubleshooting
- [references/aso-checklist.md](references/aso-checklist.md) — App Store Optimization keyword and description checklist.
- [references/signing-troubleshoot.md](references/signing-troubleshoot.md) — Resolving codesigning, certificate, and profile errors.
- [references/common-pitfalls.md](references/common-pitfalls.md) — Avoiding Apple App Review rejections (Guidelines 5.1.1, 5.1.2, formatting rules).
- [references/testflight-internal-release.md](references/testflight-internal-release.md) — TestFlight internal distribution guide.
