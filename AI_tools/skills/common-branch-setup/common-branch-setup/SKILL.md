---
name: branch-setup
description: >-
  Ensures the git working tree is clean and creates a correctly-named feature branch from an up-to-date develop branch. Use this skill when a user is about to start working on a new feature, user story, or task and needs to set up the correct branch. Triggers on phrases like "開始新功能", "建立 feature branch", "我要開發新功能", "setup feature branch", "create feature branch", "start new feature", "checkout new branch".
---

# Git Feature Branch Setup

## Overview

This skill orchestrates the full git setup flow before starting a new feature: it checks for a
clean working tree, ensures the base is `develop`, syncs with remote, and creates a
`feature/VSTS{id}-{name}` branch. Use the bundled script for reliable execution.

## Workflow

Run the setup script bundled with this skill. Use the glob tool or `/skills info branch-setup` to locate the `scripts/setup_feature_branch.py` path, then run:

```bash
# Interactive mode (will prompt for VSTS ID and branch name)
python <skill-dir>/scripts/setup_feature_branch.py

# Non-interactive mode
python <skill-dir>/scripts/setup_feature_branch.py \
  --vsts-id 123456 --name add-login-page
```

The script performs these steps in order:

### Step 1 — Dirty State Check
If uncommitted changes, staged files, or untracked files exist, prompt the user:

| Choice | Behaviour |
|--------|-----------|
| **保留現有異動** | `git stash push -u` → create branch → `git stash pop` (changes move to new branch) |
| **自動 Stash** | `git stash push -u` → create branch (changes stay in stash) |
| **自行處理** | Exit; user cleans up manually |

### Step 2 — Ensure on `develop`
- If on a `feature/*` branch → auto-switch to `develop`
- If on any other branch → prompt user to confirm switch

### Step 3 — Sync `develop`
```bash
git pull origin develop
```

### Step 4 — Create Feature Branch
Branch naming convention:
```
feature/VSTS{xxxxxxx}-{description}
```
- `{xxxxxxx}` — Azure DevOps (VSTS) Work Item ID (digits only)
- `{description}` — lowercase, hyphen-separated description (e.g., `add-login-page`)

Example: `feature/VSTS123456-add-login-page`

## Manual Fallback

If the script cannot be run, follow these steps manually:

```bash
# 1. Check dirty state
git status

# 2. If dirty, stash
git stash push -u -m "wip: before feature branch"

# 3. Switch to develop
git checkout develop

# 4. Sync
git pull origin develop

# 5. Create feature branch
git checkout -b feature/VSTS{id}-{name}

# 6. Restore stash if needed
git stash pop
```
