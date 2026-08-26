# StarLuna Production Caching Patterns

## 1. FounderPortal / Crackit: Immutable Evaluation Versions

- **Pattern**: `EvaluationFlowViewModel.swift` holds an `IdeaWorkspaceCache` across the lifecycle. `HistoryView` invokes `loadIfNeeded()`, avoiding redundant fetches on navigation pop/push.
- **TTL**: None. Completed version histories are immutable snapshots. Pull-to-refresh serves as the explicit live re-fetch.
- **Invalidation**: `createDraft`, appending interview answers, completing an evaluation, or advancing stages explicitly invalidates the list cache because parent row badges, score cards, and update timestamps change.
- **Lesson**: Separate "mutable current state" from "completed immutable snapshots". Avoid replacing domain events with arbitrary 5-minute timers.

## 2. Luna Bee (`path`): Offline-First, User-Partitioned Disk Cache

- **Pattern**: `TravelPlansStore.swift` is the app-wide source of truth. `loadIfNeeded()` executes once per session; pull-to-refresh triggers `reload()`. Local mutations call `upsert()` / `remove()` on both memory and disk structures.
- **Storage**: `CodableDiskCache.swift` writes an envelope (`payload` + `cachedAt`) to `Caches/StructuredCache/<namespace>/<userID>.json`. Uses atomic writes and partitions by user ID so the OS can evict safely without data corruption.
- **Offline Fallback**: Hydrates from cache first on startup. Network failure preserves cached data instead of resetting to empty arrays.
- **Entitlements**: Remote-first with cached fallback in `LiveDataRepositories.swift`. Network errors return previously verified entitlements to prevent erroneously locking out paid subscribers.
- **Lesson**: Persistent caches must distinguish speed/offline convenience from authorization truths.

## 3. Shooting Star (`marketing-ios`): Scoped Session Cache

- **Pattern**: `RevealedPostCache` uses a composite scope key: `(userID, projectID, planID)`. Any change in active scope purges entries.
- **Invalidation**: Successful regeneration overwrites post entries. User sign-out calls `removeAll()`.
- **Lesson**: Cache keys are rarely raw string IDs. Whenever ownership is bound to workspace, user, or environment, scope must form part of the key.

## Review Checklist

1. Does re-entering a view read from the store rather than issuing new network requests?
2. Does every mutation update or invalidate related caches?
3. Does pull-to-refresh force a live fetch while retaining existing data during the request?
4. Is cached data partitioned by user ID to prevent cross-account leakage?
5. Do network failures preserve valid cached states instead of clearing UI?
6. Are test cases present for duplicate loads, force refresh, scope switching, and offline fallback?
