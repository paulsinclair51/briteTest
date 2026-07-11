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
| v1.0.0 | 2026-07-09 | Current v1.0.0 development reference; includes initial content plus PR #10 consolidation in `Script-Based Access Control`. | Paul Sinclair |

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
- `1` - Valid main branch
- `2` - Valid version branch (format: v<M>.<m>.0)
- `3` - Valid targeted branch (format: dev/<desc>-<version> or fix/<desc>-<version>)
- `4` - Valid contributor branch (format: [<type>/]<description>)
- `5` - Invalid branch name

**Examples:**

```bash
# Check main branch
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
| 1 | main | `main` | Protected main branch |
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
- `<base_branch>` - Base branch to create from (default: main)

**Exit Codes:**

- `0` - Branch created successfully
- `1` - Branch name invalid
- `2` - Base branch not found
- `3` - Branch already exists

**Examples:**

```bash
# Create contributor branch from main
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

- `main`
- `v*` (version branches)

---

### mergetoparent

**Purpose:** Merges the current source branch to its inferred parent branch using squash merge with policy checks.

**Location:** `scripts/bin/mergetoparent`

**Usage:**

```bash
scripts/bin/mergetoparent [OPTIONS]
```

**Options:**

- `-m, --message <msg>` - Use custom squash commit message
- `-v, --verbose` - Verbose output
- `-h, --help` - Show usage

**Policy Notes:**

- Protected parents (`main`, `v<M>.<m>.<p>`) are updated via `mergetoparent` only
- If inferred parent is protected, approver role is required
- Resolve parent/source conflicts in the source branch before running `mergetoparent`
- Running from detached HEAD or a protected current branch is rejected

**Examples:**

```bash
# Merge current branch to inferred parent using PR title
scripts/bin/mergetoparent

# Merge with explicit message
scripts/bin/mergetoparent -m "Merge parser fixes"
```

---

### ckversions

**Purpose:** Validates version consistency across all versioned files.

**Location:** `scripts/bin/ckversions`

**Usage:**

```bash
scripts/bin/ckversions [--check] [--update]
```

**Arguments:**

- `--check` - Check version consistency (default)
- `--update` - Update versions to be consistent

**Exit Codes:**

- `0` - Versions are consistent
- `1` - Version inconsistency detected

**Examples:**

```bash
# Check version consistency
scripts/bin/ckversions

# Check with detailed output
scripts/bin/ckversions --check

# Update versions (caution: advanced)
scripts/bin/ckversions --update
```

**Versioned Files:**

- `include/runnerapi.h` - Runner API header
- `src/runnerapi.c` - Runner API implementation
- `include/testapi.h` - Test API header
- `src/testapi.c` - Test API implementation
- `docs/md/*.md` - Documentation (excluding README.md)

---

### updatebrand

**Purpose:** Updates brand name, initials, and tagline across the repository.

**Location:** `scripts/bin/updatebrand`

**Usage:**

```bash
scripts/bin/updatebrand [-d] [-h]
```

**Arguments:**

- `-d` - Dry run (show changes without applying)
- `-h` - Show help

**Exit Codes:**

- `0` - Update completed successfully
- `1` - Configuration error or failed update

**Workflow:**

1. Edit `logs/brand_history.md` with new brand values
2. Run dry run: `scripts/bin/updatebrand -d`
3. Review changes in `logs/updatebrand-log-dry-run-*.md`
4. Apply: `scripts/bin/updatebrand`
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
| Branch and commit operations (`mkbranch`, `commit`, `mkpullrequest`) | ✅ | ✅ | ✅ |
| Review operations (`mkfeedback`) | ❌ | ✅ | ✅ |
| Retarget operations (`chtarget`) | ❌ | ❌ | ✅ |
| Protected operations (`mergetoparent`, `mkrelease`, `fixrepository`) | ❌ | ❌ | ✅ (override required) |

### Protected Script Rule

Approver-only scripts require explicit override confirmation:

```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mergetoparent
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mkrelease v1.0.0
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/fixrepository
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

#### Version Check Fails

**Error:** `Version inconsistency detected`

**Solution:**

1. Run: `scripts/bin/ckversions`
2. Review the differences reported
3. Manually update version numbers in affected files
4. Re-run `scripts/bin/ckversions` to verify

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
