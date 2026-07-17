![Contributor Reference](/docs/branding/Contributor_Reference.png)

#### Version: v1.0.0

Comprehensive reference for all scripts and helper tools used in briteTest development.

#### Copyright (c) 2026 Paul Sinclair

<details>
<summary><strong>License</strong></summary>

### License

SPDX-License-Identifier: MIT

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
</details>

<details>
<summary><strong>Preface</strong></summary>

## Preface

This document is for contributors, reviewers, and approvers who need
script-level details for workflow, validation, and role-based operations.

For contribution policies, branching rules, and workflows, see
[Contributor_Guide.md](./Contributor_Guide.md).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-07-09 | Initial version. | Paul Sinclair |
</details><br>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [scripts/bin/](#1-scriptsbin)<br>
   1.1. [Workflow Management](#11-workflow-management)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.1. [chbranch](#111-chbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.2. [commit](#112-commit)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.3. [copyfix](#113-copyfix)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.4. [feedback](#114-feedback)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.5. [lsbranch](#115-lsbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.6. [lsbranchlog](#116-lsbranchlog)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.7. [mkbranch](#117-mkbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.8. [mrgbranch](#118-mrgbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.9. [mrgdown](#119-mrgdown)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.10. [mrgup](#1110-mrgup)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.11. [retarget](#1111-retarget)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.12. [review](#1112-review)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.13. [rmbranch](#1113-rmbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.14. [undo](#1114-undo)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.15. [release](#1115-release)<br>
   1.2. [Repository and Clone Management](#12-repository-and-clone-management)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1. [fixrepo](#121-fixrepo)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. [installscripts](#122-installscripts)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.3. [mkclone](#123-mkclone)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.4. [mkfork](#124-mkfork)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.5. [rmclone](#125-rmclone)<br>
   1.3. [Documentation and Branding](#13-documentation-and-branding)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.1. [ckstyle](#131-ckstyle)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.2. [gendocs](#132-gendocs)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.3. [genpngs](#133-genpngs)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.4. [rebrand](#134-rebrand)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.5. [replacetext](#135-replacetext)<br>

2. [scripts/helpers/](#2-scriptshelpers)<br>
   2.1. [Validation Helpers](#21-validation-helpers)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.1. [ckbranchname.sh](#211-ckbranchnamesh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.2. [ckrole.sh](#212-ckrolesh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.3. [rbac.sh](#213-rbacsh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.4. [validation-helpers.sh](#214-validation-helperssh)<br>
   2.2. [Git and GitHub Helpers](#22-git-and-github-helpers)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.1. [git_helpers.sh](#221-git_helperssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.2. [github_helpers.sh](#222-github_helperssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.3. [history_log.sh](#223-history_logsh)<br>
   2.3. [Core Utilities](#23-core-utilities)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.1. [common.sh](#231-commonsh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.2. [common-utils.sh](#232-common-utilssh)<br>
   2.4. [Documentation Generators](#24-documentation-generators)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.1. [gendocx.sh](#241-gendocxsh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2. [genpdf.sh](#242-genpdfsh)<br>

3. [Script-Based Access Control](#3-script-based-access-control)<br>
   3.1. [Role Permissions Matrix](#31-role-permissions-matrix)<br>
   3.2. [Protected Script Rule](#32-protected-script-rule)<br>

4. [Environment Variables](#4-environment-variables)<br>
   4.1. [GitHub Actions Environment](#41-github-actions-environment)<br>
   4.2. [Custom Variables](#42-custom-variables)<br>

5. [Exit Codes](#5-exit-codes)<br>
   5.1. [Common Exit Codes](#51-common-exit-codes)<br>
   5.2. [Script-Specific Codes](#52-script-specific-codes)<br>

6. [Troubleshooting](#6-troubleshooting)<br>
   6.1. [Common Issues](#61-common-issues)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;6.1.1. [Branch Creation Fails](#611-branch-creation-fails)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;6.1.2. [Version Check Fails](#612-version-check-fails)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;6.1.3. [Permission Denied](#613-permission-denied)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;6.1.4. [Role Check Fails for Known Approver/Reviewer](#614-role-check-fails-for-known-approverreviewer)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;6.1.5. [Git Command Failures](#615-git-command-failures)<br>
</details>

<details>
<summary><strong>1. scripts/bin/</strong></summary>

## 1. scripts/bin/

Standalone executable scripts located in `scripts/bin/`. For full usage
information, run any script with `-h` or `--help`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Workflow Management</summary>

### 1.1. Workflow Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.1. chbranch</summary>

#### 1.1.1 chbranch

**Purpose:** Change to specified local branch as current branch.

**Usage:**

```bash
chbranch BRANCH
```

**Notes:**

- Blocks checkout to `main` (remote-only branch)
- Creates local tracking branch if it doesn't exist
- Can include cached remote-only branches
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.2. commit</summary>

#### 1.1.2. commit

**Purpose:** Commit changes with optional push to remote.

**Usage:**

```bash
commit [OPTIONS]
```

**Options:**

- `-p, --push` - Push after commit
- `-m, --message <msg>` - Custom commit message
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.3. copyfix</summary>

#### 1.1.3. copyfix

**Purpose:** Cherry-pick fix commits from another branch into current branch.

**Usage:**

```bash
copyfix <source_branch> [<commit_hash>]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.4. feedback</summary>

#### 1.1.4. feedback

**Purpose:** View and respond to pull request review feedback.

**Usage:**

```bash
feedback [OPTIONS]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.5. lsbranch</summary>

#### 1.1.5. lsbranch

**Purpose:** List branches and their status information.

**Usage:**

```bash
lsbranch [<pattern>]
```

**Arguments:**

- `<pattern>` - Optional: Branch name pattern to filter
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.6. lsbranchlog</summary>

#### 1.1.6. lsbranchlog

**Purpose:** Query branch history log entries.

**Usage:**

```bash
lsbranchlog [OPTIONS] [<pattern>]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.7. mkbranch</summary>

#### 1.1.7. mkbranch

**Purpose:** Create branches with policy validation and proper naming.

**Usage:**

```bash
mkbranch -r BRANCH [PARENTBRANCH]
```

**Arguments:**

- `-r` - Create the branch (required)
- `BRANCH` - Name for the new branch
- `PARENTBRANCH` - Parent branch (if BRANCH is a targeted branch, defaults
  to version branch corresponding to the target version BRANCH; otherwise,
  otherwise, PARENTBRANCH must be specified).

**Branch Naming Guide:**

- **Contributor:** `[<type>/]<description>` (type: dev, fix, feature, docs)
- **Targeted:** `dev/<description>-<version>` or `fix/<description>-<version>`
- **Version:** `v<M>.<m>.<p>` (approvers only)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.8. mrgbranch</summary>

#### 1.1.8. mrgbranch

**Purpose:** Fetch and pull latest changes from remote into local branch.

**Usage:**

```bash
mrgbranch [BRANCHNAME]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.9. mrgdown</summary>

#### 1.1.9. mrgdown

**Purpose:** Merge parent branch into current branch to sync changes.

**Usage:**

```bash
mrgdown [OPTIONS]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.10. mrgup</summary>

#### 1.1.10. mrgup

**Purpose:** Merge current branch to its inferred parent branch.

**Usage:**

```bash
mrgup [OPTIONS]
```

**Options:**

- `-m, --message <msg>` - Custom merge message
- `-v, --verbose` - Verbose output
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.11 release</summary>

#### 1.1.11. release

**Purpose:** Create and publish releases for the repository.

**Usage:**

```bash
release <version> [OPTIONS]
```

**Notes:**

- Approver role required
- Creates version branch and tags
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.12. retarget</summary>

#### 1.1.12. retarget

**Purpose:** Retarget a targeted branch to a different version branch.

**Usage:**

```bash
retarget <branch_name> <new_version>
```

**Notes:**

- Renames targeted branch with new version
- Approver role required
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.13. review</summary>

#### 1.1.13. review

**Purpose:** Create or update a pull request for code review.

**Usage:**

```bash
review [OPTIONS]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.14. rmbranch</summary>

#### 1.1.14. rmbranch

**Purpose:** Safely remove local and/or remote branches with validation.

**Usage:**

```bash
rmbranch <branch_name> [OPTIONS]
```

**Protected Branches (Cannot Delete):**

- `main` (remote-only base branch)
- `v*` (version branches)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.15. undo</summary>

#### 1.1.15. undo

**Purpose:** Undo recent merge, release, or commit operations.

**Usage:**

```bash
undo [OPTIONS]
```
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. Repository and Clone Management</summary>

### 1.2. Repository and Clone Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1. fixrepo</summary>

#### 1.2.1. fixrepo

**Purpose:** Verify repository/clone integrity and run safe cleanup fixes.

**Usage:**

```bash
fixrepo [OPTIONS]
```

**Functions:**

- Verify repository structure
- Run post-cleanup checks
- Generate health report
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. installscripts</summary>

#### 1.2.2. installscripts

**Purpose:** Install and setup all scripts in `scripts/bin/`.

**Usage:**

```bash
bash scripts/bin/installscripts [OPTIONS]
```

**Functions:**

- Make all scripts executable
- Add `scripts/bin/` to PATH in `~/.bashrc`
- Load configuration immediately
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.3. mkclone</summary>

#### 1.2.3. mkclone

**Purpose:** Clone the repository with optional target naming.

**Usage:**

```bash
mkclone [<target_name>]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.4. mkfork</summary>

#### 1.2.4. mkfork

**Purpose:** Create a fork of the repository and optionally configure upstream.

**Usage:**

```bash
mkfork [OPTIONS]
```

**Options:**

- Upstream remote configuration
- User as approver setup
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.5. rmclone</summary>

#### 1.2.5. rmclone

**Purpose:** Safely remove a local clone with validation checks.

**Usage:**

```bash
rmclone <clone_path> [OPTIONS]
```

**Options:**

- `-f, --force` - Override validation checks
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.3. Documentation and Branding</summary>

### 1.3. Documentation and Branding

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.1. ckstyle</summary>

#### 1.3.1. ckstyle

**Purpose:** Validate style guidelines for documentation, code, scripts, and versions.

**Usage:**

```bash
ckstyle [OPTIONS]
```

**Options:**

- `-d` - Run document checks
- `-r` - Run directory guide checks
- `-v` - Run version consistency checks

**Validation Coverage:**

- Markdown document formatting
- Front matter structure
- Details/summary pairing
- Heading numbering
- ASCII-only content
- Document version history
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.2. gendocs</summary>

#### 1.3.2. gendocs

**Purpose:** Generate PDF and DOCX documentation from Markdown sources.

**Usage:**

```bash
gendocs [OPTIONS]
```

**Output:** Generated documents in `build/` directory
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.3. genpngs</summary>

#### 1.3.3. genpngs

**Purpose:** Generate PNG branding images from SVG source files.

**Usage:**

```bash
genpngs [<svg_file_or_dir>]
```

**Arguments:**

- `<svg_file_or_dir>` - Optional: Specific SVG or directory (default: `docs/branding/`)

**Requirements:**

- `inkscape` or `convert` command-line tools
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.4. rebrand</summary>

#### 1.3.4. rebrand

**Purpose:** Update brand name, initials, and tagline across the repository.

**Usage:**

```bash
rebrand [OPTIONS]
```

**Workflow:**

1. Edit `logs/brand_history.md` with new brand values
2. Run script to update all references
3. Regenerates related branding assets
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.5. replacetext</summary>

#### 1.3.5. replacetext

**Purpose:** Apply configured text replacements in markdown files.

**Usage:**

```bash
replacetext [OPTIONS]
```
</details>
</details>
</details>

<details>
<summary><strong>2. scripts/helpers/</strong></summary>

## 2. scripts/helpers/

Helper modules and utilities located in `scripts/helpers/` designed to
be sourced or called by other scripts and workflows.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. Validation Helpers</summary>

### 2.1. Validation Helpers

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.1. ckbranchname.sh</summary>

#### 2.1.1. ckbranchname.sh

**Purpose:** Validates branch names against repository naming conventions.

**Usage:**

```bash
bash scripts/helpers/ckbranchname.sh "<branch_name>"
```

**Exit Codes:**

- `1` - Valid main branch name
- `2` - Valid version branch (format: `v<M>.<m>.<p>`)
- `3` - Valid targeted branch (format: `dev/<desc>-<version>` or `fix/<desc>-<version>`)
- `4` - Valid contributor branch (format: `[<type>/]<description>`)
- `5` - Invalid branch name

**Branch Type Codes:**

| Code | Type | Format | Purpose |
|------|------|--------|----------|
| 1 | main | `main` | Remote-only base branch |
| 2 | version | `v<M>.<m>.<p>` | Protected version branch |
| 3 | targeted | `dev/fix/<desc>-<version>` | Target-specific work |
| 4 | contributor | `[<type>/]<description>` | General work branch |
| 5 | invalid | Any other | Invalid naming |
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.2. ckrole.sh</summary>

#### 2.1.2. ckrole.sh

**Purpose:** Validates user roles and permissions.

**Usage:**

```bash
bash scripts/helpers/ckrole.sh "<role>"
```

**Arguments:**

- `<role>` - Role to check: `contributor`, `reviewer`, or `approver`

**Exit Codes:**

- `0` - User has the specified role
- `1` - User does not have the role

**Identity Resolution Order:**

1. `GITHUB_ACTOR` environment variable
2. `gh api user --jq '.login'` (GitHub CLI)
3. `git config user.name`
4. `USER` environment variable

**Environment Variables:**

- `GITHUB_ACTOR` - GitHub username (preferred)
- `CKROLE_TRUSTED_ACTORS` - Comma-separated allowed bot accounts
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.3. rbac.sh</summary>

#### 2.1.3. rbac.sh

**Purpose:** Role-based access control implementation for script execution.

**Functions:**

- User role verification
- Permission enforcement
- Policy validation
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.4. validation-helpers.sh</summary>

### 2.1.4. validation-helpers.sh

**Purpose:** General validation utility functions for scripts.

**Functions:**

- Input validation
- Format checking
- State verification
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. Git and GitHub Helpers</summary>

### 2.2. Git and GitHub Helpers

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.1. git_helpers.sh</summary>

#### 2.2.1. git_helpers.sh

**Purpose:** Shared Git branch and repository operation helpers.

**Functions:**

- Branch lookup and resolution
- Parent branch detection
- Protected branch checks
- Git state operations
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.2. github_helpers.sh</summary>

#### 2.2.2. github_helpers.sh

**Purpose:** Shared GitHub CLI pull-request and status helpers.

**Functions:**

- PR lookup and status
- Status check validation
- Approver verification
- GitHub API integration
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.3. history_log.sh</summary>

#### 2.2.3. history_log.sh

**Purpose:** Shared branch-history markdown logging helpers.

**Functions:**

- Log merge operations
- Track branch modifications
- Generate history reports
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.3. Core Utilities</summary>

### 2.3. Core Utilities

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.1. common.sh</summary>

#### 2.3.1. common.sh

**Purpose:** Shared output and branch-detection helpers for consistent messaging.

**Functions:**

- `bt_info()` - Print info message
- `bt_success()` - Print success message
- `bt_error_exit()` - Print error and exit
- `bt_get_current_branch()` - Get current branch name
- `ensure_hooks_installed()` - Verify/install Git hooks
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.2. common-utils.sh</summary>

#### 2.3.2. common-utils.sh

**Purpose:** Common utility functions shared across scripts.

**Functions:**

- Path manipulation
- String utilities
- File operations
- General helpers
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.4. Documentation Generators</summary>

### 2.4. Documentation Generators

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.1. gendocx.sh</summary>

#### 2.4.1. gendocx.sh

**Purpose:** Generate DOCX files from PDF sources.

**Usage:**

```bash
bash scripts/helpers/gendocx.sh <pdf_file> [<output_file>]
```

**Requirements:**

- PDF to DOCX conversion tools
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2. genpdf.sh</summary>

#### 2.4.2. genpdf.sh

**Purpose:** Generate PDF files from Markdown sources.

**Usage:**

```bash
bash scripts/helpers/genpdf.sh <markdown_file> [<output_file>]
```

**Requirements:**

- Markdown to PDF conversion tools (pandoc, etc.)
</details>
</details>
</details>

<details>
<summary><strong>3. Script-Based Access Control</strong></summary>

## 3. Script-Based Access Control

Role-based script permissions are enforced by helper checks and protected script wrappers.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Role Permissions Matrix</summary>

### 3.1. Role Permissions Matrix

| Script Capability | Contributor (C) | Reviewer (R) | Approver (A) |
|------------------|-----------------|--------------|--------------| 
| Branch and commit operations (`mkbranch`, `commit`, `mkpullrequest`) | PASS | PASS | PASS |
| Review operations (`mkfeedback`) | FAIL | PASS | PASS |
| Retarget operations (`chtarget`) | FAIL | FAIL | PASS |
| Protected operations (`mergetoparent`, `mkrelease`, `fixrepository`) | FAIL | FAIL | PASS (override required) |
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Protected Script Rule</summary>

### 3.2. Protected Script Rule

Approver-only scripts require explicit override confirmation:

```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mergetoparent
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mkrelease v1.0.0
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/fixrepository
```

If override confirmation is missing, execution must fail by design.
</details>
</details>

<details>
<summary><strong>4. Environment Variables</strong></summary>

## 4. Environment Variables

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.1. GitHub Actions Environment</summary>

### 4.1. GitHub Actions Environment

These variables are automatically set by GitHub Actions:

| Variable | Purpose | Example |
|----------|---------|----------|
| `GITHUB_ACTOR` | GitHub username of workflow trigger | `paulsinclair51` |
| `GITHUB_EVENT_NAME` | Type of event | `pull_request`, `push` |
| `GITHUB_REF_NAME` | Branch or tag name | `main`, `v1.0.0` |
| `GITHUB_BASE_REF` | Target branch (PR only) | `main` |
| `GITHUB_HEAD_REF` | Source branch (PR only) | `dev/feature-v1.0.0` |
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.2. Custom Variables</summary>

### 4.2. Custom Variables

Variables used by briteTest scripts:

| Variable | Purpose | Default |
|----------|---------|----------|
| `CKROLE_TRUSTED_ACTORS` | Comma-separated allowed bots | Empty |
| `CONTRIBUTORS_FILE` | Path to contributors config | `config/contributors.md` |
| `BRAND_HISTORY` | Path to brand history log | `logs/brand_history.md` |
| `GITHUB_ACTOR` | Preferred GitHub login for role checks | Environment-specific |

For role-gated scripts, ensure one of the supported identity sources resolves to a valid GitHub login in `config/contributors.md`.
</details>
</details>

<details>
<summary><strong>5. Exit Codes</strong></summary>

## 5. Exit Codes

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.1. Common Exit Codes</summary>

### 5.1. Common Exit Codes

| Code | Common Meaning |
|------|----------|
| 0 | Success |
| 1 | Argument/option error or validation failure |
| 2 | Git operation failed or invalid usage |
| 3 | Resource not found or operation not allowed |
| 4 | Conflict detected or API error |
| 5 | Permission/authorization error or operation failed |
| 6+ | Script-specific errors (see individual script documentation) |
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.2. Script-Specific Codes</summary>

### 5.2. Script-Specific Codes

**ckstyle**

| Code | Meaning |
|------|----------|
| 0 | Success (no validation issues) |
| 1 | Invalid option or argument |
| 2 | Validation issues found |

**commit**

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | Invalid option or argument |
| 2 | Could not detect current branch |
| 3 | Not on a local branch |
| 5 | Current branch is protected |
| 6 | Commit message missing |
| 7 | Commit message empty |
| 8 | Contributors list missing |
| 9 | Could not detect GitHub identity |
| 10 | Not authorized for commit |
| 11 | Could not inspect working tree |
| 12 | Could not stage or commit changes |
| 14 | Push failed |
| 15 | Branch divergence not auto-resolved |

**mkbranch**

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | Arguments/options invalid |
| 2 | Invalid branch name |
| 3 | Invalid option |
| 4 | Conflicting options |
| 5 | Git operation failed |
| 6 | Local parent branch doesn't exist |
| 7 | Remote parent branch doesn't exist |
| 8 | Local branch already exists |
| 9 | Remote branch already exists |
| 10 | Validation failed |

**rmbranch**

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | Argument error |
| 2 | Git operation failed |
| 3 | Branch does not exist |
| 4 | Local deleted, remote protected |
| 5 | Remote branch is protected |
| 6 | Branch has unmerged commits |
| 7 | User not authorized |
| 8 | Local deletion blocked |

**review**

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | Argument or validation error |
| 2 | Git operation failed |
| 3 | Cannot create PR from main branch |
| 4 | GitHub API error |
| 5 | Configuration error |

**chbranch**

| Code | Meaning |
|------|----------|
| 0 | Success |
| 1 | Argument or validation error |
| 2 | Branch already current |
| 3 | Branch does not exist |
| 4 | Remote branch does not exist |
| 5 | Branch operation failed |
| 6 | Current branch is dirty |
| 7 | Remote branch unreachable |

For other scripts, run with `-h` or `--help` to view exit code documentation.
</details>
</details>

<details>
<summary><strong>6. Troubleshooting</strong></summary>

## 6. Troubleshooting

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;6.1. Common Issues</summary>

### 6.1. Common Issues

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
</details>
</details>
