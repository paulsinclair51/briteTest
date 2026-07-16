# Contributor Reference

## Scripts and Tools Reference

#### Version: v1.0.0

Comprehensive reference for all scripts and helper tools used in briteTest development.

#### Copyright (c) 2026 Paul Sinclair

SPDX-License-Identifier: MIT

---

## Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-07-13 | Current v1.0.0 development reference; refreshed to match current `scripts/bin/` inventory and clone lifecycle scripts (`mkclone`/`rmclone`). | Paul Sinclair |
| v1.0.0 | 2026-07-14 | Added current `chbranch` and `commit` behavior details (dirty-worktree guard, commit auto-push, report naming). | Paul Sinclair |

---

## Table of Contents

1. [Helper Scripts](#helper-scripts)
2. [Binary Scripts](#binary-scripts)
3. [Script-Based Access Control](#script-based-access-control)
4. [Environment Variables](#environment-variables)
5. [Exit Codes](#exit-codes)
6. [Troubleshooting](#troubleshooting)

---

## Helper Scripts

Helper scripts located in `scripts/helpers/` are designed to be sourced or called by other scripts and workflows.

### ckbranchname.sh

**Purpose:** Validates branch names against repository naming conventions.

**Location:** `scripts/helpers/ckbranchname.sh`

**Usage:**

```bash
bash scripts/helpers/ckbranchname.sh "<branch_name>"
```

**Arguments:**

- `<branch_name>` - The branch name to validate

**Exit Codes:**

- `0` - Script execution succeeded (used with `echo $?`)
- `1` - Valid main branch name (remote-only branch base)
- `2` - Valid version branch (format: v<M>.<m>.0)
- `3` - Valid targeted branch (format: dev/<desc>-<version> or fix/<desc>-<version>)
- `4` - Valid contributor branch (format: [<type>/]<description>)
- `5` - Invalid branch name

**Examples:**

```bash
# Check main branch name
bash scripts/helpers/ckbranchname.sh "main"
# Exit code: 1

# Check version branch
bash scripts/helpers/ckbranchname.sh "v1.0.0"
# Exit code: 2

# Check targeted branch
bash scripts/helpers/ckbranchname.sh "dev/fix-parser-v1.0.0"
# Exit code: 3

# Check contributor branch
bash scripts/helpers/ckbranchname.sh "mywork/feature-name"
# Exit code: 4

# Check invalid branch
bash scripts/helpers/ckbranchname.sh "INVALID_NAME"
# Exit code: 5
```

**Branch Type Codes:**

| Code | Type | Format | Purpose |
|------|------|--------|----------|
| 1 | main | `main` | Protected main branch name (managed remotely) |
| 2 | version | `v<M>.<m>.0` | Protected version branch |
| 3 | targeted | `dev/fix/<desc>-<version>` | Target-specific work branch |
| 4 | contributor | `[<type>/]<description>` | General work branch |
| 5 | invalid | Any other | Invalid naming |

---

### ckrole.sh

**Purpose:** Validates user roles and permissions.

**Location:** `scripts/helpers/ckrole.sh`

**Usage:**

```bash
bash scripts/helpers/ckrole.sh "<role>"
```

**Arguments:**

- `<role>` - Role to check: `contributor`, `reviewer`, or `approver`

**Exit Codes:**

- `0` - User has the specified role
- `1` - User does not have the role

**Environment Variables:**

- `GITHUB_ACTOR` - GitHub username (preferred identity source)
- `CKROLE_TRUSTED_ACTORS` - Comma-separated list of allowed bot accounts

**Identity Resolution Order:**

1. `GITHUB_ACTOR`
2. `gh api user --jq '.login'` (if authenticated)
3. `git config user.name`
4. `USER`

If the resolved value is not a valid GitHub login format, role checks fail.

**Examples:**

```bash
# Check if user is contributor
bash scripts/helpers/ckrole.sh contributor
# Exit code: 0 or 1

# Check if user is approver
bash scripts/helpers/ckrole.sh approver
# Exit code: 0 or 1
```

---

### validate-format.sh

**Purpose:** Validates code formatting using clang-format.

**Location:** `scripts/helpers/validate-format.sh`

**Usage:**

```bash
bash scripts/helpers/validate-format.sh [<file_or_dir>]
```

**Arguments:**

- `<file_or_dir>` - Optional: File or directory to check (default: current directory)

**Exit Codes:**

- `0` - All files properly formatted
- `1` - Formatting issues found

**Examples:**

```bash
# Check all C/C++ files
bash scripts/helpers/validate-format.sh

# Check specific file
bash scripts/helpers/validate-format.sh src/runner.c

# Check directory
bash scripts/helpers/validate-format.sh src/
```

---

## Binary Scripts

Binary scripts located in `scripts/bin/` are standalone executables.

### Current scripts/bin catalog

This catalog reflects the current script set in `scripts/bin/`.

| Category | Scripts |
|----------|---------|
| Setup and Installation | `installscripts` |
| Document and Brand Management | `ckstyle`, `gendocs`, `genpngs`, `replacetext`, `rebrand` |
| Repository and Fork Management | `mkfork`, `mkclone`, `rmclone`, `fixrepo` |
| Branch and Workflow Management | `lsbranchlog`, `chbranch`, `lsbranch`, `mkbranch`, `commit`, `copyfix`, `feedback`, `mrgup`, `review`, `retarget`, `release`, `mrgbranch`, `mrgdown`, `undo`, `rmbranch` |

---

### mkbranch

**Purpose:** Creates and sets up a new branch with proper naming.

**Location:** `scripts/bin/mkbranch`

**Usage:**

```bash
scripts/bin/mkbranch -r <branch_name> [<base_branch>]
```

**Arguments:**

- `-r` - Create the branch (required)
- `<branch_name>` - Name for the new branch
- `<base_branch>` - Base branch to create from (default: `main`, resolved from `origin/main` when local `main` is absent)

**Exit Codes:**

- `0` - Branch created successfully
- `1` - Branch name invalid
- `2` - Base branch not found
- `3` - Branch already exists

**Examples:**

```bash
# Create contributor branch from main base
scripts/bin/mkbranch -r mywork/feature main

# Create targeted branch from version branch
scripts/bin/mkbranch -r dev/fix-parser-v1.0.0 v1.0.0

# Create targeted fix branch
scripts/bin/mkbranch -r fix/memory-leak-v1.0.0 v1.0.0
```

**Branch Naming Guide:**

- **Contributor:** `[<type>/]<description>` (type = dev, fix, feature, docs, etc.)
- **Targeted:** `dev/<description>-<version>` or `fix/<description>-<version>`
- **Version:** Created by approvers only

---

### chbranch

**Purpose:** Change to a branch with local-first behavior and guarded
local/remote mode switching.

**Location:** `scripts/bin/chbranch`

**Usage:**

```bash
scripts/bin/chbranch <branch>
scripts/bin/chbranch -r <branch>
scripts/bin/chbranch -f <branch>
```

**Current behavior highlights:**

- Rejects remote ref input form (`origin/<branch>`).
- Blocks switching to `main` by policy.
- Uses local branch when it exists; otherwise changes to remote `origin/<branch>`.
- Blocks switching when current worktree is dirty unless `-f` is used.
- `-r` requires remote branch availability and returns distinct not-found/
	unreachable exit codes.
- `-f -r` preserves uncommitted changes when the remote target fails prechecks.

**Validation smoke test:**

```bash
bash scripts/tests/test_chbranch.sh
```

The smoke test covers help/argument validation and key exit-code paths,
including no-change (`2`), branch/remote not-found (`3`/`4`), dirty
worktree (`6`), and remote unreachable (`7`).

---

### commit

**Purpose:** Commit changes on the current local non-protected branch.

**Location:** `scripts/bin/commit`

**Usage:**

```bash
scripts/bin/commit [OPTIONS] [-- TOKENS]
```

**Options:**

- `-d` - Dry run
- `-m, --message <msg>` - Commit message
- `-- <tokens...>` - Unix-style commit message
- `-v` - Verbose output

**Current behavior highlights:**

- `-p` is not supported.
- Auto-push occurs only when origin is connected and
  `origin/<current-branch>` exists.
- If those push preconditions are not met, commit still succeeds locally.
- Report file naming is unified:
  - `reports/branch/commit-<datetime>.md`
  - `reports/branch/commit-d-<datetime>.md` (dry-run)

---

### mkclone

**Purpose:** Clone the repository to a local directory and run initial script/hook setup.

**Location:** `scripts/bin/mkclone`

**Usage:**

```bash
scripts/bin/mkclone [OPTIONS] [directory]
```

**Examples:**

```bash
scripts/bin/mkclone
scripts/bin/mkclone my-workspace
```

---

### rmclone

**Purpose:** Safely remove a local clone directory with data-loss checks.

**Location:** `scripts/bin/rmclone`

**Usage:**

```bash
scripts/bin/rmclone [OPTIONS] <clone-path>
```

**Options:**

- `-d, --dry-run` - Preview checks and deletion plan
- `-O, --override` - Remove even when safety checks fail

**Safety checks (default):**

- working tree clean
- no stash entries
- no local-only commits
- origin reachability when configured

**Examples:**

```bash
scripts/bin/rmclone -d ../BriteTest-work
scripts/bin/rmclone ../BriteTest-work
scripts/bin/rmclone -O ../BriteTest-work
```

---

### rmbranch

**Purpose:** Safely removes a branch with validation.

**Location:** `scripts/bin/rmbranch`

**Usage:**

```bash
scripts/bin/rmbranch <branch_name>
```

**Arguments:**

- `<branch_name>` - Name of branch to remove

**Exit Codes:**

- `0` - Branch removed successfully
- `1` - Protected branch (cannot delete)
- `2` - Branch not found
- `3` - Error during deletion

**Examples:**

```bash
# Delete a contributor branch
scripts/bin/rmbranch mywork/feature

# Delete a targeted branch
scripts/bin/rmbranch dev/fix-parser-v1.0.0
```

**Protected Branches (Cannot Delete):**

- `main` (remote-only base branch)
- `v*` (version branches)

---

### mrgup

**Purpose:** Merges the current source branch to its inferred parent branch using squash merge with policy checks.

**Location:** `scripts/bin/mrgup`

**Usage:**

```bash
scripts/bin/mrgup [OPTIONS]
```

**Options:**

- `-m, --message <msg>` - Use custom squash commit message
- `-v, --verbose` - Verbose output
- `-h, --help` - Show usage

**Policy Notes:**

- Protected parents (`main` as the remote-only base, and `v<M>.<m>.<p>`) are updated via `mrgup` only
- If inferred parent is protected, approver role is required
- Resolve parent/source conflicts in the source branch before running `mrgup`
- Running from detached HEAD or a protected current branch is rejected

**Examples:**

```bash
# Merge current branch to inferred parent using PR title
scripts/bin/mrgup

# Merge with explicit message
scripts/bin/mrgup -m "Merge parser fixes"
```

---

### fixrepo

**Purpose:** Verify repository integrity and apply safe cleanup/fixes.

**Location:** `scripts/bin/fixrepo`

**Usage:**

```bash
scripts/bin/fixrepo [OPTIONS]
scripts/bin/fixrepo [OPTIONS] <clone-path>
```

**Options:**

- `-d` - Dry run (report only; no remediations)
- `-q` - Faster reduced-cost checks
- `-r <sec>` - Remote connectivity timeout in seconds (`0` disables remote checks)
- `-v` - Print report content to stdout

**Notes:**

- Writes report: `reports/repository/repository-<datetime>.md`
- Protected script: approver override required
- On non-dry runs, cleanup is followed by rerunning affected verification
	checks so the report reflects whether the remediation was actually effective.

**Maintainer failure scenarios checklist:**

| Scenario | Example Command | Expected Exit | Expected Report/Output Signal |
|----------|------------------|---------------|-------------------------------|
| Invalid timeout argument | `scripts/bin/fixrepo -r abc` | `1` | stderr includes `Invalid -r value` |
| Invalid clone path | `scripts/bin/fixrepo -d /tmp/missing-clone` | `1` | stderr includes `Clone path not found or not a directory` |
| Dry-run with detected issues | `scripts/bin/fixrepo -d` | `2` when issues exist | Report status: `Issues detected; no automated fixes applied (-d).` |
| Non-dry run with fully verified remediation | `scripts/bin/fixrepo` | `0` | Report status: `All detected issues were resolved by verified remediations.` |
| Non-dry run with remediation attempts but no verification | `scripts/bin/fixrepo` | `2` when unresolved | Report status: `Remediation attempts were made, but none were fully verified.` |
| Remote checks disabled intentionally | `scripts/bin/fixrepo -r 0` | `0` or `2` (issue-dependent) | Remote check rows indicate `Skipped (disabled by -r 0)` |

If behavior differs from this checklist, run `make test-fixrepo` and then
`make test-all-scripts` before triaging script logic.

---

### Script Smoke Test Runner

**Purpose:** Run all script smoke tests in `scripts/tests/` before PR updates.

**Location:** `scripts/tests/test_scripts.sh`

**Usage:**

```bash
make test-all-scripts
bash scripts/tests/test_scripts.sh [OPTIONS]
```

**Options (`test_scripts.sh`):**

- `-v, --verbose` - Detailed output
- `-c, --continue` - Continue after failures

When present, `test_chbranch.sh` is prioritized to run first.

**Examples:**

```bash
make test-all-scripts
bash scripts/tests/test_scripts.sh -v
bash scripts/tests/test_scripts.sh -c
```

---

### rebrand

**Purpose:** Updates brand name, initials, and tagline across the repository.

**Location:** `scripts/bin/rebrand`

**Usage:**

```bash
scripts/bin/rebrand [-d] [-h]
```

**Arguments:**

- `-d` - Dry run (show changes without applying)
- `-h` - Show help

**Exit Codes:**

- `0` - Update completed successfully
- `1` - Configuration error or failed update

**Workflow:**

1. Edit `logs/brand_history.md` with new brand values
2. Run dry run: `scripts/bin/rebrand -d`
3. Review changes in `reports/guidelines/rebrand-dry-run-*.md`
4. Apply: `scripts/bin/rebrand`
5. Verify with `git diff`

---

### genpngs

**Purpose:** Generates PNG files from SVG branding assets.

**Location:** `scripts/bin/genpngs`

**Usage:**

```bash
scripts/bin/genpngs [<svg_file_or_dir>]
```

**Arguments:**

- `<svg_file_or_dir>` - Optional: Specific SVG or directory (default: docs/branding)

**Requirements:**

- `inkscape` or `convert` command-line tools
- SVG source files in `docs/branding/`

**Examples:**

```bash
# Generate all PNG files
scripts/bin/genpngs

# Generate from specific SVG
scripts/bin/genpngs docs/branding/logo.svg

# Generate from directory
scripts/bin/genpngs docs/branding/
```

---

## Script-Based Access Control

Role-based script permissions are enforced by helper checks and protected script wrappers.

### Role Permissions Matrix

| Script Capability | Contributor (C) | Reviewer (R) | Approver (A) |
|------------------|-----------------|--------------|--------------| 
| Branch and commit operations (`mkbranch`, `commit`, `review`) | ✅ | ✅ | ✅ |
| Repository/clone lifecycle (`mkclone`, `rmclone`) | ✅ | ✅ | ✅ |
| Review operations (`feedback`) | ❌ | ✅ | ✅ |
| Retarget operations (`retarget`) | ❌ | ❌ | ✅ |
| Protected operations (`mrgup`, `release`, `fixrepo`) | ❌ | ❌ | ✅ (override required) |

### Protected Script Rule

Approver-only scripts require explicit override confirmation:

```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.0.0
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/fixrepo
```

If override confirmation is missing, execution must fail by design.

---

## Environment Variables

### GitHub Actions Environment

These variables are automatically set by GitHub Actions:

| Variable | Purpose | Example |
|----------|---------|----------|
| `GITHUB_ACTOR` | GitHub username of workflow trigger | `paulsinclair51` |
| `GITHUB_EVENT_NAME` | Type of event | `pull_request`, `push` |
| `GITHUB_REF_NAME` | Branch or tag name | `main`, `v1.0.0` |
| `GITHUB_BASE_REF` | Target branch (PR only) | `main` |
| `GITHUB_HEAD_REF` | Source branch (PR only) | `dev/feature-v1.0.0` |

### Custom Variables

Variables used by briteTest scripts:

| Variable | Purpose | Default |
|----------|---------|----------|
| `CKROLE_TRUSTED_ACTORS` | Comma-separated allowed bots | Empty |
| `CONTRIBUTORS_FILE` | Path to contributors config | `config/contributors.md` |
| `BRAND_HISTORY` | Path to brand history log | `logs/brand_history.md` |
| `GITHUB_ACTOR` | Preferred GitHub login for role checks | Environment-specific |

For role-gated scripts, ensure one of the supported identity sources resolves to a valid GitHub login in `config/contributors.md`.

---

## Exit Codes

### Common Exit Codes

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | General failure / validation failure |
| 2 | Not found / missing argument |
| 3 | Already exists / conflict |
| 4 | Permission denied |
| 5 | Invalid format |

### Script-Specific Codes

See individual script sections for detailed exit code meanings.

---

## Troubleshooting

### Common Issues

#### Branch Creation Fails

**Error:** `Branch name is invalid`

**Solution:**

1. Check branch name format
2. Run: `bash scripts/helpers/ckbranchname.sh "<name>"`
3. Fix naming to match required format

#### Repository Health Check Fails

**Error:** `Issues detected` during repository verification

**Solution:**

1. Run: `scripts/bin/fixrepo -d`
2. Review `reports/repository/repository-<datetime>.md`
3. Re-run without `-d` for safe cleanup remediations
4. If a clone path is involved, run with positional path: `scripts/bin/fixrepo <clone-path>`

#### Permission Denied

**Error:** `Permission denied` on script execution

**Solution:**

```bash
chmod +x scripts/bin/* scripts/helpers/*
```

#### Role Check Fails for Known Approver/Reviewer

**Error:** Identity cannot be resolved or user not found in contributors list

**Solution:**

1. Ensure login exists in `config/contributors.md`
2. Ensure identity resolves to your GitHub login:
	- `export GITHUB_ACTOR=<login>`
	- or `gh auth login`
	- or `git config user.name <login>`

#### Git Command Failures

**Error:** `fatal: bad revision` or similar git errors

**Solution:**

1. Verify you're in the repository root: `pwd`
2. Verify git is initialized: `ls -la .git`
3. Fetch latest refs: `git fetch --all`
4. Try command again

---

## Related Documentation

- [Contributor_Guide.md](./Contributor_Guide.md) - Main contribution guide
- [README.md](../../README.md) - Project overview
- Branch naming workflow examples in Contributor_Guide.md
