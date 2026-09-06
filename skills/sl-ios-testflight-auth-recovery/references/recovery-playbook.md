# TestFlight recovery playbook

## Contents

- Failure decision tree
- ASC API credential recovery
- Xcode signing and Keychain recovery
- Hidden compiler errors during recovery
- Apple upload processing
- Session incident record

## Failure decision tree

| Symptom | Layer | First useful check | Likely recovery |
|---|---|---|---|
| `credentials not found for profile` | ASC API | `asc auth status --output json` | Bypass the unusable stored profile and supply the existing key for one command |
| Keychain error `-25293` during `asc auth login` | ASC credential storage | Confirm an existing `.p8` matches the Key ID | Avoid login; use command-scoped credentials |
| `.p8` permission warning | Local API-key file | Inspect mode without printing content | Restrict the exact file to mode `600` |
| `CodeSign ... errSecInternalComponent` | Xcode signing | `security find-identity -v -p codesigning` and `security show-keychain-info` | Unlock the login Keychain, then retry the same archive |
| Archive fails after signing was repaired | Swift/Release build | Capture the complete archive log | Fix the reported source error; do not keep changing credentials |
| Upload says committed but build is absent | Apple processing | Keep the original `asc publish ... --wait` running | Wait and query the exact version/build; do not upload again |
| Beta group is skipped because it receives all builds | TestFlight distribution | Inspect group configuration/result | This is success, not an assignment failure |

## ASC API credential recovery

### 1. Establish what already exists

Use read-only checks and avoid displaying secret material:

```bash
asc auth status --output json
rg -n '^(ASC_KEY_ID|ASC_PROFILE|APP_ID)=' .asc/app.env 2>/dev/null
find "$HOME/Projects" -type f -name 'AuthKey_*.p8' -print 2>/dev/null
```

`asc auth status` listing a credential proves only that a profile record exists. It does not
prove the current process can retrieve the stored private key or make an authenticated request.

Match the filename `AuthKey_<KEY_ID>.p8` to the configured Key ID. An App Store Connect `.p8`
file is downloaded from Apple when the key is created; `asc auth login` registers an existing
file locally and does not generate or recover the Apple private key.

If the matching file is too permissive, restrict only that exact file:

```bash
chmod 600 "/absolute/path/to/AuthKey_<KEY_ID>.p8"
```

### 2. Test the existing key without storing it

Obtain the issuer ID from the team's existing secure configuration or previously registered
profile metadata. Do not infer it from another Apple team.

Run a read-only request with complete command-scoped credentials:

```bash
ASC_BYPASS_KEYCHAIN=1 \
ASC_KEY_ID="<KEY_ID>" \
ASC_ISSUER_ID="<ISSUER_ID>" \
ASC_PRIVATE_KEY_PATH="/absolute/path/to/AuthKey_<KEY_ID>.p8" \
asc builds list --app "<APP_ID>" --limit 3 --output table
```

Why `ASC_BYPASS_KEYCHAIN=1` matters: a saved default profile has higher resolution priority
than environment credentials. Unsetting `ASC_PROFILE` alone may still leave the default
Keychain profile selected, producing `credentials not found for profile` even though all three
environment fields were supplied. The bypass flag makes `asc` use the complete environment
credential set for that process only.

Use the same environment prefix for subsequent authorized `asc` commands. It changes no saved
profile and creates no key.

### 3. Approaches that did not solve this incident

- `asc auth status` looked healthy because it showed the Key ID, but live build queries failed.
- Supplying environment credentials while merely running `env -u ASC_PROFILE` still selected
  the saved default profile.
- `asc auth login` first rejected an overly permissive `.p8`; after mode `600`, Keychain storage
  failed with macOS error `-25293`.
- `asc auth login --bypass-keychain` would persist key material in a config file. Do not use it
  as an automatic workaround. Use it only when the user explicitly chooses that storage model
  and the destination is confirmed ignored and permission-restricted.
- Creating a new Apple API key was unnecessary. The existing key successfully accessed multiple
  StarLuna apps once Keychain profile resolution was bypassed.

## Xcode signing and Keychain recovery

ASC API authentication and archive signing are independent. After ASC access is repaired, an
archive can still fail like this:

```text
CodeSign ...
errSecInternalComponent
Command CodeSign failed with a nonzero exit code
```

Inspect the local state:

```bash
security find-identity -v -p codesigning
security list-keychains -d user
security default-keychain -d user
security show-keychain-info "$HOME/Library/Keychains/login.keychain-db"
```

`security find-identity` showing a valid Apple Development or Distribution identity proves the
certificate and associated key are discoverable. It does not prove a noninteractive `codesign`
process may use the private key.

If the login Keychain is locked, ask the user to run:

```bash
security unlock-keychain "$HOME/Library/Keychains/login.keychain-db"
```

The command prompts securely for the Mac login password. Never request the password in chat or
put it in shell history with `-p`. Retry the exact archive after the user unlocks the Keychain.

If the Keychain is unlocked and `errSecInternalComponent` persists, inspect the signing
certificate/private-key access control in Keychain Access. Updating the key partition list is a
broader Keychain ACL change and requires explicit user direction after explaining the scope; do
not apply it reflexively. Certificate rotation is later than ACL diagnosis, not the first step.

Signing into the Xcode Accounts UI may refresh developer accounts and provisioning profiles,
but it does not necessarily unlock the login Keychain for command-line `codesign`.

XcodeBuildMCP remains useful for simulator/device builds, tests, logs, and UI automation. It does
not itself repair Keychain ACLs, authenticate `asc`, or replace an archive/export/upload workflow
when no archive tool is exposed.

## Hidden compiler errors during recovery

Release wrappers often pipe `xcodebuild` through `tail`, so the final lines can report only
`Archiving project ... (N failures)`. After signing is fixed, capture one complete retry:

```bash
xcodebuild <the same archive arguments> > /tmp/testflight-archive.log 2>&1
rg -n -C 4 'error:|fatal error|ARCHIVE FAILED|The following build commands failed' \
  /tmp/testflight-archive.log
```

Use the exact project archive arguments; do not change build settings while diagnosing. A new
Swift error means authentication recovery worked and compilation is now the blocker.

In the September 2026 Luna Bee incident, unlocking the Keychain exposed Release whole-module
compile errors that Debug/simulator work had not caught: one missing structural brace and two
non-exhaustive switches after a real `serviceUnavailable` case replaced mock fallback behavior.
Those were source defects, not additional authentication failures.

After fixing source, run the Release archive again before committing a claimed release fix.

## Apple upload processing

For an authorized TestFlight release, prefer a waiter tied to the original upload:

```bash
ASC_BYPASS_KEYCHAIN=1 \
ASC_KEY_ID="<KEY_ID>" \
ASC_ISSUER_ID="<ISSUER_ID>" \
ASC_PRIVATE_KEY_PATH="/absolute/path/to/AuthKey_<KEY_ID>.p8" \
asc publish testflight \
  --app "<APP_ID>" \
  --ipa "/absolute/path/to/App.ipa" \
  --group "<INTERNAL_GROUP>" \
  --wait
```

`Upload committed in App Store Connect` means Apple accepted the upload transport. Keep waiting
for the build record and processing result. A temporary empty build list is normal during this
window.

Verify the exact build rather than relying on the latest row:

```bash
asc builds info \
  --app "<APP_ID>" \
  --version "<MARKETING_VERSION>" \
  --build-number "<BUILD_NUMBER>" \
  --platform IOS \
  --output json
```

Completion requires `processingState: VALID`. If an internal group has access to all builds,
`asc publish testflight` may report that assignment was skipped; the build is already available
to that group.

## Session incident record: September 2026

### Initial evidence and hypothesis

- `asc auth status` showed a default StarLuna profile and the expected Key ID.
- Live `asc builds list` returned `credentials not found for profile`.
- Xcode showed a signed-in StarLuna team, which did not explain the ASC CLI failure.
- Prior successful Shooting Star and Luna Bee releases were reviewed. They used the repository's
  raw archive/export workflow followed by `asc publish testflight`; no `asc auth login` occurred
  in those release sessions.

The evidence separated two questions: how to make `asc` use the already downloaded API key, and
whether `codesign` could access its separate certificate private key.

### Experiments and results

1. Supplying the key ID, issuer ID, and `.p8` path while unsetting `ASC_PROFILE` failed because
   the saved default profile still won credential resolution.
2. Adding `ASC_BYPASS_KEYCHAIN=1` made read-only build queries succeed for both Luna Bee and
   Shooting Star. This confirmed the existing API key was valid and shared across those apps.
3. The first archive then failed at widget `CodeSign` with `errSecInternalComponent`.
4. Three valid signing identities were installed, but `security show-keychain-info` could not
   access the login Keychain. Passwordless unlock also failed.
5. The user ran the secure `security unlock-keychain` command. The Keychain then reported
   `no-timeout`, and the next archive passed the earlier signing point.
6. Release-only Swift errors surfaced and were fixed. The archive and export succeeded.
7. The archived app was verified for the intended version/build and production backend before
   upload.
8. `asc publish testflight --wait` committed one upload, waited for Apple, and returned the exact
   build as `VALID`. The internal group was correctly skipped because it already received all
   builds.

### Generalized lesson

Do not collapse “TestFlight authentication” into one credential problem. Diagnose in order:

```text
ASC API key resolution -> archive certificate private-key access -> Release compilation
-> IPA environment/identity -> Apple upload processing -> beta-group access
```

Record evidence at each boundary and resume from the failed boundary. This avoids needless key
rotation, repeated build bumps, duplicate uploads, and false claims that an accepted upload is
already available in TestFlight.
