# Git Hooks Workflow Guide

This document explains how Git hooks protect the briteTest repository and how to work within the script-only workflow.

---

## Overview

briteTest uses Git hooks to enforce a **script-only workflow**. This means:

✅ All branch modifications must go through provided scripts  
❌ Direct `git` commands that modify state are blocked  
🛡️ Accidental (or intentional) misuse is prevented  
📝 All changes are audited and logged  

---

## How Git Hooks Work

Git hooks are scripts that run automatically at specific points in the Git workflow:

### Hook Points

| Hook | Triggers | Blocks |
|------|----------|--------|
| `pre-commit` | Before `git commit` | `git add`, `git commit`, `git rm` |
| `pre-push` | Before `git push` | `git push` (all variants) |
| `pre-merge-commit` | Before merge commit | `git merge` (all variants) |
| `post-checkout` | After checkout | Auto-verifies other hooks |

### Hook Protection

Each hook checks for the `BRITETEST_BYPASS_HOOKS` environment variable:

```bash
# Direct use (blocked by hook):
git push origin branch        # ❌ ERROR: blocked by pre-push hook

# Script use (allowed via bypass):
commit -p                     # ✅ OK: script sets BRITETEST_BYPASS_HOOKS=true
```

---

## Blocked Commands vs. Required Scripts

### Commit Operations

| Blocked | Use Script | Example |
|---------|------------|---------|
| `git add` | `commit` | `commit -m "message"` |
| `git commit` | `commit` | `commit -m "message"` |
| `git rm` | `commit` | (file deletion via commit) |

```bash
# ❌ These will be blocked:
git add file.js
git commit -m "My change"
git rm old-file.js

# ✅ Use this instead:
commit -m "My change"
```

### Push Operations

| Blocked | Use Script | Example |
|---------|------------|---------|
| `git push` | `commit -p` | `commit -m "msg" -p` |
| `git push --force` | `commit -p` | (merge handles it) |
| `git push origin --delete` | `rmbranch` | `rmbranch my-branch -r` |

```bash
# ❌ These will be blocked:
git push origin my-branch
git push --force-with-lease

# ✅ Use this instead:
commit -m "My change" -p
```

### Branch Operations

| Blocked | Use Script | Example |
|---------|------------|---------|
| `git branch -d` | `rmbranch` | `rmbranch my-branch -l` |
| `git branch -D` | `rmbranch` | `rmbranch my-branch -l -f` |
| `git branch -m` | Not yet | (blocked for safety) |

```bash
# ❌ These will be blocked:
git branch -d old-branch
git branch -D feature

# ✅ Use this instead:
rmbranch old-branch
rmbranch feature -f
```

### Merge/Rebase Operations

| Blocked | Use Script | Example |
|---------|------------|---------|
| `git merge` | `merge` | `merge` (merge current) |
| `git rebase` | `chtarget` | `chtarget v1.2.3` |
| `git cherry-pick` | Future | (planned) |

```bash
# ❌ These will be blocked:
git merge feature-branch
git rebase origin/main

# ✅ Use this instead:
merge                        # Merges current branch to parent
chtarget v1.2.3             # Rebases current onto v1.2.3
```

### Tag Operations

| Blocked | Use Script | Example |
|---------|------------|---------|
| `git tag` (create) | `mkrelease` | `mkrelease v1.0.0` |
| `git tag -d` | `undo` | `undo release` |

```bash
# ❌ These will be blocked:
git tag v1.0.0
git tag -d v0.9.9

# ✅ Use this instead:
mkrelease v1.0.0
undo release
```

---

## Error Messages and Solutions

### "Direct git commit/add operations are not allowed"

**You tried:** `git add` or `git commit`

**Use instead:**
```bash
commit -m "Your commit message"

# With options:
commit -m "Message" -p              # Commit and push
commit -m "Message" -v              # Verbose output
commit file1.js file2.js -m "Msg"  # Specific files
```

### "Direct git push operations are not allowed"

**You tried:** `git push`

**Use instead:**
```bash
# Push via commit script
commit -m "Your message" -p

# Or if already committed:
commit -p  # -p flag alone pushes existing commits
```

### "Direct git merge operations are not allowed"

**You tried:** `git merge`

**Use instead:**
```bash
# Merge current branch to its parent:
merge

# With custom message:
merge -m "Custom merge message"

# Verbose:
merge -v
```

### "Cannot commit directly to protected branch"

**You tried:** Committing to `main` or version branch directly

**Solution:**
1. Create a new branch: `mkbranch patch/fix-name main`
2. Make your changes and commit
3. Create a PR on GitHub
4. Once approved, use `merge` to merge

### "Not an approver - cannot merge to protected branch"

**You tried:** Merging to a protected branch without approval rights

**Solution:**
1. Ask an approver to review your PR
2. Once they approve, they can run `merge`
3. Or, request approver status from maintainers

---

## Bypass Mechanism (For Script Developers)

### How Scripts Use Bypass

Scripts set `BRITETEST_BYPASS_HOOKS=true` before restricted operations:

```bash
# Pseudo-code pattern used in all scripts:
export BRITETEST_BYPASS_HOOKS=true

# Execute restricted git operation
git push origin branch
RESULT=$?

# IMMEDIATELY unset for safety
unset BRITETEST_BYPASS_HOOKS

# Check result
if [[ $RESULT -ne 0 ]]; then
  echo "Error: Git operation failed"
  exit 1
fi
```

### Why Unset Immediately?

The bypass variable is unset immediately after each operation to prevent accidental permission leakage. This ensures:

✅ Only the intended operation is allowed  
✅ No accidental cascade of allowed operations  
✅ Future operations respect hooks again  

### Creating New Scripts

When adding new scripts that need bypass:

```bash
#!/usr/bin/env bash

# Source helpers
source scripts/helpers/common.sh

# Verify hooks installed
ensure_hooks_installed

# ... script logic ...

# Before restricted git operation:
export BRITETEST_BYPASS_HOOKS=true
if ! git <operation>; then
  unset BRITETEST_BYPASS_HOOKS
  bt_error_exit 1 "Operation failed"
fi
unset BRITETEST_BYPASS_HOOKS
```

---

## Hook Installation

### Automatic Installation

Hooks install automatically in two ways:

1. **Via `mkclone` (recommended):**
   ```bash
   mkclone          # Clones repo and installs hooks
   ```

2. **Via `installscripts`:**
   ```bash
   bash scripts/bin/installscripts
   ```

### Manual Installation

```bash
bash scripts/helpers/install-git-hooks.sh
```

### Verify Installation

```bash
ls -la .git/hooks/

# Should show:
# orchestrator.sh
# pre-commit -> ../../../scripts/helpers/.githooks/pre-commit
# pre-push
# pre-merge-commit
# post-checkout
```

### Re-installation

If hooks go missing or need updating:

```bash
bash scripts/helpers/install-git-hooks.sh
```

This is idempotent (safe to run multiple times).

---

## Troubleshooting

### Hooks Stopped Working

**Symptoms:** Commands that should be blocked aren't blocked

**Solution:**
```bash
# Reinstall hooks
bash scripts/helpers/install-git-hooks.sh

# Verify installation
ls -la .git/hooks/ | grep orchestrator
```

### Hook Running But Wrong Error Message

**Symptoms:** Seeing generic error instead of helpful message

**Solution:**
1. Check `.git/hooks/orchestrator.sh` exists and is executable
2. Check hook wrapper exists: `.git/hooks/pre-commit`, etc.
3. Reinstall: `bash scripts/helpers/install-git-hooks.sh`

### Need to Temporarily Disable Hooks

**⚠️ NOT RECOMMENDED - development only:**

```bash
# Bypass for one operation (NEVER DO THIS in production)
BRITETEST_BYPASS_HOOKS=true git push origin branch

# IMMEDIATELY unset
unset BRITETEST_BYPASS_HOOKS
```

### Hooks in Subdirectory

If you clone the repo as a subdirectory, hooks apply to that specific clone:

```bash
mkclone my-workspace
cd my-workspace
# Hooks are in: ./my-workspace/.git/hooks/
```

---

## Hook Files

All hook files are version-controlled in `scripts/helpers/.githooks/`:

| File | Purpose |
|------|----------|
| `orchestrator.sh` | Master logic (checks bypass variable) |
| `pre-commit` | Wrapper that calls orchestrator |
| `pre-push` | Wrapper that calls orchestrator |
| `pre-merge-commit` | Wrapper that calls orchestrator |
| `post-checkout` | Auto-verifies hooks are installed |
| `README.md` | Hook documentation |

**These are symlinked or copied to `.git/hooks/` during installation.**

---

## Summary

### Remember:

✅ Use scripts for all branch modifications  
✅ Scripts handle Git hooks automatically  
✅ Hooks only block direct git commands  
✅ Run `script-name -h` for help  
✅ Error messages tell you which script to use  

### Scripts to Know:

```bash
mkclone           # Clone and setup
mkbranch          # Create branch
commit            # Commit and optionally push
merge             # Merge to parent
rmbranch          # Delete branch
undo              # Undo commit/merge/release
chtarget          # Rebase to new parent
mkrelease         # Create release
```

### Workflow:

```bash
mkclone                        # Setup
mkbranch patch/fix main       # Create branch
commit -m "Fix bug"           # Make changes
commit -p                      # Push when ready
merge                          # Merge after PR approval
```

---

## More Information

- **Getting Started:** See `docs/SETUP_FIRST_CLONE.md`
- **Contributing:** See `docs/md/Contributor_Guide.md`
- **Script Details:** Run `script-name -h` for any script
- **Hook Code:** See `scripts/helpers/.githooks/`

**Questions?** Check the error message - it tells you what to do! 🎯
