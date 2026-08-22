![Contributor Reference](/docs/branding/Contributor_Reference.png)

#### Version: v1.0.0

Comprehensive reference for all scripts and helper tools used in repository development.

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

For public contribution policies, branching rules, and workflows, see
[Contributor_Guide.md](./Contributor_Guide.md).
For owner override rules, protected branch policy, and remote repair procedures,
see [Contributor_Internal_Guide.md](./Contributor_Internal_Guide.md) and
[Contributor_Internal_Reference.md](./Contributor_Internal_Reference.md).

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

**Find by task**

- **Set up:** [`mkclone`](#124-mkclone), [`setupclone`](#123-setupclone),
  [`mkfork`](#125-mkfork), [`setup_rulesets`](#129-setup_rulesets)
- **Work on a change:** [`chbranch`](#111-chbranch),
  [`mkbranch`](#117-mkbranch), [`commit`](#112-commit),
  [`push`](#1116-push), [`pull`](#118-pull),
  [`pulldown`](#119-pulldown)
- **Review and publish:** [`review`](#1113-review),
  [`feedback`](#114-feedback), [`pushup`](#1110-pushup),
  [`retarget`](#1112-retarget), [`release`](#1111-release)
- **Inspect and undo:** [`lsbranch`](#115-lsbranch),
  [`report`](#116-report), [`undo`](#1115-undo),
  [`rmbranch`](#1114-rmbranch)
- **Repair:** [`fixlocal`](#121-fixlocal), [`fixrepo`](#127-fixrepo),
  [`fixremote`](#122-fixremote), [`override`](#128-override)
- **Documentation and branding:** [`report style`](#131-report-style),
  [`gendocs`](#132-gendocs), [`genpngs`](#133-genpngs),
  [`rebrand`](#134-rebrand), [`replacetext`](#135-replacetext)

**Commands A-Z**

| Command | Reference | Command | Reference |
|---------|-----------|---------|-----------|
| `chbranch` | [1.1.1](#111-chbranch) | `mkfork` | [1.2.5](#125-mkfork) |
| `commit` | [1.1.2](#112-commit) | `override` | [1.2.8](#128-override) |
| `copyfix` | [1.1.3](#113-copyfix) | `pull` | [1.1.8](#118-pull) |
| `feedback` | [1.1.4](#114-feedback) | `pulldown` | [1.1.9](#119-pulldown) |
| `fixlocal` | [1.2.1](#121-fixlocal) | `push` | [1.1.16](#1116-push) |
| `fixremote` | [1.2.2](#122-fixremote) | `pushup` | [1.1.10](#1110-pushup) |
| `fixrepo` | [1.2.7](#127-fixrepo) | `rebrand` | [1.3.4](#134-rebrand) |
| `gendocs` | [1.3.2](#132-gendocs) | `release` | [1.1.11](#1111-release) |
| `genpngs` | [1.3.3](#133-genpngs) | `replacetext` | [1.3.5](#135-replacetext) |
| `lsbranch` | [1.1.5](#115-lsbranch) | `report` | [1.1.6](#116-report) |
| `mkbranch` | [1.1.7](#117-mkbranch) | `retarget` | [1.1.12](#1112-retarget) |
| `mkclone` | [1.2.4](#124-mkclone) | `review` | [1.1.13](#1113-review) |
| `rmbranch` | [1.1.14](#1114-rmbranch) | `setup_rulesets` | [1.2.9](#129-setup_rulesets) |
| `rmclone` | [1.2.6](#126-rmclone) | `setupclone` | [1.2.3](#123-setupclone) |
| `undo` | [1.1.15](#1115-undo) | | |

1. [Command Reference (`scripts/bin/`)](#1-command-reference-scriptsbin)<br>
   1.1. [Workflow Management](#11-workflow-management)<br>
   1.2. [Repository and Clone Management](#12-repository-and-clone-management)<br>
   1.3. [Documentation and Branding](#13-documentation-and-branding)<br>

2. [Internal Helper Reference (`scripts/helpers/`)](#2-internal-helper-reference-scriptshelpers)<br>
   2.1. [Validation Helpers](#21-validation-helpers)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.1. [ckbranchname.sh](#211-ckbranchnamesh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.2. [ckrole.sh](#212-ckrolesh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.3. [rbac.sh](#213-rbacsh)<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.4. [validation_helpers.sh](#214-validation_helperssh)<br>
   2.2. [Git and GitHub Helpers](#22-git-and-github-helpers)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.1. [git_helpers.sh](#221-git_helperssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.2. [github_helpers.sh](#222-github_helperssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.2.3. [history_log.sh](#223-history_logsh)<br>
   2.3. [Core Utilities](#23-core-utilities)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.1. [common.sh](#231-commonsh)<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.2. [common_utils.sh](#232-common_utilssh)<br>
   2.4. [Documentation Generators](#24-documentation-generators)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.1. [gendocx.sh](#241-gendocxsh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.4.2. [genpdf.sh](#242-genpdfsh)<br>
   2.5. [Git Hooks Infrastructure](#25-git-hooks-infrastructure)<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.1. [install_git_hooks.sh](#251-install_git_hookssh)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.2. [post-checkout](#252-post-checkout)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.3. [pre-commit](#253-pre-commit)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.4. [pre-push](#254-pre-push)<br>
   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.5. [pre-merge-commit](#255-pre-merge-commit)<br>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.6. [githook_helper.sh](#256-githook_helpersh)<br>

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
      [Branch Creation Fails](#branch-creation-fails)<br>
      [Version Check Fails](#version-check-fails)<br>
      [Permission Denied](#permission-denied)<br>
      [Role Check Fails for Known Approver/Reviewer](#role-check-fails-for-known-approverreviewer)<br>
      [Git Command Failures](#git-command-failures)<br>

7. [GitHub Actions Workflow Architecture](#7-github-actions-workflow-architecture)<br>
   7.1. [Architecture Overview](#71-architecture-overview)<br>
   7.2. [Layered Validation Approach](#72-layered-validation-approach)<br>
   7.3. [Helper Script Library](#73-helper-script-library)<br>
   7.4. [Adding New Validations](#74-adding-new-validations)<br>
</details>

<details>
<summary><strong>1. Command Reference (scripts/bin/)</strong></summary>

## 1. Command Reference (scripts/bin/)

Standalone executable scripts located in `scripts/bin/`. For full usage
information, run any script with `-h` or `--help`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Workflow Management</summary>

### 1.1. Workflow Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.1. chbranch</summary>

#### 1.1.1 chbranch

**Purpose:** Select a local branch or a read-only snapshot of a remote branch.

**Usage:**

```bash
chbranch [-l | -r] [-t SEC] [-v] [BRANCH]
```

**Notes:**

- Prefers an existing local branch when neither `-l` nor `-r` is specified.
- `-l` requires an existing local branch; `-r` selects a fresh read-only
  snapshot of an existing remote branch.
- Local protected branches may be selected and are refreshed only by a safe
  fast-forward. Protected branches and remote snapshots are read-only.
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

**Purpose:** Copy commits from a local source fix branch into the current local
target branch.

The command updates the current target branch directly. If conflicts occur,
resolve the files and run `copyfix --continue` to continue the copy.

**Usage:**

```bash
copyfix [OPTIONS] SOURCE_BRANCH [-- TOKEN...]
copyfix --continue [-v]
```

Use `-c TOKEN` or `-- TOKEN...` to replace the comment on each copied fix
commit. Without either option, copied commits retain their original comments.

Use `-d` to preview the copy without changing the target. Successful copies
are available through `report`. Dry runs and operation errors write
`copyfix-d-<datetime>.md` and `copyfix-e-<datetime>.md` for the current target
branch. Reports are untracked files in `reports/`.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.4. feedback</summary>

#### 1.1.4. feedback

**Purpose:** View and respond to pull request review feedback.

**Usage:**

```bash
feedback [ACTION] [OPTIONS] [-- TOKEN...]
```

**Notes:**

- `feedback view` lists review comments with IDs.
- `feedback respond -i <id> -c <text>` replies to a specific review comment.
- `feedback resolve -i <id>` resolves the matching review thread.
- `feedback approve` and `feedback disapprove` submit final approval decisions.
  Approval is refused while another open approved PR targets the same parent
  branch, or when GitHub cannot verify that no such PR exists.
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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.6. report</summary>

#### 1.1.6. report

**Purpose:** Generate repository, branch activity, or style reports.

**Usage:**

```bash
report [OPTIONS] [TYPE]
```

`TYPE` is `repo`, `branch`, or `style` and defaults to `branch`. The latest
report is written directly in `reports/` as `repo-<datetime>.md`,
`local-<datetime>.md`, `remote-<datetime>.md`, or `style-<datetime>.md`.
Only one report with each filename prefix is kept. Local and remote reports
are retained independently.

Use `report branch -r [-t SEC]` to refresh and report the remote corresponding
to the current local branch or remote snapshot without changing the checked-out
branch, detached snapshot, or worktree. For a remote snapshot, `-r` reports the
current remote state rather than the snapshot state. The timeout defaults to
10 seconds.
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
- **Version:** `v<M>.<m>.0` (approvers only)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.8. pull</summary>

#### 1.1.8. pull

**Purpose:** Fetch and pull latest changes from remote into local branch.

**Usage:**

```bash
pull [OPTIONS]
```

`pull` synchronizes the current local branch with its corresponding remote;
it does not accept a branch-name argument. Use `-d` for a dry run, `-o` for an
owner-authorized version-branch pull, `-t SEC` for the remote timeout, and `-v`
for verbose output.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.9. pulldown</summary>

#### 1.1.9. pulldown

**Purpose:** Merge parent branch into current branch to sync changes.

**Usage:**

```bash
pulldown [OPTIONS]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.10. pushup</summary>

#### 1.1.10. pushup

**Purpose:** Push the current branch up to its parent, publish both updated
branches, and leave the resynchronized source branch selected. Interrupted
prepublication work is recovered by rerunning `pushup`; work that may have
published the parent is resumed with `pushup --continue`.

**Usage:**

```bash
pushup [OPTIONS]
pushup --continue
```

**Options:**

- `--continue` - Reconcile saved local and remote tips and resume a push-up
  workflow that may have published its parent.
- `-c TOKEN` - Custom pushup commit comment.
- `-o` - Repository-owner override for eligible targeted-to-version paths.
- `-t SEC` - Remote timeout in seconds. After parent publication starts,
  subsequent remote access uses three times this value.
- `-v` - Verbose output.
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

**Purpose:** Retarget a targeted branch locally to a different version branch.

**Usage:**

```bash
retarget [-r] <branch_name> <new_version>
```

**Notes:**

- Renames targeted branch with new version
- Approver role required
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.13. review</summary>

#### 1.1.13. review

**Purpose:** Manage draft pull requests and start code review.

**Usage:**

```bash
review [OPTIONS] [-- TOKEN...]
```

**Notes:**

- By default, `review` creates a draft PR (or updates an existing draft PR).
- `review -s` starts review: create a non-draft PR, or convert an existing draft PR to ready-for-review and request reviewers/approvers.
- `review --delete` deletes the current draft PR. Use only when a draft PR exists.
- `-b` opens the PR in the GitHub UI after completion and cannot be combined with `--delete`.
- `-l` replaces existing labels when updating a draft PR.
- Use `feedback` (not `review`) to respond, resolve, approve, or disapprove review comments.
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

- `main` (protected base branch, locally and remotely)
- `v*` (version branches)
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.15. undo</summary>

#### 1.1.15. undo

**Purpose:** Undo recent pull-down, release, commit, push, pull, or uncommitted
changes.

**Usage:**

```bash
undo [OPTIONS]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.16. push</summary>

#### 1.1.16. push

**Purpose:** Push commits on the current local targeted or contributor branch
to its corresponding remote branch.

**Usage:**

```bash
push [OPTIONS]
```

**Key Options:**

- `-d` - Validate and report what would be pushed without publishing it.
- `-e` - Generate an error report for testing and diagnostics.
- `-t SEC` - Set the remote reachability timeout.
- `-v` - Show progress and diagnostics.

**Related Commands:** Run `commit` before `push`, `pull` when local and remote
branches have diverged, and `report` to inspect recorded activity.
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. Repository and Clone Management</summary>

### 1.2. Repository and Clone Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1. fixlocal</summary>

#### 1.2.1. fixlocal

**Purpose:** Check local repository health, apply guarded local remediations, and produce a diagnostic report.

**Usage:**

```bash
fixlocal [OPTIONS]
```

**Functions:**

- Verify git object database integrity (`git fsck --full`)
- Verify working tree cleanliness
- Check remote connectivity and per-branch tracking status
- Attempt guarded current-branch synchronization from upstream
- Run safe cleanup (`git gc --prune=now`)
- Continue on non-critical check/fix failures and record them in report
- Distinguish fixable vs. non-fixable issues and verified vs. unverified remediation

**Exit Codes:**

- 0: Success - no issues or all issues fixed
- 1: Invalid option or argument
- 2: User is not authorized (requires contributor role or higher)
- 3: Issues detected - one or more were not fixable
- 100: Missing required helper files, dependencies, or configuration
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. fixremote</summary>

#### 1.2.2. fixremote

**Purpose:** Run owner/approver-only origin recovery workflow from a clean local clone.

**Usage:**

```bash
fixremote [OPTIONS] <clone-path>
```

**Functions:**

- Verify user is approver/owner
- Run preflight validation (clone integrity/cleanliness, origin URL/reachability)
- Execute recovery only with `-x` (safe default is preflight-only)
- Push branch/tag refs from clean clone to origin during execution mode
- Verify post-recovery origin/main parity with source clone
- Generate recovery report with actionable follow-up details

**Exit Codes:**

- 0: Success - checks passed and no unresolved issues
- 1: Invalid option or argument
- 2: User is not authorized - only approver/owner can run fixremote
- 3: Recovery failed - see report for details
- 100: Missing required dependencies or configuration files
- 200: Git operation failed during recovery
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.3. setupclone</summary>

#### 1.2.3. setupclone

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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.4. mkclone</summary>

#### 1.2.4. mkclone

**Purpose:** Clone the repository with optional target naming.

**Usage:**

```bash
mkclone [<target_name>]
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.5. mkfork</summary>

#### 1.2.5. mkfork

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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.6. rmclone</summary>

#### 1.2.6. rmclone

**Purpose:** Safely remove a local clone with validation checks.

**Usage:**

```bash
rmclone <clone_path> [OPTIONS]
```

**Options:**

- `-f, --force` - Override validation checks
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.7. fixrepo</summary>

#### 1.2.7. fixrepo

**Purpose:** Check repository health, apply safe repairs, and generate a
repository report. One additional clone may be checked in the same run.

**Usage:**

```bash
fixrepo [OPTIONS] [<clone-path>]
```

**Key Options:**

- `-d` - Report issues without attempting repairs.
- `-q` - Use reduced-cost diagnostics.
- `-t SEC` - Set the remote timeout; use `0` to skip remote checks.
- `-v` - Show the generated report.

**Related Commands:** Use `fixlocal` first for an isolated local problem and
`fixremote` only to recover a damaged remote from a known-good clone.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.8. override</summary>

#### 1.2.8. override

**Purpose:** Enable or disable an exceptional repository-owner recovery mode
for the current clone or a temporary remote repair authorization window.

**Usage:**

```bash
override [-r] [-t SEC] on
override off
```

**Key Options:**

- `-r` - Enable the remote repair authorization window with `on`.
- `-t SEC` - Set the remote reachability timeout.
- `-v` - Show progress and diagnostics.

Use `fixlocal`, `fixrepo`, and `fixremote` before `override` when possible.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.9. setup_rulesets</summary>

#### 1.2.9. setup_rulesets

**Purpose:** Create, update, or verify the GitHub rulesets that protect `main`
and version branches.

**Usage:**

```bash
setup_rulesets [--check] [OWNER/REPOSITORY]
```

**Key Option:** `--check` verifies the live rulesets without changing them.

The authenticated GitHub user must have repository administration permission.
</details>
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.3. Documentation and Branding</summary>

### 1.3. Documentation and Branding

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.1. report style</summary>

#### 1.3.1. report style

**Purpose:** Validate style guidelines for documentation, code, scripts, and versions.

**Usage:**

```bash
report style [OPTIONS]
```

**Options:**

- `-f FILE` - Check only the specified file; may be repeated
- `-i` - Run include checks
- `-m` - Run Markdown and version consistency checks
- `-r` - Run directory guide checks
- `-s` - Run source and script checks
- `-v` - Output verbose progress and diagnostics

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

**Default Output:** PDF files in `docs/pdf/` and DOCX files in `docs/docx/`.
Use positional output-directory arguments to choose other locations.
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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.5. replacetext</summary>

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
<summary><strong>2. Internal Helper Reference (scripts/helpers/)</strong></summary>

## 2. Internal Helper Reference (scripts/helpers/)

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
- `2` - Valid version branch (format: `v<M>.<m>.0`)
- `3` - Valid targeted branch (format: `dev/<desc>-<version>` or `fix/<desc>-<version>`)
- `4` - Valid contributor branch (format: `[<type>/]<description>`)
- `5` - Invalid branch name

**Branch Type Codes:**

| Code | Type | Format | Purpose |
|------|------|--------|----------|
| 1 | main | `main` | Protected base branch |
| 2 | version | `v<M>.<m>.0` | Protected version branch |
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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.1.4. validation_helpers.sh</summary>

#### 2.1.4. validation_helpers.sh

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
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.3.2. common_utils.sh</summary>

#### 2.3.2. common_utils.sh

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

Git hooks automate configuration and enforce the script-based workflow. All hooks are versioned in `scripts/helpers/.githooks/` and configured via Git's `core.hooksPath` mechanism. The hook entrypoints keep the canonical Git hook names without `.sh` because Git resolves those names directly; shared logic can still live in `.sh` helpers such as `githook_helper.sh`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.1. install_git_hooks.sh</summary>

#### 2.5.1. install_git_hooks.sh

**Purpose:** Configure Git to use hooks from the versioned `.githooks/` directory via `core.hooksPath`.

**Usage:**

```bash
bash scripts/helpers/install_git_hooks.sh [--silent]
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
pushup                              # [OK] Push up to the parent branch
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
pulldown                      # [OK] Merge parent branch into current branch
pushup                        # [OK] Merge current branch up to parent workflow
```

**Error message shown:**

```
[ERROR] Direct git merge operations are not allowed.

  Use the 'pulldown' script instead:
   ...
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2.5.6. githook_helper.sh</summary>

#### 2.5.6. githook_helper.sh

**Purpose:** Provide common enforcement logic shared by all Git hooks.

**Usage:**

Sourced by other hooks, not called directly:

```bash
source "scripts/helpers/.githooks/githook_helper.sh"
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

Commands check repository permissions before performing restricted operations.
The exact requirement is documented by each command's `-h` output.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Role Permissions Matrix</summary>

### 3.1. Role Permissions Matrix

| Permission | Typical Capabilities |
|------------|----------------------|
| Contributor | Branch modification, validation, documentation, and reporting |
| Reviewer | Contributor capabilities plus review feedback |
| Approver | Reviewer capabilities plus protected branch and release operations |
| Repository owner | Exceptional recovery controls where a command supports them |

Identity is resolved from the authenticated GitHub user and matched against
`config/contributors.md`. For contributor-facing permission guidance, see the
[Contributor Guide](./Contributor_Guide.md). For enforcement and owner
recovery details, see the
[Contributor Internal Reference](./Contributor_Internal_Reference.md).
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Protected Script Rule</summary>

### 3.2. Protected Script Rule

Protected operations must pass permission checks, and some commands add
operation-specific approval controls.

Use script help for exact current behavior:

```bash
pushup -h
release -h
fixlocal -h
rmbranch -h
```

Repository owner override controls are explicit and local to the invoking
command or clone; they do not grant a different repository permission.
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

**report style**

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

1. Run: `report style -m`
2. Review the differences reported
3. Manually update version numbers in affected files
4. Re-run `report style -m` to verify

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

Pull-request workflows validate proposed changes before they reach protected
branches. Protected-branch workflows then record and verify repository events.
Shared checks live in `scripts/helpers/`, principally `common_utils.sh` and
`validation_helpers.sh`.

| Layer | Trigger | Purpose |
|-------|---------|---------|
| Pull-request validation | Pull request activity | Reject invalid content, commits, signatures, or protected-file changes |
| Protected-branch audit | Pushes and tags | Verify and record protected repository activity |

Workflow files are under `.github/workflows/`. For implementation details and
the process for changing validation, see the
[Contributor Internal Reference](./Contributor_Internal_Reference.md).
</details>
