# Getting Started: First Clone with briteTest

## Why Use `mkclone`?

briteTest uses Git hooks to protect the repository from accidental (or intentional) misuse of direct Git commands. These hooks enforce a **script-only workflow** where all branch modifications must go through provided scripts.

**Using `mkclone` is the ONLY way to set up a new clone** because it:

1. ✅ Clones the repository
2. ✅ Automatically installs Git hooks
3. ✅ Makes all scripts executable
4. ✅ Adds scripts to your PATH
5. ✅ Sets up everything in one step (no manual work needed)

---

## First Clone Setup

### Step 1: Clone the Repository

Instead of `git clone`, use the `mkclone` script from anywhere:

```bash
# Create clone with default directory name (BriteTest/)
mkclone

# Or specify a custom directory name
mkclone my-britetest-workspace
```

**What happens:**
- Repository clones to the specified directory
- Scripts are installed and made executable
- Git hooks are automatically installed to `.git/hooks/`
- PATH is updated to include scripts

### Step 2: Enter the Repository

```bash
cd BriteTest
```

### Step 3: Verify Setup

Verify hooks are installed:

```bash
ls -la .git/hooks/ | grep -E 'pre-commit|pre-push|pre-merge-commit|orchestrator'
```

You should see:
```
orchestrator.sh
pre-commit
pre-push
pre-merge-commit
post-checkout
```

---

## Common First Tasks

### Create Your First Branch

```bash
# Create a new patch branch from main
mkbranch patch/my-first-fix main

# Switch to it (git checkout also works)
git checkout patch/my-first-fix
```

### Make Changes and Commit

```bash
# Edit files...

# Commit using the commit script (NOT git commit)
commit -m "My first change"

# Or commit and push together
commit -m "My first change" -p
```

### Merge Your Changes

```bash
# Switch back to your branch
git checkout patch/my-first-fix

# Create a PR first (via GitHub UI)

# Once PR is approved, merge using merge script
merge
```

---

## Troubleshooting

### Hooks Not Installed After Clone

If hooks didn't install (rare), manually install them:

```bash
bash scripts/bin/setupclone
```

### "Direct git push operations are not allowed"

You tried to run `git push` directly. Instead, use:

```bash
# Commit and push together
commit -m "Your message" -p
```

### "Direct git commit/add operations are not allowed"

You tried to run `git commit` or `git add` directly. Instead, use:

```bash
# Use the commit script
commit -m "Your message"
```

### "Direct git merge operations are not allowed"

You tried to run `git merge` directly. Instead, use:

```bash
# Use the merge script
merge
```

### "Current branch is protected"

You tried to commit directly to `main` or a version branch. Instead:

1. Create a new branch
2. Make your changes there
3. Create a PR
4. Use `merge` to merge after approval

### I Need to Update Hooks

If hooks are updated in the repo, reinstall them:

```bash
bash scripts/bin/setupclone
```

The `post-checkout` hook will auto-verify and reinstall if needed.

---

## Available Scripts

After `mkclone` and `setupclone`, these commands are available:

| Script | Purpose | Example |
|--------|---------|----------|
| `mkclone` | Clone repository with setup | `mkclone` |
| `mkbranch` | Create new branch | `mkbranch patch/my-fix main` |
| `commit` | Commit changes | `commit -m "Fix bug"` |
| `merge` | Merge to parent branch | `merge` |
| `rmbranch` | Delete branch | `rmbranch patch/old-fix` |
| `undo` | Undo commit/merge/release | `undo commit` |
| `retarget` | Rebase to new parent | `retarget v1.2.3` |
| `release` | Create release | `release v1.0.0` |

**For detailed help on any script:**
```bash
<script-name> -h
# Example:
commit -h
```

---

## Next Steps

1. ✅ Clone with `mkclone`
2. ✅ Verify hooks installed
3. Read `docs/GIT_HOOKS_WORKFLOW.md` for detailed workflow
4. Read `docs/md/Contributor_Guide.md` for contribution guidelines
5. Start creating branches and making changes!

---

## Questions?

If something isn't working:

1. Check the error message carefully (they tell you which script to use)
2. Run `<script> -h` to see usage
3. See the troubleshooting section above
4. Check `docs/GIT_HOOKS_WORKFLOW.md` for detailed explanations

**Happy coding! 🚀**
