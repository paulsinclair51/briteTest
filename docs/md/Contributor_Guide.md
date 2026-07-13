# Contributor Guide

Welcome to briteTest! This guide explains how to contribute to the project.

---

## Getting Started: First Clone

**⚠️ IMPORTANT: Use `mkclone` to clone the repository**

Do NOT use `git clone`. Instead:

```bash
mkclone
```

This automatically:
- ✅ Clones the repository
- ✅ Installs Git hooks
- ✅ Makes scripts executable
- ✅ Sets up everything needed

**For detailed setup instructions, see:** [`docs/SETUP_FIRST_CLONE.md`](../SETUP_FIRST_CLONE.md)

---

## Workflow Overview

### 1. Create Your Branch

```bash
mkbranch patch/your-fix main
```

Branch naming conventions:
- `patch/description-v1.0.0` - Bug fix or patch
- `feature/description-v1.0.0` - New feature
- `dev/description-v1.0.0` - Development/experimental
- `fix/description-v1.0.0` - Quick fix

### 2. Make Your Changes

Edit files, add new code, etc.

### 3. Commit Your Changes

Use the `commit` script (NOT `git commit`):

```bash
# Commit all changes
commit -m "Your commit message"

# Commit specific files
commit file1.js file2.js -m "Your message"

# Commit and push immediately
commit -m "Your message" -p
```

### 4. Create a Pull Request

On GitHub, create a PR from your branch to `main`.

### 5. Address Review Feedback

Make any requested changes and commit them:

```bash
commit -m "Address review feedback"
commit -p  # Push when ready
```

### 6. Merge Your Changes

Once approved, use the `merge` script:

```bash
merge
```

DO NOT use `git merge` directly.

---

## Important: Script-Only Workflow

All branch modifications go through scripts:

| Operation | Script | Command |
|-----------|--------|----------|
| Clone | `mkclone` | `mkclone` |
| Create branch | `mkbranch` | `mkbranch branch-name parent` |
| Commit | `commit` | `commit -m "message"` |
| Push | `commit` | `commit -m "message" -p` |
| Merge | `merge` | `merge` |
| Delete branch | `rmbranch` | `rmbranch branch-name` |
| Undo commit | `undo` | `undo commit` |
| Rebase | `chtarget` | `chtarget new-parent` |
| Release | `mkrelease` | `mkrelease v1.0.0` |

**Direct `git` commands that modify state are blocked by Git hooks.**

If you see an error like:
```
Error: Direct git push operations are not allowed in briteTest.
Use the 'commit' script with -p flag to push changes:
  commit -m "your message" -p
```

This means you tried to use `git push` directly. Use the indicated script instead.

---

## Git Hooks Protection

briteTest uses Git hooks to prevent accidental misuse. These hooks:

✅ Enforce script-only workflow  
✅ Block direct `git add`, `git commit`, `git push`, `git merge`, etc.  
✅ Auto-install on first clone  
✅ Provide clear error messages  
✅ Audit all changes  

**For detailed information:** See [`docs/GIT_HOOKS_WORKFLOW.md`](../GIT_HOOKS_WORKFLOW.md)

---

## Before You Commit

### Code Quality

- Follow the coding style of the existing codebase
- Test your changes locally
- Run existing tests if applicable
- Write clear commit messages

### Commit Messages

Write clear, descriptive commit messages:

```bash
# Good:
commit -m "Fix authentication bug in login module"
commit -m "Add documentation for setup process"

# Avoid:
commit -m "fix stuff"
commit -m "update"
```

### Files to Change

Common areas for contributions:

- `scripts/bin/` - Workflow scripts
- `docs/` - Documentation
- `src/` - Source code
- Tests and test utilities

---

## Branch Protection

These branches are protected:

- `main` - Production branch
- `v*.*.* ` - Version branches (e.g., `v1.0.0`)

You cannot commit directly to protected branches. Instead:

1. Create a new branch from a protected branch
2. Make your changes
3. Create a PR
4. Get approval from maintainers
5. Use `merge` script to merge

---

## Common Tasks

### Delete a Branch

```bash
# Delete locally and remotely
rmbranch patch/old-fix

# Delete only locally
rmbranch patch/old-fix -l

# Force delete (if unmerged)
rmbranch patch/old-fix -f
```

### Undo a Commit

```bash
# Undo last commit (changes preserved)
undo commit

# Undo last merge
undo merge
```

### Rebase Branch

```bash
# Rebase current branch onto new parent
chtarget v1.2.3

# Preview rebase without making changes
chtarget v1.2.3 -d
```

### View All Available Scripts

After `mkclone`:

```bash
ls scripts/bin/

# Get help on any script:
<script-name> -h
```

---

## Troubleshooting

### "Can't use direct git commands"

This is intentional! Use scripts instead. Error messages tell you which script to use.

### "Hooks not installed"

Re-install hooks:

```bash
bash scripts/helpers/install-git-hooks.sh
```

### "Not an approver - cannot merge to protected branch"

You need approval from a project maintainer before merging to protected branches. Ask in the PR.

### Need Help?

1. Read the error message (it's helpful!)
2. Run `script-name -h` for script help
3. Check `docs/GIT_HOOKS_WORKFLOW.md` for workflow details
4. Check `docs/SETUP_FIRST_CLONE.md` for setup help

---

## Code Review

When your PR is ready:

1. **Request Review** - Ask maintainers to review on GitHub
2. **Address Feedback** - Make requested changes and commit
3. **Get Approval** - Wait for approval from maintainers
4. **Merge** - Run `merge` script to merge your changes

---

## Releases

Only maintainers can create releases:

```bash
mkrelease v1.0.0
```

This:
- Creates an annotated git tag
- Pushes the tag to remote
- Creates a GitHub release

---

## Questions?

- **Setup problems?** See `docs/SETUP_FIRST_CLONE.md`
- **Workflow questions?** See `docs/GIT_HOOKS_WORKFLOW.md`
- **Script help?** Run `script-name -h`
- **Git hooks?** See `scripts/helpers/.githooks/README.md`

**Happy contributing! 🚀**
