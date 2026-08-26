---
name: ios-cache
description: Design, implement, or review local caching strategies for SwiftUI and iOS applications. Covers duplicate network call prevention, view re-entry performance, offline fallbacks, per-user cache isolation, cache invalidation on mutation, pull-to-refresh semantics, image caching, and cross-session state hydration.
---

# iOS Caching Strategies

Always identify the source of truth, mutability, and user-visible staleness risk before picking arbitrary TTLs.

## Decision Matrix

1. **Document Per Resource**: Owner, scope (account/project/version), mutability, offline utility, data sensitivity, and mutation entry points.
2. **Strategy Selection**:
   - **Session-shared mutable state**: Same account, frequent re-entry, kept consistent by local mutations. Use an app-owned `@Observable` or `ObservableObject` store where `loadIfNeeded()` loads at most once per session.
   - **Immutable snapshots**: Cache by version ID or content hash with NO arbitrary TTL. Re-fetch only on explicit refresh or when a new version is created.
   - **Cross-session / Offline persistence**: Use Codable disk caches in `Caches/` partitioned by user ID (`<namespace>/<userID>.json`). Hydrate from cache first, then refresh in background.
   - **Critical Entitlements (Subscriptions / Auth)**: Remote-first. Use cached values strictly as offline fallbacks; never treat cache misses as free/unauthorized.
   - **Images & Binary Blobs**: Two-tier (Memory + `Caches/`) keyed by URL or content hash, allowing system eviction.
3. **Centralize Reads**: Place read requests in stores/repositories, never directly in SwiftUI `body` or individual child views.
4. **Pull-to-Refresh**: Always bypass cache and fetch live; display existing cached items with a loading indicator rather than clearing the list.
5. **Post-Mutation Synchronization**: After a successful mutation, `upsert`/`remove` items using the server response, or `invalidate()` if state cannot be cleanly merged. Keep existing cache on network failure.

## SwiftUI Pattern

```swift
@MainActor final class ResourceStore: ObservableObject {
  @Published private(set) var items: [Item] = []
  private var hasLoaded = false

  func loadIfNeeded() async {
    guard !hasLoaded else { return }
    await refresh()
  }

  func refresh() async {
    do {
      items = try await repository.fetch()
      hasLoaded = true
    } catch {
      // Retain existing cached items on failure
    }
  }

  func upsert(_ item: Item) {
    if let idx = items.firstIndex(where: { $0.id == item.id }) {
      items[idx] = item
    } else {
      items.append(item)
    }
  }

  func remove(id: Item.ID) {
    items.removeAll { $0.id == id }
  }

  func invalidate() {
    hasLoaded = false
  }
}
```

See [references/starluna-examples.md](references/starluna-examples.md) for production-tested patterns from Luna Bee, FounderPortal, and Shooting Star.
