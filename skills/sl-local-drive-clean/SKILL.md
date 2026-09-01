---
name: sl-local-drive-clean
description: Intelligently identifies and cleans up massive developer bloat, AI sandbox runtimes, container images, Xcode test clones, package caches, and system junk. Categorizes cleanups into Tier 1 (zero-risk auto-purge), Tier 2 (developer rebuildables with interactive confirmation), and Tier 3 (high-impact system/media resets with explicit warnings).
---

# Local Drive Clean v2.0

This skill systematically identifies and reclaims hundreds of gigabytes of disk space across developer tooling, AI sandbox environments, container runtimes, and macOS system caches.

> ⚠️ **Important Permission Note:** Cleaning `~/Library/Developer` (specifically `XCTestDevices` and `XcodeBuildMCP`) and container volumes requires elevated/unsandboxed execution (`BypassSandbox: true`), otherwise macOS sandbox blocks deletion silently.

---

## Step 1: 360° Storage Scan

Run a structured scan across all major developer and system storage categories:

```bash
# 1. Check disk capacity
df -h /

# 2. Xcode & Apple Developer Bloat
du -sh ~/Library/Developer/XCTestDevices 2>/dev/null || true
du -sh ~/Library/Developer/XcodeBuildMCP 2>/dev/null || true
du -sh ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true
du -sh ~/Library/Developer/Xcode/"iOS DeviceSupport" 2>/dev/null || true
xcrun simctl runtime list 2>/dev/null || true

# 3. AI & Sandbox Tooling
du -sh ~/Library/"Application Support"/Claude/vm_bundles 2>/dev/null || true
du -sh ~/.cache/codex-runtimes ~/.cache/uv ~/.cache/huggingface 2>/dev/null || true

# 4. Containers & Virtual Machines
du -sh ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw 2>/dev/null || true

# 5. Application Updaters & Caches
du -sh ~/Library/Caches/com.microsoft.VSCode.ShipIt ~/Library/Caches/*-updater ~/Library/Caches/ms-playwright 2>/dev/null || true
du -sh ~/Library/"Application Support"/Code/CachedExtensionVSIXs 2>/dev/null || true

# 6. Package Manager & Language Caches
du -sh ~/.npm ~/.cocoapods ~/.gradle ~/.pub-cache ~/.cargo/registry ~/Library/Caches/org.swift.swiftpm 2>/dev/null || true

# 7. macOS System & Media Data
du -sh ~/Library/Containers/com.apple.wallpaper.agent 2>/dev/null || true
tmutil listlocalsnapshots / 2>/dev/null || true
```

---

## Step 2: 3-Tier Cleaning Workflow

Structure the cleanup into three distinct safety tiers with appropriate confirmation flows:

### 🟢 Tier 1: Zero-Risk Auto-Purge (No Confirmation Needed)
Pure transient caches and updater leftovers that auto-regenerate on demand:
- **Electron App Auto-Updater DMGs**: `rm -rf ~/Library/Caches/*.ShipIt ~/Library/Caches/*-updater`
- **Package Manager Caches**: `npm cache clean --force`, `pip cache purge`, `brew cleanup --prune=all || true`
- **Dead/Unavailable Simulators**: `xcrun simctl delete unavailable`
- **QuickLook & System Thumbnails**: `qlmanage -r cache`

### 🟡 Tier 2: Developer Rebuildables (Standard Multi-Select Confirmation)
Developer artifacts that are 100% safe to delete, but recompiling or re-downloading them on the next run will take 30–60 seconds longer. Present options using `ask_question` with `is_multi_select: true` and display the exact impact:
- **XCTest Parallel Test Clones** (~100–300+ GB): `rm -rf ~/Library/Developer/XCTestDevices/*`
  * *Impact:* Next test run will recreate clean test clones.
- **XcodeBuildMCP Workspaces** (~10–60+ GB): `rm -rf ~/Library/Developer/XcodeBuildMCP/workspaces/* ~/Library/Developer/XcodeBuildMCP/derived-data/*`
  * *Impact:* Next MCP session re-indexes workspace freshly.
- **Xcode DerivedData & DeviceSupport** (~20–80+ GB): `rm -rf ~/Library/Developer/Xcode/DerivedData/* ~/Library/Developer/Xcode/"iOS DeviceSupport"/*`
  * *Impact:* Next Xcode build recompiles from scratch.
- **Claude Desktop VM Bundles** (~5–10 GB): `rm -rf ~/Library/"Application Support"/Claude/vm_bundles/*`
  * *Impact:* Next Claude local code sandbox run downloads a fresh VM bundle.
- **VS Code Cached Extension Installers & Playwright Browsers**: `rm -rf ~/Library/"Application Support"/Code/CachedExtensionVSIXs/* ~/Library/Caches/ms-playwright/*`
  * *Impact:* Clean caches; Playwright tests re-install browsers if needed.
- **Unused Simulator Runtimes**: `xcrun simctl runtime delete <UUID>` (interactive per-runtime selection).

### 🟠 Tier 3: High-Impact Reset (Explicit Warning Alert + Per-Item Opt-In)
User-facing media, virtual machine storage, or system restore points. Always present detailed warnings before execution:
- **Docker Desktop VM Virtual Disk (`Docker.raw`)** (~20–100+ GB):
  * *Command:* `docker system prune -a --volumes -f` or remove sparse `Docker.raw`.
  * ⚠️ *Warning:* Resets all stopped containers, unmounted local database volumes, and unpinned images.
- **macOS 4K Aerial Video Wallpapers** (~5–20 GB):
  * *Command:* `rm -rf ~/Library/Containers/com.apple.wallpaper.agent/Data/Library/"Application Support"/com.apple.wallpaper/Store/*`
  * ⚠️ *Warning:* Dynamic video wallpapers reset to Apple defaults until re-selected in System Settings.
- **APFS Local Snapshots**:
  * *Command:* `for s in $(tmutil listlocalsnapshotdates 2>/dev/null | grep -v 'Snapshot'); do tmutil deletelocalsnapshots "$s"; done`
  * ⚠️ *Warning:* Deletes local on-disk Time Machine rollback points.

---

## Step 3: Verification & Reporting

Always verify the reclaimed space with `df -h /` and present a structured summary table showing:
1. Available space Before vs. After
2. Total space reclaimed (in GB)
3. Breakdown of all cleaned components

---

## Reference Documentation

For detailed architectural rationale, sequence diagrams, and root-cause analysis of developer storage bloat, see [references/architecture.md](references/architecture.md).
