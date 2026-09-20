---
name: local-first-icloud-sync-release
description: Plan, implement, migrate, and release local-first SwiftData/CloudKit sync with safe multi-device and Apple Watch behavior. Use for iCloud adoption, CloudKit schema changes, sync recovery, or production-schema/TestFlight gates; not for ordinary local-only persistence edits.
---

# Local-First iCloud Sync Release

Use this skill when a local-first Apple app adopts or changes iCloud/CloudKit persistence. Preserve local operation and treat production CloudKit schema deployment as an explicit, separate release action.

## Before changing code

1. Read the repository's applicable `AGENTS.md` files and the feature specification. Inspect the real model schema, model-container construction, existing store location, migrations, entitlements, app/widget/watch targets, cached repository state, and all destructive commands.
2. State the changed surface and direct reproduction cases before testing.
3. Write or update a short sync behavior contract before implementation when any of these are undecided: sync scope, first-device behavior, stable identity, concurrent edits, delete-vs-edit, global deletion, Apple Account changes, offline behavior, Watch commands, or user-facing status.
4. Verify current Apple documentation and the project SDK/API surface. Do not paste conceptual CloudKit configuration or assume a capability is enabled.

## Required invariants

- The app remains fully functional, including durable writes, without network access or an iCloud account. Never reset user data to recover from a cloud failure.
- Keep local source data authoritative for the running app. CloudKit is asynchronous persistence and cross-device convergence, never a live control bus.
- Preserve stable logical identifiers through migration. Do not use a storage uniqueness constraint as the cross-device identity or deduplication strategy.
- Make incoming store changes observable by repositories, UI state, App Group snapshots, widgets, and derived projections. Never issue a collection-wide replacement/delete based on a stale in-memory cache.
- Keep derived state and transient UI/system state local. Recompute it from synchronized source records.
- Create, update, and delete records with an explicit per-entity merge policy. Preserve independent additions. Do not silently delete malformed or conflicting user data.
- Treat a user-requested cloud purge as intentional. Do not silently re-upload it; offer an explicit recovery/back-up action only if the product contract permits it.
- Keep user-facing sync status truthful: show restoration, unavailability, and actionable failure; do not claim a global completion/progress state unless the framework supplies reliable evidence.

## Schema and migration

- Treat CloudKit enablement as a migration project. Inventory every persisted type, relationship, delete rule, default, uniqueness constraint, and persisted URL before changing configuration.
- Add an explicit migration plan when the actual SwiftData schema requires one. Test a frozen production-like old store and prove that templates, relationships, entries, settings, IDs, time zones, and raw intervals survive.
- Validate CloudKit compatibility from the current Apple documentation and the deployment SDK. Maintain optionality/defaults/inverses/delete behavior compatible with the selected framework rather than blindly flattening the domain model.
- Seed only deterministic, idempotent state. Keep application-provided catalogs static where possible; never let each device manufacture duplicate built-ins.

## Multi-device and Watch behavior

- Use the documented current-state versus durable-command distinction: state snapshots may be replaced, but user commands require unique IDs, idempotent processing, acknowledgement, and deterministic ordering.
- Use immediate WatchConnectivity messaging when reachable. For offline Watch actions, persist a command outbox and queue durable background transfer; reconcile with the phone's canonical state on acknowledgement. Do not make a Watch a competing full database unless standalone Watch operation is explicitly in scope.
- Test paired device behavior on physical hardware. Simulators do not prove CloudKit or WatchConnectivity delivery.

## Release gates

1. Test the migration and sync contract on development-signed physical devices in the CloudKit Development environment.
2. Inspect the generated development schema and all proposed production changes. A production schema is additive: deployed record types and fields cannot be casually removed, renamed, or repurposed.
3. Stop and obtain explicit user approval before enabling capabilities against production or deploying the schema to CloudKit Production.
4. After production deployment, validate an actual TestFlight build against Production. Do not describe a Development-environment result as TestFlight proof.
5. Run the changed-surface tests plus the necessary build targets. When the requester explicitly requires no regression failures or the change is a release candidate, run the repository's full relevant test suite; report the exact suites and physical-device scenarios separately.

## Paceful decisions

When this skill is used for `/Users/sl/Projects/time-ios`, read [the Paceful sync contract](references/paceful-sync-contract.md) before acting. It records approved product decisions that must not be re-litigated or weakened without the user's direction.
