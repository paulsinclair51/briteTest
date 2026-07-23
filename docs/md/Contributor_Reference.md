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
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.8. [pull](#118-pull)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.9. [mrgdown](#119-mrgdown)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.10. [mrgup](#1110-mrgup)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.11. [retarget](#1111-retarget)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.12. [review](#1112-review)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.13. [rmbranch](#1113-rmbranch)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.14. [undo](#1114-undo)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.15. [release](#1115-release)<br>
   1.2. [Repository and Clone Management](#12-repository-and-clone-management)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1. [fixrepo](#121-fixrepo)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. [setupclone](#122-setupclone)<br>
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
   2.5. [Git Hooks Infrastructure](#25-git-hooks-infrastructure)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.1. [install-git-hooks.sh](#251-install-git-hookssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.2. [post-checkout](#252-post-checkout)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.3. [pre-commit](#253-pre-commit)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.4. [pre-push](#254-pre-push)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.5. [pre-merge-commit](#255-pre-merge-commit)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.6. [orchestrator.sh](#256-orchestratorsh)<br>

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
      6.1.1. [Branch Creation Fails](#611-branch-creation-fails)<br>
      6.1.2. [Version Check Fails](#612-version-check-fails)<br>
      6.1.3. [Permission Denied](#613-permission-denied)<br>
      6.1.4. [Role Check Fails for Known Approver/Reviewer](#614-role-check-fails-for-known-approverreviewer)<br>
      6.1.5. [Git Command Failures](#615-git-command-failures)<br>

7. [GitHub Actions Workflow Architecture](#7-github-actions-workflow-architecture)<br>
   7.1. [Architecture Overview](#71-architecture-overview)<br>
   7.2. [Layered Validation Approach](#72-layered-validation-approach)<br>
   7.3. [Helper Script Library](#73-helper-script-library)<br>
   7.4. [Adding New Validations](#74-adding-new-validations)<br>
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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.8. pull</summary>

#### 1.1.8. pull

**Purpose:** Fetch and pull latest changes from remote into local branch.

**Usage:**

```bash
pull [BRANCHNAME]
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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. setupclone</summary>

#### 1.2.2. setupclone

**Purpose:** Setup clone environment - install scripts, add to PATH, and configure Git hooks.

**Usage:**

```bash
bash scripts/bin/setupclone [OPTIONS]
```

**Functions:**

- Make all scripts executable
- Add `scripts/bin/` to PATH in `~/.bashrc`
- Configure Git hooks via `core.hooksPath`
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

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.5. Git Hooks Infrastructure</summary>

### 2.5. Git Hooks Infrastructure

Git hooks automate configuration and enforce the script-based workflow. All hooks are versioned in `scripts/helpers/.githooks/` and configured via Git's `core.hooksPath` mechanism.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.1. install-git-hooks.sh</summary>

#### 2.5.1. install-git-hooks.sh

**Purpose:** Configure Git to use hooks from the versioned `.githooks/` directory via `core.hooksPath`.

**Usage:**

```bash
bash scripts/helpers/install-git-hooks.sh [--silent]
```

**Options:**

- `--silent` - Suppress output (for use in automated workflows)

**What it does:**

- Configures `git config core.hooksPath scripts/helpers/.githooks`
- Makes all hook files executable
- Works in both fresh clones and existing repositories

**Exit codes:**

- `0` - Git hooks configured successfully
- `1` - Could not determine repository root
- `2` - .git directory not found
- `3` - .githooks directory not found
- `4` - Failed to set core.hooksPath

**Called by:**

- `setupclone` - Automatically during clone setup
- `mkclone` - Automatically during repository cloning
- `post-checkout` hook - As fallback safety net
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.2. post-checkout</summary>

#### 2.5.2. post-checkout

**Purpose:** Auto-configure git identity and ensure hooks are installed after clone and checkout.

**Triggers:** After `git clone`, `git checkout`, or any git operation that changes working tree

**What it does:**

1. Queries GitHub API via `gh cli` to get your GitHub login
2. Sets `git config --local user.name` to your GitHub login (not display name)
3. Verifies `core.hooksPath` is configured

**Why it matters:**

- Prevents git user.name truncation issues
- Ensures commits are attributed to your GitHub login
- Runs automatically on every clone without user action

**Example:**

```bash
# After git clone, hook runs automatically
# You see your git config updated:
$ git config --local user.name
paulsinclair51
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.3. pre-commit</summary>

#### 2.5.3. pre-commit

**Purpose:** Block direct `git add` and `git commit` operations to enforce script-based commits.

**Triggers:** Before `git add` or `git commit` command

**What it blocks:**

```bash
git add <file>           # [ERROR] BLOCKED
git commit -m "msg"      # [ERROR] BLOCKED
git rm <file>            # [ERROR] BLOCKED
```

**What to use instead:**

```bash
commit -m "Your message"           # [OK] Correct approach
commit -m "Message" -p             # [OK] Commit + push
```

**How to bypass (scripts only):**

Scripts automatically set `GIT_BYPASS_HOOKS=true` before git operations.

**Error message shown:**

```
[ERROR] Direct git add/commit/rm operations are not allowed.

   Use the 'commit' script instead:
   
     commit -m "Your commit message"
     commit -m "Message" -p    # Commit and push
   
   For help:
     commit -h
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.4. pre-push</summary>

#### 2.5.4. pre-push

**Purpose:** Block direct `git push` operations to enforce script-based push workflows.

**Triggers:** Before `git push` command

**What it blocks:**

```bash
git push origin <branch>           # [ERROR] BLOCKED
git push --force-with-lease        # [ERROR] BLOCKED
git push origin --delete <branch>  # [ERROR] BLOCKED
```

**What to use instead:**

```bash
commit -m "msg" -p                 # [OK] Commit + push
push                               # [OK] Push current branch
mrgup                              # [OK] Merge-up workflow
rmbranch <branch> -r               # [OK] Delete remote branch
```

**Error message shown:**

```
[ERROR] Direct git push operations are not allowed.

   Use the appropriate script instead:
   ...
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.5. pre-merge-commit</summary>

#### 2.5.5. pre-merge-commit

**Purpose:** Block direct `git merge` operations to enforce script-based merge workflows.

**Triggers:** Before `git merge` command creates a merge commit

**What it blocks:**

```bash
git merge <branch>           # [ERROR] BLOCKED
git merge --squash           # [ERROR] BLOCKED
git merge --no-ff            # [ERROR] BLOCKED
```

**What to use instead:**

```bash
mrgdown                      # [OK] Merge parent branch into current branch
mrgup                        # [OK] Merge current branch up to parent workflow
```

**Error message shown:**

```
[ERROR] Direct git merge operations are not allowed.

  Use the 'mrgdown' script instead:
   ...
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.6. orchestrator.sh</summary>

#### 2.5.6. orchestrator.sh

**Purpose:** Provide common enforcement logic shared by all Git hooks.

**Usage:**

Sourced by other hooks, not called directly:

```bash
source "scripts/helpers/.githooks/orchestrator.sh"
check_bypass "git commit" "commit"
```

**Functions provided:**

- `check_bypass <operation> [suggested_script]` - Check if bypass flag set and show error if blocked
- `hook_name` - Get current hook name
- `git_command_in_progress` - Check if git command is in progress

**How it works:**

1. Checks `GIT_BYPASS_HOOKS` environment variable
2. If set to `true`, allows operation (script is running)
3. If not set, blocks operation and shows error guidance

**Bypass flag usage (internal):**

```bash
# Scripts use this pattern:
export GIT_BYPASS_HOOKS=true
git add files...
git commit -m "msg"
unset GIT_BYPASS_HOOKS
```

**Security model:**

- Only scripts can set `GIT_BYPASS_HOOKS`
- Environment variable is unset immediately after operation
- Direct user git commands cannot bypass hooks
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

briteTest implements hierarchical role-based access control: **Approver (A)** > **Reviewer (R)** > **Contributor (C)**

#### Capabilities by Role

| Script Capability | Contributor (C) | Reviewer (R) | Approver (A) |
|------------------|-----------------|--------------|--------------| 
| Branch and commit operations | [OK] | [OK] | [OK] |
| Review operations | [NO] | [OK] | [OK] |
| Retarget operations | [NO] | [NO] | [OK] |
| Protected operations (merge/release/repair) | [NO] | [NO] | [OK] (override required) |

#### Scripts by Role

**Contributor (C) Scripts** - Basic contributor access
```
mkbranch          - Create new feature branches from parent
mkclone           - Clone the repository
commit            - Create and sign commits with optional push (-p)
copyfix           - Cherry-pick fix commits between branches
pull         - Sync with remote repository
mrgdown           - Sync down from main branch
undo              - Undo uncommitted changes
lsbranchlog       - Check branch history
lsbranch          - List branches and status
ckstyle           - Check code style compliance
gendocs           - Generate PDF/DOCX documentation
genpngs           - Generate PNG branding from SVG
setupclone        - Setup clone environment
```

**Reviewer (R) Scripts** - Inherits all Contributor scripts, plus:
```
feedback          - Provide code review feedback on PRs
review            - Create/update pull requests for review
```

**Approver (A) Scripts** - Inherits all Reviewer + Contributor scripts, plus:
```
mrgup             - Merge branches to parent/protected branches (requires override)
release           - Create releases and version tags (requires override)
fixrepo           - Repair repository state (requires override)
rebrand           - Update branding across repository (requires override)
replacetext       - Replace text globally across repo (requires override)
```

#### How Role Checking Works

1. User's GitHub login is resolved from (in order):
   - `GITHUB_ACTOR` environment variable
   - `gh auth login` via GitHub CLI
   - `git config user.name` (must be GitHub login, not display name)

2. Login is matched against `config/contributors.md` to determine role (C/R/A)

3. Script checks required role and either executes or fails with permission error

**Example Role Check:**
```bash
# If you are a Contributor and run:
mrgup

# Script will fail:
[ERROR] This operation requires Approver role
```

#### Protected Script Override

Approver-only scripts require explicit override confirmation:

```bash
SCRIPT_OVERRIDE_CONFIRMED=true mrgup
SCRIPT_OVERRIDE_CONFIRMED=true release v1.0.0
SCRIPT_OVERRIDE_CONFIRMED=true fixrepo
```

Without override flag, execution fails by design as a safety control.
Role checks are evaluated first; override confirmation does not grant
non-approver users additional access.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Protected Script Rule</summary>

### 3.2. Protected Script Rule

Approver-only scripts require explicit override confirmation:

```bash
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/mrgup
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/release v1.0.0
SCRIPT_OVERRIDE_CONFIRMED=true scripts/bin/fixrepo
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

<details>
<summary><strong>7. GitHub Actions Workflow Architecture</strong></summary>

## 7. GitHub Actions Workflow Architecture

### 7.1. Architecture Overview

briteTest uses a **defense-in-depth** validation approach with two layers of GitHub Actions workflows:

**Primary Layer (Prevention)** - Blocks invalid PRs before merge
- `branch-validation-pull-request.yml` - PR content validation
- `branch-validation-commit-message.yml` - Commit message format
- `branch-validation-gpg-signature.yml` - Signed commits required
- `branch-validation-file-changes.yml` - Protected file changes blocked
- `branch-validation-secrets.yml` - Secret scanning
- `branch-validation-code-quality.yml` - Code standards
- `+4 more prevention workflows` - Specialized validation (license headers, file size, workflows, authors)

**Secondary Layer (Audit)** - Creates compliance log after merge
- `branch-validation-merge.yml` - Log merge operations
- `branch-validation-rebase.yml` - Log rebase operations  
- `branch-validation-force-push.yml` - Log force push operations
- `branch-validation-cherry-pick.yml` - Log cherry-pick operations
- `+1 more audit workflow` - Tag operations logging

### 7.2. Layered Validation Approach

```
[=============================================================]
  LAYER 1: PRIMARY - Prevention (PR Blocks)
  Runs on: pull_request (opened, synchronize, reopened)
  Result: Fails PR if any validation fails
  + 10 prevention workflows covering all key validations
[=============================================================]
                            |
                    All Checks Pass
                            |
          PR Approved and Ready to Merge
                            |
[=============================================================]
  LAYER 2: SECONDARY - Audit (Compliance Logging)
  Runs on: push (to main and version branches)
  Result: Creates audit log entry in reports/
  + 5 audit workflows tracking protected-branch activity
[=============================================================]
                            |
              Audit Trail Recorded
```

**Benefits of this approach:**
- Failures detected early (before merge)
- Issues fixed in PRs (not production)
- Audit trail shows who changed what, when
- Compliance visibility for code governance
- Easy to add new validations without modifying old workflows

### 7.3. Helper Script Library

Workflows use centralized helper scripts to reduce duplication and share validation logic:

```
scripts/helpers/
+-- common-utils.sh
|   +-- log_info, log_error, log_section
|   +-- assert_set, assert_file_exists
|   +-- timer_start, timer_end
|   +-- string_contains, string_equals
|   +-- array_contains
|   +-- git_log_range, git_changed_files
|   +-- print_success, print_failure
|
+-- validation-helpers.sh
|   +-- validate_commit_message() - Check commit format
|   +-- validate_all_commit_messages() - Check PR commits
|   +-- scan_for_secrets() - Pattern matching for secrets
|   +-- check_file_size() - File size limits
|   +-- validate_license_header() - License text presence
|   +-- validate_shell_format() - Shell script syntax
|   +-- validate_c_format() - C/H file syntax
|
+-- Domain-Specific Helpers
|   +-- ckbranchname.sh - Branch naming validation
|   +-- ckrole.sh - User role verification
|   +-- rbac.sh - Role-based access control
|   +-- Others - Repository-specific checks
```

**Key principles:**
- Functions are reusable and standalone
- Clear return codes (0=success, 1=failure)
- Documented with inline comments
- Efficient (fail fast, minimize git operations)
- Tested in workflows before merge

### 7.4. Adding New Validations

To add a new validation workflow:

**1. Implement validation function** in `scripts/helpers/validation-helpers.sh`:

```bash
# validate_my_check: Description of what is validated
#
# Args: $1 = parameter (e.g., commit hash, file path)
# Returns: 0 if valid, 1 if invalid (non-zero)
# 
validate_my_check() {
  local param=$1
  
  # Your validation logic
  if [[ condition ]]; then
    return 0  # Valid
  else
    return 1  # Invalid
  fi
}
```

**2. Create workflow file** `.github/workflows/branch-validation-mycheck.yml`:

```yaml
name: Validate My Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for comparisons

      - name: Source helpers
        run: |
          source scripts/helpers/common-utils.sh
          source scripts/helpers/validation-helpers.sh

      - name: Run validation
        run: |
          timer_start
          log_section "My Check"
          
          if validate_my_check "param"; then
            print_success "My check passed"
            timer_end "my_check"
          else
            print_failure "My check failed"
            exit 1
          fi
```

**3. Register in branch protection rules:**

Add the new workflow to GitHub branch protection settings for `main` and version branches.

**4. Test and iterate:**

- Push to a test branch to verify workflow runs
- Fix any issues and re-push
- Once working, create PR for review
</details>
