# `<repo>/scripts/bin/`

Directory containing contributor scripts for briteTest workflow.

**⚠️ IMPORTANT: All scripts must be installed via `mkclone` or `installscripts`**

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

---

## Quick Start

```bash
# Clone repository with automatic setup (RECOMMENDED)
# Can run from ANYWHERE on your local machine
mkclone

# Then enter directory and use scripts
cd BriteTest
commit -h
```

For detailed setup: See [`docs/SETUP_FIRST_CLONE.md`](../../docs/SETUP_FIRST_CLONE.md)

---

## Files

### Setup and Installation

- **`mkclone`**: Clone the repository with automatic installation of scripts and Git hooks.
  - **Can run from ANY directory on your local machine**
  - Clones repository
  - Installs scripts
  - Installs Git hooks
  - Adds scripts to PATH
  - **USE THIS FOR FIRST CLONE** ✅

- **`installscripts`**: Make all scripts executable and add `<repo>/scripts/bin/` to PATH.
  - Also installs Git hooks
  - Idempotent (safe to run multiple times)

### Git Hook Protection

**All scripts below work with Git hooks. See [`docs/GIT_HOOKS_WORKFLOW.md`](../../docs/GIT_HOOKS_WORKFLOW.md) for details.**

### Branch Workflow Scripts

- **`mkbranch`**: Create new branches with policy validation.
  - Usage: `mkbranch fix/my-fix main` or `mkbranch dev/feature v1.0.0`
  - Only allows `fix/` and `dev/` for targeted branches
  - Creates local branch from parent
  - Optionally pushes to remote with `-r`

- **`commit`**: Commit and optionally push changes.
  - Usage: `commit -m "Your message"`
  - Use instead of `git add` and `git commit`
  - Add `-p` flag to push: `commit -m "msg" -p`
  - Add `-v` for verbose output
  - Blocks commits to protected branches (`main`, `v*.*.*`)

- **`merge`**: Merge current branch to its parent branch.
  - Usage: `merge`
  - Use after PR approval
  - Validates PR, status checks, and permissions

- **`rmbranch`**: Delete branches locally and/or remotely.
  - Usage: `rmbranch fix/old-fix`
  - Add `-f` to force delete unmerged commits

- **`undo`**: Undo recent commit, merge, or release operations.
  - Usage: `undo commit` or `undo merge` or `undo release`
  - Soft resets to preserve changes

- **`chtarget`**: Rebase current branch onto a different parent.
  - Usage: `chtarget v1.2.3`
  - Use when changing version target
  - Add `-d` for dry-run preview

- **`mkrelease`**: Create and publish releases with git tags.
  - Usage: `mkrelease v1.0.0`
  - Creates annotated tag and GitHub release
  - Only on `main` branch

### Document and Brand Management

- **`ckstyle`**: Check style guidelines for documentation, code, scripts, etc.
- **`gendocs`**: Generate PDF and DOCX documentation.
- **`genpngs`**: Generate branding PNG images from SVG files.
- **`replacephrases`**: Apply configured phrase replacements in markdown files.
- **`updatebrand`**: Update branding text and regenerate related assets.

### Repository and Fork Management

- **`mkfork`**: Create a fork and optionally configure with upstream remote.

### Additional Scripts

- **`ckbranch_history`**: Query branch history log entries.
- **`lsbranch`**: List branches and their status.
- **`copyfix`**: Cherry-pick/copy fix commits from another branch.
- **`mkfeedback`**: View/respond to PR feedback workflows.
- **`mkpullrequest`**: Create or update a pull request.
- **`synceremote`**: Fetch and pull latest changes.
- **`syncparent`**: Merge parent branch into current branch.
- **`testscripts`**: Run tests and documentation checks.

---

## Git Hooks Integration

**All scripts work seamlessly with Git hooks that enforce script-only workflow.**

Hooks prevent direct use of:
- ❌ `git add` / `git commit` → Use `commit` script
- ❌ `git push` → Use `commit -p`
- ❌ `git merge` → Use `merge` script
- ❌ `git branch -d` → Use `rmbranch` script
- ❌ `git rebase` → Use `chtarget` script
- ❌ `git tag` → Use `mkrelease` script

Hooks auto-install on first clone and provide clear error messages.

**For details:** See [`docs/GIT_HOOKS_WORKFLOW.md`](../../docs/GIT_HOOKS_WORKFLOW.md)

---

## Getting Started

### Step 1: Clone with `mkclone` (from anywhere)

```bash
# Run from ANY directory on your local machine
mkclone
cd BriteTest
```

This automatically:
- Clones the repository
- Installs all scripts
- Installs Git hooks
- Makes scripts available

### Step 2: Verify Setup

```bash
# Check hooks installed
ls -la .git/hooks/ | grep -E 'orchestrator|pre-commit|pre-push'

# Try a script
commit -h
```

### Step 3: Start Working

```bash
# Create a branch (only fix/ or dev/ allowed)
mkbranch fix/my-fix main

# Make changes and commit
commit -m "Fix bug"

# Push when ready
commit -p
```

---

## Script Usage

For any script's detailed help:

```bash
<script-name> -h
```

Examples:
```bash
commit -h
merge -h
mkbranch -h
rmbranch -h
undo -h
chtarget -h
mkrelease -h
```

---

## Common Workflow

```bash
# Setup (once per clone, from anywhere)
mkclone
cd BriteTest

# Create fix branch
mkbranch fix/feature-name main

# Make changes
echo "code" > file.js

# Commit
commit -m "Add feature"

# Push
commit -p

# Create PR on GitHub (or use mkpullrequest script)

# After approval, merge
merge

# Delete old branch
rmbranch fix/feature-name
```

---

## Troubleshooting

### Scripts not executable

Re-run setup:
```bash
bash scripts/bin/installscripts
```

### Scripts not in PATH

Reload shell configuration:
```bash
source ~/.bashrc
```

### Git command blocked

Error message tells you which script to use. Read it carefully!

Examples:
- "Use 'commit' script" → Run `commit -m "message"`
- "Use 'commit -p'" → Run `commit -m "message" -p`
- "Use 'merge' script" → Run `merge`

### Hooks not installed

Re-install hooks:
```bash
bash scripts/helpers/install-git-hooks.sh
```

---

## Documentation

- **First Setup:** [`docs/SETUP_FIRST_CLONE.md`](../../docs/SETUP_FIRST_CLONE.md)
- **Workflows:** [`docs/GIT_HOOKS_WORKFLOW.md`](../../docs/GIT_HOOKS_WORKFLOW.md)
- **Contributing:** [`docs/md/Contributor_Guide.md`](../../docs/md/Contributor_Guide.md)
- **Hook Details:** [`scripts/helpers/.githooks/README.md`](../helpers/.githooks/README.md)

---

## README Directory Guide

- **README.md**: This directory guide.

## Subdirectories

- None.
