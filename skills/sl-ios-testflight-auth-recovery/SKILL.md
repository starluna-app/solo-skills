---
name: sl-ios-testflight-auth-recovery
description: >-
  Diagnose and recover StarLuna iOS TestFlight release failures involving asc credentials,
  App Store Connect API keys, macOS Keychain access, Xcode codesigning, or builds that do not
  appear after upload. Use when asc says credentials or profile not found, auth login fails,
  xcodebuild reports errSecInternalComponent, or TestFlight processing is ambiguous. Do not
  use for ordinary source compilation errors unless they appear while recovering a release.
---

# TestFlight Authentication and Signing Recovery

Recover the failed stage without creating or rotating credentials unnecessarily. Keep the
original release scope and approval boundary: diagnosis does not authorize upload, beta
distribution, metadata changes, or App Review submission.

## Start by Classifying the Failure

Treat these as separate systems:

1. `asc` authenticates to the App Store Connect API with an API key.
2. `xcodebuild` and `codesign` sign the archive with certificate private keys in the macOS
   Keychain.
3. Apple processes an uploaded IPA asynchronously and later creates the TestFlight build.

Do not assume signing into Xcode repairs `asc`, or that a working `asc` session proves
`codesign` can use its private key.

Read [references/recovery-playbook.md](references/recovery-playbook.md) before taking recovery
actions. It contains the diagnostic decision tree, safe commands, incident evidence, failed
approaches, and escalation conditions.

## Recovery Invariants

- Inspect and reuse existing credentials before considering `asc auth login`, a new API key,
  or certificate rotation.
- Never print, read into the conversation, commit, or copy the contents of a `.p8` file.
- Prefer command-scoped environment credentials. Do not persist private-key material in a
  repository or config file merely to bypass a broken Keychain profile.
- Never pass the macOS login password with `security ... -p`; let the user enter it at the
  secure prompt.
- Run a read-only ASC request before archiving or uploading.
- If the upload was committed, wait for that upload. Do not retry and create a duplicate build.
- Once recovery succeeds, resume the original release at the failed stage. Do not bump the
  build number again unless ASC already contains that build number.

## Completion Evidence

Report each layer independently:

- ASC API access: a read-only build query succeeds for the intended app.
- Signing: the archive ends with `** ARCHIVE SUCCEEDED **`.
- Packaging: export succeeds and the IPA identity/environment matches the intended release.
- TestFlight: the exact version and build reach `VALID`; confirm the intended beta group or
  that its `hasAccessToAllBuilds` setting already grants access.

An upload acknowledgement is not TestFlight completion. Xcode sign-in, installed identities,
or a successful simulator build are not archive-signing evidence.
