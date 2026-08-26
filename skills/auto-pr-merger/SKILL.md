---
name: auto-pr-merger
description: Automatically fetches open Pull Requests, runs lint and format checks, rebases against main, and attempts to resolve basic merge conflicts. If tests and checks pass cleanly, merges the PR into main. Activate when the user says "merge all PRs", "process open PRs", or "auto rebase and merge".
---

# Auto PR Merger Agent

This skill provides an automated, engineering-grade workflow for AI agents to systematically review, test, rebase, and merge open Pull Requests (PRs) in Git/GitHub repositories.

## Core Workflow

Execute the following sequence strictly upon activation:

### 1. Fetch Open PRs
Query open pull requests via GitHub CLI:
```bash
gh pr list --state open
```
If no open PRs exist, inform the user and exit cleanly.

### 2. Process Each PR Sequentially
For each open PR:

#### 2.1 Checkout the Branch
```bash
gh pr checkout <pr-number>
```

#### 2.2 Rebase Onto Main
```bash
git fetch origin main
git rebase origin/main
```

#### 2.3 Resolve Conflicts
- If minor merge conflicts occur, attempt automated resolution using semantic understanding of both branches.
- **If conflicts are complex or involve high-risk business logic**: abort the rebase (`git rebase --abort`), post a comment on the PR indicating that manual conflict resolution is required, and skip to the next PR.

#### 2.4 Run Lint & Format Checks
- Detect project tooling (e.g., `npm`, `yarn`, `pnpm`, `cargo`, `swiftformat`).
- Run configured lint and formatting scripts (e.g., `npm run lint`, `npm run format`).
- If formatting issues are detected, auto-fix and commit.
- If unresolvable lint errors remain, push fixes to PR, comment with details, and skip.

#### 2.5 Run Automated Tests
- Run test suites (e.g., `npm test`, `swift test`, `cargo test`).
- If any test fails, comment on the PR with the failure log and skip merging.

#### 2.6 Merge PR
- Once rebase, formatting, and tests all pass cleanly:
```bash
git push --force-with-lease
gh pr merge <pr-number> --rebase --delete-branch
```

### 3. Summary Report
Deliver a concise Markdown summary:
- **Successfully Merged**: List PR numbers and titles.
- **Skipped / Blocked**: List PR numbers, titles, and specific blocking reasons (e.g., conflicts, test failure, lint failure).
