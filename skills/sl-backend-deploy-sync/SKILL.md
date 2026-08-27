---
name: sl-backend-deploy-sync
description: Dual-branch synchronization and deployment verification agent for repositories operating under the UAT/PROD model (e.g. starluna-portal, starluna-backend). Safely validates commit parity between uat and main, fast-forwards clean merges, executes safety pre-flights, and pushes synchronized updates to both origin/uat and origin/main. Use when pushing backend or portal changes, synchronizing UAT and Production branches, or verifying environment parity.
---

# Dual-Branch Deployment & Branch Synchronization Agent

Use this skill to maintain synchronization between `uat` (staging / local dev environment) and `main` (production release environment) in dual-branch repositories like `starluna-portal` and `starluna-backend`.

## Core Philosophy

1. **Parity by Default**: When changes are verified and ready for release, both `origin/uat` and `origin/main` must converge to the same commit hash.
2. **Fast-Forward Only**: Avoid messy merge commits when syncing production and staging branches. Use `--ff-only` to ensure a linear, reproducible git history.
3. **Automated Parity Verification**: Always assert `git rev-list --left-right --count main...origin/uat` equals `0 0` before finishing.

---

## 🚀 Quick Execution

Run the bundled synchronization script from within the repository root:

```bash
bash /Users/sl/Projects/solo-skills/skills/sl-backend-deploy-sync/scripts/sync-branches.sh
```

---

## 🛠️ Step-by-Step Manual Workflow

### 1. Preflight Check
Ensure working directory is clean:
```bash
git status --porcelain
```

### 2. Commit & Push to Current Branch
```bash
git add .
git commit -m "<type>(<scope>): <descriptive message>"
git push origin <current_branch>
```

### 3. Synchronize Dual Branch
```bash
# If on main, sync to uat:
git checkout uat
git merge main --ff-only
git push origin uat
git checkout main

# If on uat, sync to main:
git checkout main
git merge uat --ff-only
git push origin main
git checkout uat
```

### 4. Parity Assertion
```bash
git rev-list --left-right --count origin/main...origin/uat
# Expected output: 0 0
```
