---
name: sl-ios-release-flow
description: Ship the next build of an iOS app (archive → export → validate → upload to TestFlight/App Store Connect) with a safety-gated pre-flight. Use when the user says "push out build N", "ship the next build", "cut a release", "upload to TestFlight", "release flow", or "create a new build". Runs blocker review, backend-deploy and cross-version (web/Android) dependency checks, confirms the build number, then drives xcodebuild + asc CLI. Gathers all inputs and consent upfront and prints a release briefing before doing anything. Never submits for App Review without explicit human confirmation.
---

# iOS Release Flow (ship the next build, safely)

A repeatable, gated process for cutting the *next* build of an iOS app that shares a backend
(e.g. Supabase) with other clients. It front-loads information gathering and consent, then runs
hard safety gates before touching the build pipeline.

> This skill assumes first-time App Store setup (bundle ID, app record, metadata, signing certs,
> ASC API key) is **already done**. For the very first submission, use a first-release skill instead.
> This skill is for shipping build N+1.

## Operating principles

1. **Gather + consent upfront.** Collect every value and decision at the start, print a **Release
   Briefing**, and get the user's go-ahead *before* mutating anything. Minimize mid-flow questions.
2. **Gates can stop the flow.** Two gates can halt: a **blocker review** (security/major bug/
   non-functional feature) and a **backend-dependency** check. When a gate trips, STOP, write a plan,
   and wait for the user. Do not "push through."
3. **Discover project values, don't hardcode.** Read IDs/paths from the repo (`.asc/app.env`,
   `project.pbxproj`, backend deploy scripts). Never paste secrets/tokens into files or this skill.
4. **Never auto-submit for review.** Uploading to TestFlight ≠ submitting. Submission is a separate,
   human-confirmed step.

---

## Phase 0 — Gather everything + print the Release Briefing

Do all of this read-only first, then present one summary and ask for consent.

### 0.1 Locate the repos and tooling

```bash
# iOS repo (run from its root). Confirm clean tree on the release branch.
git -C "$IOS_REPO" status --porcelain        # expect clean
git -C "$IOS_REPO" branch --show-current      # expect main (or the release branch)
git -C "$IOS_REPO" fetch --quiet && git -C "$IOS_REPO" rev-list --left-right --count origin/main...main

# ASC project config (do NOT print secrets)
cat "$IOS_REPO/.asc/app.env"                  # APP_ID, BUNDLE_ID, SKU, app name
asc auth status                               # confirm a credential (Admin/Developer role)

# Signing team must be a single value
grep -E "DEVELOPMENT_TEAM" "$IOS_REPO"/*.xcodeproj/project.pbxproj | sort -u

# Sibling repos that share the backend (discover; ask the user if unsure)
#   backend (migrations/functions/auth config), web client, future Android, etc.
ls ~/Projects | grep -iE "backend|portal|web|android"
```

### 0.2 Determine the last release and the commit range

```bash
# Latest build already on App Store Connect
asc builds list --app "$APP_ID" --output table | head -5
# Current version/build in the project
xcodebuild -project "$IOS_REPO"/*.xcodeproj -showBuildSettings -scheme "$SCHEME" 2>/dev/null \
  | grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" | sort -u
# The commit the last release shipped from (last release commit / tag). If unknown, ask the user.
# All work since then:
git -C "$IOS_REPO" log --oneline <LAST_RELEASE_REF>..HEAD
```

`<LAST_RELEASE_REF>` is the commit/tag of the previous shipped build. The release tracker
(`.asc/releases/<version>.md`) or the last `chore(release): bump build number` commit usually
identifies it. **If you can't determine it confidently, ask the user** — it scopes the whole review.

### 0.3 Print the Release Briefing and get consent

Present a single block like this, then wait:

```
─────────── RELEASE BRIEFING ───────────
App / bundle:      <name> (<BUNDLE_ID>), APP_ID <APP_ID>, team <TEAM_ID>
Version:           <MARKETING_VERSION>   (unchanged unless user says otherwise)
Build number:      <latest ASC build> → proposing <latest+1>
Commits to ship:   <N> since <LAST_RELEASE_REF>  (<short summary of themes>)
Backend repo:      <changes since last release? deployed?>
Other clients:     <web/Android repos that may be impacted>
Target:            TestFlight only  |  TestFlight → submit for review
─────────────────────────────────────────
```

Ask for explicit consent on, all at once:
- **Build number / version** to ship (default: latest ASC build + 1; version unchanged).
- **If backend changes are required and undeployed** — permission to deploy to the required
  instance(s) (and which: uat first, then prod).
- **Destination** — TestFlight only, or also submit for App Review afterward (default: TestFlight
  only; submission stays a later, separately-confirmed step).

---

## Phase 1 — Blocker review (GATE) 🚦

Review every commit since the last release for anything that should **block** shipping.

```bash
git -C "$IOS_REPO" diff <LAST_RELEASE_REF>..HEAD -- '<source-glob>' > /tmp/release.diff
```

Scan for (read the diff, not just grep):

| Class | What to look for |
|-------|------------------|
| **Secrets** | API keys/tokens, `sbp_`/`sb_secret_`, service-role keys, hardcoded passwords committed in source |
| **Injection / unsafe** | string-built queries, `dangerouslySetInnerHTML`, `eval`, unsanitized input |
| **Crash risk** | `try!`, `as!`, force-unwrap of network/optional data, `fatalError` on a live path |
| **Auth/data exposure** | broken access checks, PII logged at `.public`, debug/demo affordances not gated out of Release |
| **Major bug / regression** | reverted fixes, half-finished refactors, broken happy paths |
| **Non-functional feature** | feature flags off, stubbed/`TODO`/`FIXME` on a user-facing path, dead handlers |

Quick first pass:
```bash
grep -nE "^\+" /tmp/release.diff | grep -iE "sbp_|sb_secret|service_role|api[_-]?key|secret=|password\s*=\s*\"|try!|as!|http://|dangerouslySet|fatalError|privacy: ?\.public|TODO|FIXME"
```

**If a blocker is found → STOP.** Write a short remediation plan (issue → severity → fix → est.
effort), present it, and **wait for the user to choose** how to proceed (fix now / defer / ship
anyway with justification). Do **not** proceed to build.

If clean: state "blocker review: clean" with what you scanned, and continue.

---

## Phase 2 — Backend dependency check (GATE) 🚦

The build must not ship code that calls backend that isn't deployed to the **target** instance
(prod for a production build).

```bash
# New backend calls introduced by this release
grep -E "^\+" /tmp/release.diff | grep -nE "\.rpc\(|\.functions\.invoke\(|\.from\(" 

# For each new .rpc / edge function / table / column referenced, confirm it exists on the TARGET
# instance. With Supabase MCP or psql against the target project:
#   - RPC/function exists?            select proname from pg_proc where proname = '<fn>';
#   - table/columns exist?            select column_name from information_schema.columns
#                                     where table_name='<t>' and column_name in (...);
# Also check the backend repo for undeployed work:
git -C "$BACKEND_REPO" log --oneline <last-backend-deploy>..HEAD
ls "$BACKEND_REPO"/supabase/migrations | tail -5     # any new migration not yet pushed?
```

Also confirm **non-schema** backend prerequisites the new client code relies on, e.g.:
- Auth settings (email confirmation on/off, password policy, **SMTP provider + email rate limit**
  if the app now depends on auth emails like OTP).
- Edge-function secrets/config.
- Email templates (if the client expects a code/link format).

**If required backend changes are NOT deployed → STOP and get consent** to deploy to the required
instance(s). Deploy via the repo's documented scripts (migrations, `functions deploy`, the
Management-API template/config push), **uat first**, verify, then prod. Then continue.

If nothing new is required on the backend, state that explicitly (it's the common, happy case).

---

## Phase 3 — Cross-version impact check

This app shares a backend with other clients. Today: a **web** client. Future: **Android**.
A backend or shared-contract change can silently break or desync them.

For each sibling client repo, check whether this release's changes affect it:
- **Shared auth policy** (e.g. you raised the server password min-length → bump the web client's
  client-side validation to match, or web users hit a confusing server error).
- **Shared email templates / links** (a redesigned confirmation email affects web sign-up too).
- **Schema/contract changes** (a renamed/added column the other client reads).
- **Behavioral changes** (confirmation now required, new required field, etc.).

For each impacted sibling: either make the matching change (with consent + push to its branches) or
file a tracked follow-up. Note future clients (Android) in the release notes / status doc so the
contract change isn't forgotten.

---

## Phase 4 — Confirm build number + version, then bump

```bash
# Latest build already consumed on ASC (cannot reuse a number)
asc builds list --app "$APP_ID" --output table | head -3
```

Confirm with the user (already proposed in the Briefing): next build = latest ASC build + 1;
version unchanged unless this is a version bump. Then set it:

```bash
# Edit CURRENT_PROJECT_VERSION across all build configs (there are usually 2–4 occurrences).
sed -i '' "s/CURRENT_PROJECT_VERSION = <old>;/CURRENT_PROJECT_VERSION = <new>;/g" \
  "$IOS_REPO"/*.xcodeproj/project.pbxproj
xcodebuild -project "$IOS_REPO"/*.xcodeproj -showBuildSettings -scheme "$SCHEME" 2>/dev/null \
  | grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" | sort -u   # verify

git -C "$IOS_REPO" add *.xcodeproj/project.pbxproj
git -C "$IOS_REPO" commit -m "chore(release): bump build number to <new>"
```

(`agvtool new-version -all <new>` also works on projects with classic Info.plist versioning; on
build-setting-based versioning, editing `CURRENT_PROJECT_VERSION` directly is more reliable.)

---

## Phase 5 — Archive → Export → Validate → Upload

### 5.1 Pre-flight signing + config

```bash
# One DEVELOPMENT_TEAM value, the org/LLC team (not a Personal Team)
grep -E "DEVELOPMENT_TEAM" "$IOS_REPO"/*.xcodeproj/project.pbxproj | sort -u
# The Release config must point at the PRODUCTION backend xcconfig (so prod is baked in)
grep -nE "baseConfigurationReference" "$IOS_REPO"/*.xcodeproj/project.pbxproj
```

### 5.2 Archive (Release)

```bash
cd "$IOS_REPO"
rm -rf build/archive
xcodebuild -project *.xcodeproj -scheme "$SCHEME" \
  -configuration Release \
  -archivePath build/archive/"$SCHEME".xcarchive \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  archive
```

### 5.3 Export IPA

```bash
rm -rf build/ipa
xcodebuild -exportArchive \
  -archivePath build/archive/"$SCHEME".xcarchive \
  -exportPath build/ipa \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
ls -lh build/ipa/*.ipa
```

**Signing recovery** — if export fails with `Cloud signing permission error`, `No Accounts`, or
`No signing certificate "iOS Distribution"`:
- It usually means command-line Xcode can't see a usable App Store distribution identity/profile
  (e.g. the ASC API key is **App Manager** not Admin, or Xcode has no Apple ID account).
- Inspect: `security find-identity -v -p codesigning`,
  `asc certificates list --certificate-type IOS_DISTRIBUTION --output table`,
  `asc profiles list --profile-type IOS_APP_STORE --output table`.
- Fix path A (preferred): log Xcode into the Apple ID account, or use an **Admin** API key, then
  retry automatic signing.
- Fix path B (CLI): create an `IOS_DISTRIBUTION` cert via `asc certificates create --generate-csr`,
  import the cert+key into the login keychain, create a matching `IOS_APP_STORE` profile via
  `asc profiles create`, install it, and export with a **manual** `ExportOptions.plist` that names
  the certificate + profile. Remove the temporary key/cert material from the workspace afterward.

### 5.4 Verify the right backend is baked in (critical)

```bash
PLIST=build/archive/"$SCHEME".xcarchive/Products/Applications/"$SCHEME".app/Secrets.plist
/usr/libexec/PlistBuddy -c "Print" "$PLIST" | grep -iE "ENVIRONMENT|SUPABASE_URL|AUTH_MODE"
# Confirm it points at the PRODUCTION backend ref, not dev/uat/empty.
```

### 5.5 Validate, then upload (TestFlight)

```bash
ISSUER_ID="$(asc auth issuer-id | tr -d '\n')"
asc xcode validate --ipa build/ipa/"$SCHEME".ipa --api-key "$KEY_ID" --api-issuer "$ISSUER_ID"
# Expect: "VERIFY SUCCEEDED with no errors"

# Upload (commits immediately; --verify-timeout watches for instant failures). This does NOT submit.
asc builds upload --app "$APP_ID" --ipa build/ipa/"$SCHEME".ipa --verify-timeout 90s

# Poll until the build reaches VALID (Apple processing, ~5–30 min)
asc builds list --app "$APP_ID" --output table | grep " <new-build> "
```

---

## Phase 6 — Record + report (stop before submit)

- Update the release tracker `.asc/releases/<version>.md` (build number, build id, what shipped,
  open items, signing notes). This file is typically gitignored/local.
- Ensure the build-number bump commit is pushed.
- Print the final report: version/build, **build id**, processing state (VALID), prod-backend
  confirmed, what shipped, and any **open items** (backend settings to verify, sibling-client
  follow-ups). State clearly it is **TestFlight only, not submitted for review.**

Submission for App Review is a separate, human-confirmed step (final `asc validate --strict`, then
`asc review submit --confirm`). Do not run it as part of this skill unless the user explicitly asks.

---

## Tool & command reference (what to use when)

| Need | Tool / command |
|------|----------------|
| Inspect/auth App Store Connect | `asc auth status`, `asc apps list`, `asc builds list --app <id>` |
| Current version/build | `xcodebuild -showBuildSettings ... \| grep VERSION` |
| Bump build number | edit `CURRENT_PROJECT_VERSION` in pbxproj (or `agvtool new-version -all`) |
| Archive | `xcodebuild ... -configuration Release ... archive` |
| Export IPA | `xcodebuild -exportArchive -exportOptionsPlist ExportOptions.plist` |
| Inspect signing | `security find-identity -v -p codesigning`, `codesign -dv --verbose=4 <app>` |
| Manage certs/profiles | `asc certificates ...`, `asc profiles ...` |
| Validate IPA | `asc xcode validate --ipa <ipa> --api-key <id> --api-issuer <id>` |
| Upload to TestFlight | `asc builds upload --app <id> --ipa <ipa> --verify-timeout 90s` |
| Backend migrations/functions | repo scripts: `supabase db push`, `supabase functions deploy` |
| Backend auth config / email templates | Supabase Management API (`PATCH /v1/projects/<ref>/config/auth`) with a **personal access token** (`sbp_`), not the DB password or anon/publishable key |
| Verify backend schema/contract | Supabase MCP / `psql` read-only against the target project |

### Credential note (avoid the common mix-up)
- **DB password** → Postgres connections / `supabase db push` only.
- **Publishable / anon key** → client API calls only.
- **Management API** (auth config, email templates) → needs a **personal access token** (`sbp_…`).
- **ASC API key** for signing/export must be **Admin** (App Manager lacks Cloud Signing → export
  fails). Import a transient token only in-session; never commit it; clear it when done.

---

## Easy-to-miss checklist (add these to the flow)

- [ ] Working tree **clean** and the release branch **in sync with remote** before archiving.
- [ ] App **icon** unchanged-or-valid (1024×1024, **no alpha**), privacy usage strings present.
- [ ] **Encryption compliance** declared (`ITSAppUsesNonExemptEncryption`) so processing doesn't stall.
- [ ] Debug/demo affordances (test creds, env badges) confirmed **gated out of Release** (`#if DEBUG`).
- [ ] If subscriptions/IAP changed, confirm StoreKit still unlocks and product IDs/pricing are intact.
- [ ] **TestFlight "What to Test"** notes set for the new build (`--test-notes`/ASC) so testers know
      what changed.
- [ ] Each impacted **sibling client** (web now, Android later) updated or has a tracked follow-up.
- [ ] Critical backend **operational** settings verified for any newly email-dependent flow (SMTP
      provider + per-hour email rate limit).
- [ ] Build numbers are **monotonic** — a consumed ASC build number can't be reused; always +1.
- [ ] Rollback awareness: you can't delete a bad uploaded build cheaply — fix, bump, re-upload.
- [ ] Optionally **tag** the release commit (`git tag v<version>-build<n>`) to mark the ship point
      for the next run's `<LAST_RELEASE_REF>`.
