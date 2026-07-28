# Git Hook Security Implementation Plan

## Overview
Implement automatic Git hook installation and enforcement to prevent contributors from using direct Git commands that modify repository state. All branch modifications must go through provided scripts.

---

## Phase 1: Hook Infrastructure (Foundation)

### Files Already Created ✅
1. `scripts/helpers/install-git-hooks.sh` - Hook installer
2. `scripts/helpers/.githooks/orchestrator.sh` - Master enforcement logic
3. `scripts/helpers/.githooks/pre-commit` - Wrapper for orchestrator
4. `scripts/helpers/.githooks/pre-push` - Wrapper for orchestrator
5. `scripts/helpers/.githooks/pre-merge-commit` - Wrapper for orchestrator
6. `scripts/helpers/.githooks/post-checkout` - Auto-verification hook
7. `scripts/helpers/.githooks/README.md` - Hook documentation
8. `scripts/helpers/common.sh` - Updated with `ensure_hooks_installed()` function
9. `scripts/bin/installscripts` - Updated to call hook installer

---

## Phase 2: Script Modifications (Bypass Mechanism)

### Files To Modify

#### 1. `scripts/bin/mkclone`
**Changes needed:**
- After successful clone (line ~165), call `installscripts`
- Add lines before `exit 0`:
```bash
# Install scripts and Git hooks
bt_info "Installing scripts and Git hooks..."
if bash "$TARGET_DIR/scripts/bin/installscripts" >/dev/null 2>&1; then
  bt_success "Scripts and Git hooks installed"
else
  bt_warn "Failed to install scripts and Git hooks"
  bt_info "Run manually: cd $TARGET_DIR && bash scripts/bin/installscripts"
fi
```

#### 2. `scripts/bin/commit`
**Changes needed:**
- Add hook verification at startup (after sourcing helpers, line ~137):
```bash
# Ensure Git hooks are installed
ensure_hooks_installed
```
- Before `git add` operations (lines ~795-815), set bypass:
```bash
export BRITETEST_BYPASS_HOOKS=true
if ! git add "${FILES[@]}" >/dev/null 2>&1; then
  unset BRITETEST_BYPASS_HOOKS
  bt_error_exit 6 "Failed to stage files: ${FILES[*]}"
fi
unset BRITETEST_BYPASS_HOOKS
```
- Before `git commit` (lines ~825-832), set bypass:
```bash
export BRITETEST_BYPASS_HOOKS=true
if ! git commit -m "$COMMIT_MESSAGE" >/dev/null 2>&1; then
  unset BRITETEST_BYPASS_HOOKS
  bt_error_exit 6 "Failed to create commit"
fi
unset BRITETEST_BYPASS_HOOKS
```
- Before `git push` (lines ~945-952), set bypass:
```bash
export BRITETEST_BYPASS_HOOKS=true
if ! git push origin "$CURRENT_BRANCH" >/dev/null 2>&1; then
  unset BRITETEST_BYPASS_HOOKS
  bt_error_exit 7 "Failed to push to remote"
fi
unset BRITETEST_BYPASS_HOOKS
```

#### 3. `scripts/bin/merge`
**Changes needed:**
- Add hook verification at startup
- Before `git checkout` commands, set/unset bypass as needed
- Before `git merge --squash` (line ~269), set bypass
- Before `git commit` (after merge), set bypass
- Before final `git push` (line ~291), set bypass
- Pattern: `export BRITETEST_BYPASS_HOOKS=true` before, `unset BRITETEST_BYPASS_HOOKS` after

#### 4. `scripts/bin/rmbranch`
**Changes needed:**
- Add hook verification at startup
- Before `git branch -d` or `-D` operations, set bypass
- Before `git push origin --delete`, set bypass
- Unset after each operation

#### 5. `scripts/bin/undo`
**Changes needed:**
- Add hook verification at startup
- Before `git reset --soft` (line ~183), set bypass
- Before `git revert -m 1` (line ~227), set bypass
- Before `git tag -d` (line ~256), set bypass
- Before `git push origin --delete` (line ~262), set bypass

#### 6. `scripts/bin/retarget`
**Changes needed:**
- Add hook verification at startup
- Before `git rebase` (line ~241), set bypass
- Before `git push --force-with-lease` (line ~259), set bypass

#### 7. `scripts/bin/copyfix`
**Changes needed:**
- Add hook verification at startup
- Before `git cherry-pick` operations, set bypass
- Unset after operation

#### 8. `scripts/bin/release`
**Changes needed:**
- Add hook verification at startup
- Before `git tag` operations, set bypass
- Before `git push origin` for tags, set bypass
- Unset after operations

#### 9. `scripts/bin/mkbranch`
**Changes needed:**
- Add hook verification at startup
- Before `git push` for remote branch creation (line ~unknown), set bypass
- Unset after operation

---

## Phase 3: Documentation

### New/Updated Documentation Files

#### 1. Create `docs/SETUP_FIRST_CLONE.md`
**Content should include:**
- Required: Use `mkclone` instead of `git clone`
- Explains why hooks are needed
- Shows: `mkclone` automatically installs everything
- Step-by-step first clone instructions
- Troubleshooting section

#### 2. Create `docs/GIT_HOOKS_WORKFLOW.md`
**Content should include:**
- Hook enforcement model overview
- Table of blocked commands and required scripts
- `BRITETEST_BYPASS_HOOKS` bypass mechanism explanation
- Error messages and what they mean
- How to use scripts correctly
- Troubleshooting: missing hooks, re-installation, etc.
- For script developers: how to use bypass variable

#### 3. Update `docs/md/Contributor_Guide.md`
**Changes needed:**
- Add "Getting Started: First Clone" section at beginning
- Reference: "Use `mkclone` to clone (required for hook setup)"
- Link to `docs/SETUP_FIRST_CLONE.md`
- Update any direct `git clone` instructions

#### 4. Update `scripts/bin/README.md`
**Changes needed:**
- Update `mkclone` description: "Clone the repository WITH automatic hook installation (required entry point)"
- Add note: "All contributors must use `mkclone` instead of `git clone`"

#### 5. Update `scripts/helpers/README.md`
**Changes needed:**
- Add `.githooks/` directory documentation
- Explain hook installation process
- Link to `docs/GIT_HOOKS_WORKFLOW.md`

---

## Phase 4: Testing Checklist

### Validation Steps
- [ ] Fresh clone using `mkclone` - verify hooks install automatically
- [ ] Try `git push` directly - verify blocked with helpful error message
- [ ] Run `commit -p` - verify push succeeds (bypass works)
- [ ] Try `git commit` directly - verify blocked
- [ ] Run `commit -m "test"` - verify succeeds
- [ ] Try `git merge` directly - verify blocked
- [ ] Try `git rebase` directly - verify blocked
- [ ] Try `git tag` directly - verify blocked
- [ ] Try `git branch -d` directly - verify blocked
- [ ] Verify all scripts work with bypass mechanism
- [ ] Test `ensure_hooks_installed()` detects missing hooks
- [ ] Verify bypass variable is unset after each operation

---

## Implementation Strategy

### Recommended Order:
1. **Verify Phase 1 files exist** (already created)
2. **Implement Phase 2** - Modify scripts one at a time, test each
3. **Create Phase 3 docs** - Document the workflow
4. **Run Phase 4 tests** - Validate everything works
5. **Commit all changes** - Single commit or staged commits

### Git Commands for Implementation:
```bash
# After completing modifications, commit:
git add scripts/bin/* scripts/helpers/* docs/*
git commit -m "feat: Implement Git hook security for script-only workflow

- Add comprehensive Git hook enforcement
- Block all direct git commands that modify state
- Implement BRITETEST_BYPASS_HOOKS bypass mechanism
- Auto-install hooks on first clone via mkclone
- Update all scripts to use bypass mechanism
- Document workflow and setup process"
```

---

## Key Implementation Details

### Bypass Pattern (Use in all scripts)
```bash
# Before restricted git operation
export BRITETEST_BYPASS_HOOKS=true
git <operation>
RESULT=$?
unset BRITETEST_BYPASS_HOOKS

# Check result
if [[ $RESULT -ne 0 ]]; then
  bt_error_exit <code> "Failed to perform operation"
fi
```

### Hook Verification Pattern (Add to all scripts)
```bash
# After sourcing helpers (line ~137 pattern)
ensure_hooks_installed
```

### Error Messages (From orchestrator.sh)
- pre-commit → Use `commit` script
- pre-push → Use `commit -p`
- pre-merge-commit → Use `merge` script
- post-rewrite → Use `retarget` or `copyfix`

---

## Files Already Completed
✅ Scripts/helpers/install-git-hooks.sh
✅ Scripts/helpers/.githooks/orchestrator.sh
✅ Scripts/helpers/.githooks/pre-commit
✅ Scripts/helpers/.githooks/pre-push
✅ Scripts/helpers/.githooks/pre-merge-commit
✅ Scripts/helpers/.githooks/post-checkout
✅ Scripts/helpers/.githooks/README.md
✅ Scripts/helpers/common.sh (with ensure_hooks_installed)
✅ Scripts/bin/installscripts (with hook installation)

---

## Files Requiring Modifications
- [ ] scripts/bin/mkclone
- [ ] scripts/bin/commit
- [ ] scripts/bin/merge
- [ ] scripts/bin/rmbranch
- [ ] scripts/bin/undo
- [ ] scripts/bin/retarget
- [ ] scripts/bin/copyfix
- [ ] scripts/bin/release
- [ ] scripts/bin/mkbranch

## Files Requiring Creation
- [ ] docs/SETUP_FIRST_CLONE.md
- [ ] docs/GIT_HOOKS_WORKFLOW.md

## Files Requiring Updates
- [ ] docs/md/Contributor_Guide.md
- [ ] scripts/bin/README.md
- [ ] scripts/helpers/README.md

---

## Next Steps

1. Copy this file and save it locally or in your repo
2. In next session, use this plan as reference
3. Implement Phase 2 modifications one script at a time
4. Create Phase 3 documentation
5. Run Phase 4 tests
6. Commit completed work

---

**Created:** 2026-07-13
**Status:** Foundation complete (Phase 1), Ready for Phase 2
**Last Updated:** Implementation plan documented
