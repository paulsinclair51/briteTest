# `<repo>/scripts/helpers/`

Directory containing helper modules and Git hooks used by scripts in `scripts/bin/`.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

---

## Files

### Core Helpers

- **`common.sh`**: Shared output and branch-detection helpers.
  - `bt_info()` - Print info message
  - `bt_success()` - Print success message
  - `bt_error_exit()` - Print error and exit
  - `bt_get_current_branch()` - Get current branch name
  - `ensure_hooks_installed()` - Verify/install Git hooks

- **`git_helpers.sh`**: Shared branch lookup and resolution helpers.
  - Branch validation functions
  - Parent branch detection
  - Protected branch checks

- **`github_helpers.sh`**: Shared GitHub CLI pull-request lookup helpers.
  - PR lookup and status functions
  - Status check validation
  - Approver verification

### Documentation Generation

- **`genpdf.sh`**: Generate PDF files from Markdown sources.
- **`gendocx.sh`**: Generate DOCX files from PDF sources.

### Utility Helpers

- **`history_log.sh`**: Shared branch-history markdown logging helpers.
  - Log merge operations
  - Track branch modifications

- Text replacement logic is implemented directly in `scripts/bin/replacetext`.

### Git Hooks

**`.githooks/` subdirectory contains all Git hook files:**

- **`orchestrator.sh`**: Master enforcement logic.
  - Checks `BRITETEST_BYPASS_HOOKS` environment variable
  - Blocks operations if bypass not set
  - Provides helpful error messages

- **`pre-commit`**: Wrapper for orchestrator.
  - Blocks `git add`, `git commit`, `git rm`
  - Error message directs to `commit` script

- **`pre-push`**: Wrapper for orchestrator.
  - Blocks `git push` and all variants
  - Error message directs to `commit -p`

- **`pre-merge-commit`**: Wrapper for orchestrator.
  - Blocks `git merge` operations
  - Error message directs to `merge` script

- **`post-checkout`**: Auto-verification hook.
  - Checks if hooks are installed after checkout
  - Auto-reinstalls if missing
  - Acts as safety net

- **`.githooks/README.md`**: Detailed hook documentation.
  - How hooks work
  - Bypass mechanism explanation
  - Installation instructions
  - Troubleshooting guide

### Installation

- **`install-git-hooks.sh`**: Hook installer script.
  - Copies hooks from `.githooks/` to `.git/hooks/`
  - Makes hooks executable
  - Idempotent (safe to run multiple times)
  - Called automatically by `setupclone` and `mkclone`

### Directory Guide

- **`README.md`**: This file.

---

## Subdirectories

- **`.githooks/`**: Git hook files (see above).

---

## How Git Hooks Work

Git hooks enforce script-only workflow by preventing direct use of dangerous git commands:

### Hook Points

| Hook | When | Blocks |
|------|------|--------|
| `pre-commit` | Before commit | `git add`, `git commit`, `git rm` |
| `pre-push` | Before push | `git push` (all variants) |
| `pre-merge-commit` | Before merge | `git merge` (all variants) |
| `post-checkout` | After checkout | Verifies hooks installed |

### Bypass Mechanism

Hooks check for `BRITETEST_BYPASS_HOOKS=true` environment variable:

```bash
# Direct command (blocked by hook):
git push origin branch        # ❌ ERROR

# Script command (allowed):
commit -p                     # ✅ OK (sets bypass internally)
```

Scripts set bypass before git operations and immediately unset after:

```bash
export BRITETEST_BYPASS_HOOKS=true
git push origin branch
unset BRITETEST_BYPASS_HOOKS
```

### Error Messages

When hooks block operations, they provide clear error messages:

```
Error: Direct git commit/add operations are not allowed in briteTest.

Use the 'commit' script instead:
  commit -m "your message"

For more information, see docs/GIT_HOOKS_WORKFLOW.md
```

---

## Installation

### Automatic (Recommended)

Hooks install automatically when you:

1. **Clone with `mkclone`:**
   ```bash
   mkclone
   ```

2. **Run `setupclone`:**
   ```bash
   bash scripts/bin/setupclone
   ```

### Manual Installation

```bash
bash scripts/helpers/install-git-hooks.sh
```

### Verify Installation

```bash
ls -la .git/hooks/
# Should show: orchestrator.sh, pre-commit, pre-push, pre-merge-commit, post-checkout
```

---

## Using Helpers in Scripts

### Import Helpers

```bash
#!/usr/bin/env bash

# Source helpers
source "$SCRIPT_DIR/../helpers/common.sh"
source "$SCRIPT_DIR/../helpers/git_helpers.sh"

# Now use helper functions
ensure_hooks_installed
CURRENT_BRANCH=$(bt_get_current_branch)
```

### Common Functions

```bash
# Messaging
bt_info "Status message"
bt_success "Success message"
bt_warn "Warning message"
bt_error_exit 1 "Error message"

# Branch operations
CURRENT=$(bt_get_current_branch)
PARENT=$(bt_get_parent_branch "$BRANCH")
if bt_is_protected_branch "$BRANCH"; then
  echo "Protected branch"
fi

# Hook verification
ensure_hooks_installed
```

---

## For Script Developers

### Pattern for Restricted Git Operations

```bash
# Before any restricted git operation:
export BRITETEST_BYPASS_HOOKS=true

# Execute git command
if ! git <operation>; then
  unset BRITETEST_BYPASS_HOOKS
  bt_error_exit 1 "Operation failed"
fi

# IMMEDIATELY unset after
unset BRITETEST_BYPASS_HOOKS
```

### Restricted Operations That Need Bypass

- `git add`
- `git commit`
- `git push`
- `git merge`
- `git branch -d` / `-D`
- `git rebase`
- `git tag`
- `git reset`
- `git cherry-pick`

---

## Documentation

- **Setup Guide:** [`docs/SETUP_FIRST_CLONE.md`](../../docs/SETUP_FIRST_CLONE.md)
- **Workflow Guide:** [`docs/GIT_HOOKS_WORKFLOW.md`](../../docs/GIT_HOOKS_WORKFLOW.md)
- **Contributing:** [`docs/md/Contributor_Guide.md`](../../docs/md/Contributor_Guide.md)
- **Hook Details:** [`.githooks/README.md`](./.githooks/README.md)
- **Implementation Plan:** [`docs/IMPLEMENTATION_PLAN_GIT_HOOKS.md`](../../docs/IMPLEMENTATION_PLAN_GIT_HOOKS.md)
