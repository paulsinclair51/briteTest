# `<repo>/briteRepo/helpers/.githooks/`

Directory containing git hook scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

Git requires hook entrypoints to use the canonical hook names (for example
`pre-commit` and `pre-push`), so those files intentionally do not use a
`.sh` suffix. Shared hook logic lives in `githook_helper.sh`.

See `<repo>/README.md` for an introduction to the repository.

## Files

**githook_helper.sh**: Master enforcement logic.
- Checks `GIT_BYPASS_HOOKS` environment variable.
- Blocks operations if bypass not set.
- Provides helpful error messages.

**post-checkout**: Auto-verification hook entrypoint.
- Checks if hooks are installed after checkout.
- Auto-reinstalls if missing.
- Acts as safety net.

**pre-commit**: Wrapper for orchestrator.
- Blocks `git add`, `git commit`, `git rm`.
- Error message directs to `commit` script.

**pre-merge-commit**: Wrapper for orchestrator.
- Blocks `git merge` operations.
- Error message directs to `merge` script.

**pre-push**: Wrapper for orchestrator.
- Blocks `git push` and all variants.
- Error message directs to `commit -p`.

**README.md**: This directory guide.

## Subdirectories

None.

## Installation

**install_git_hooks.sh**: Hook installer script.
- Copies hooks from `.githooks/` to `.git/hooks/`.
- Makes hooks executable.
- Idempotent (safe to run multiple times).
- Called automatically by `setupclone` and `mkclone`.

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

Hooks check for `GIT_BYPASS_HOOKS=true` environment variable:

```bash
# Direct command (blocked by hook):
git push origin branch        # ❌ ERROR

# Script command (allowed):
commit -p                     # ✅ OK (sets bypass internally)
```

Scripts set bypass before git operations and immediately unset after:

```bash
export GIT_BYPASS_HOOKS=true
git push origin branch
unset GIT_BYPASS_HOOKS
```

### Error Messages

When hooks block operations, they provide clear error messages:

```
Error: Direct git commit/add operations are not allowed.

Use the 'commit' script instead:
  commit -m "your message"

For more information, see docs/GIT_HOOKS_WORKFLOW.md
```

## Installation

### Automatic (Recommended)

Hooks install automatically when you:

1. **Clone with `mkclone`:**
   ```bash
   mkclone
   ```

2. **Run `setupclone`:**
   ```bash
   bash briteRepo/bin/setupclone
   ```

### Manual Installation

```bash
bash briteRepo/helpers/install_git_hooks.sh
```

### Verify Installation

```bash
ls -la .git/hooks/
# Should show: githook_helper.sh, pre-commit, pre-push, pre-merge-commit, post-checkout
```

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

## For Script Developers

### Pattern for Restricted Git Operations

```bash
# Before any restricted git operation:
export GIT_BYPASS_HOOKS=true

# Execute git command
if ! git <operation>; then
  unset GIT_BYPASS_HOOKS
  bt_error_exit 1 "Operation failed"
fi

# IMMEDIATELY unset after
unset GIT_BYPASS_HOOKS
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

## Documentation

- **Contributing:** [`docs/md/Contributor_Guide.md`](../../docs/md/Contributor_Guide.md)
