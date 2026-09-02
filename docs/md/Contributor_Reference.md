![Contributor Reference](/docs/branding/Contributor_Reference.png)

#### Version: v1.0.0

Reference for supported repository commands, branch rules, permissions, exit
statuses, and user troubleshooting.

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
  [`mkfork`](#125-mkfork), [`mkrepo`](#1210-mkrepo),
  [`setup_rulesets`](#129-setup_rulesets)
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
| `chbranch` | [1.1.1](#111-chbranch) | `pull` | [1.1.8](#118-pull) |
| `commit` | [1.1.2](#112-commit) | `pulldown` | [1.1.9](#119-pulldown) |
| `copyfix` | [1.1.3](#113-copyfix) | `push` | [1.1.16](#1116-push) |
| `feedback` | [1.1.4](#114-feedback) | `pushup` | [1.1.10](#1110-pushup) |
| `fixlocal` | [1.2.1](#121-fixlocal) | `rebrand` | [1.3.4](#134-rebrand) |
| `fixremote` | [1.2.2](#122-fixremote) | `release` | [1.1.11](#1111-release) |
| `fixrepo` | [1.2.7](#127-fixrepo) | `replacetext` | [1.3.5](#135-replacetext) |
| `gendocs` | [1.3.2](#132-gendocs) | `report` | [1.1.6](#116-report) |
| `genpngs` | [1.3.3](#133-genpngs) | `retarget` | [1.1.12](#1112-retarget) |
| `lsbranch` | [1.1.5](#115-lsbranch) | `review` | [1.1.13](#1113-review) |
| `mkbranch` | [1.1.7](#117-mkbranch) | `rmbranch` | [1.1.14](#1114-rmbranch) |
| `mkclone` | [1.2.4](#124-mkclone) | `rmclone` | [1.2.6](#126-rmclone) |
| `mkfork` | [1.2.5](#125-mkfork) | `setup_rulesets` | [1.2.9](#129-setup_rulesets) |
| `mkrepo` | [1.2.10](#1210-mkrepo) | `setupclone` | [1.2.3](#123-setupclone) |
| `override` | [1.2.8](#128-override) | `undo` | [1.1.15](#1115-undo) |

1. [Command Reference (`briteRepo/bin/`)](#1-command-reference-scriptsbin)<br>
   1.1. [Workflow Management](#11-workflow-management)<br>
   1.2. [Repository and Clone Management](#12-repository-and-clone-management)<br>
   1.3. [Documentation and Branding](#13-documentation-and-branding)<br>

2. [Branch and Permission Reference](#2-branch-and-permission-reference)<br>
   2.1. [Branch Types](#21-branch-types)<br>
   2.2. [Allowed Push-Up Paths](#22-allowed-push-up-paths)<br>
   2.3. [Roles](#23-roles)<br>
   2.4. [File Access](#24-file-access)<br>

3. [Command Permission Checks](#3-command-permission-checks)<br>

4. [User Environment](#4-user-environment)<br>

5. [Exit Codes](#5-exit-codes)<br>

6. [Troubleshooting](#6-troubleshooting)<br>
   6.1. [Common Issues](#61-common-issues)<br>
      [Branch Creation Fails](#branch-creation-fails)<br>
      [Version Check Fails](#version-check-fails)<br>
      [Permission Denied](#permission-denied)<br>
      [Role Check Fails for Known Approver/Reviewer](#role-check-fails-for-known-approverreviewer)<br>
      [Repository Operation Fails](#repository-operation-fails)<br>

7. [Contributor-Specific Glossary](#7-contributor-specific-glossary)<br>
</details>

<details>
<summary><strong>1. Command Reference (briteRepo/bin/)</strong></summary>

## 1. Command Reference (briteRepo/bin/)

Standalone executable scripts located in `briteRepo/bin/`. For full usage
information, run any script with `-h` or `--help`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Workflow Management</summary>

### 1.1. Workflow Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.1. chbranch</summary>

#### 1.1.1. chbranch

**Purpose:** Select a local branch or a read-only copy of a remote branch.

**Usage:**

```bash
chbranch [-l | -r] [-p] [-t SEC] [-v] [BRANCH]
chbranch [-l | -r] -b [-t SEC] [-v]
chbranch [-l | -r] -u [-t SEC] [-v]
```

**Notes:**

- Prefers an existing local branch when neither `-l` nor `-r` is specified.
- `-l` requires an existing local branch; `-r` selects a refreshed, read-only
  copy of an existing remote branch.
- `-p` selects the parent of the current branch, or the parent of `BRANCH` when
  a branch is supplied. It selects the local parent by default; use `-r` for the
  remote parent copy. It is mutually exclusive with `-b` and `-u`.
- `-b` returns to the previously selected branch. `BRANCH` is not allowed with
  `-b`. It selects the local previous branch by default; use `-r` for the remote
  previous branch copy.
- `-u` walks up the current branch stack. `BRANCH` is not allowed with `-u`. It
  selects the local stacked branch by default; use `-r` for the remote stacked
  branch copy.
- Local protected branches are updated only when they can safely match their
  remote copy. Protected branches and remote copies are read-only.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.2. commit</summary>

#### 1.1.2. commit

**Purpose:** Commit changes to the current local targeted or contributor branch.

**Usage:**

```bash
commit [OPTIONS] [-- TOKEN...]
```

**Key Options:**

- `-c TOKEN` or `-- TOKEN...` - Add a user comment to the generated commit
  message.
- `-d` - Generate a dry-run report for the commit workflow without running the
  commit workflow.
- `-e` - Generate an error report for the commit workflow without running the
  commit workflow.
- `-v` - Show progress and diagnostics.

Run `push` separately to publish the commit.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.3. copyfix</summary>

#### 1.1.3. copyfix

**Purpose:** Copy commits from a local source fix branch into the current local
target branch.

The command updates the current target branch directly. If conflicts occur,
resolve the files and rerun `copyfix` to continue the copy.

**Usage:**

```bash
copyfix [OPTIONS] SOURCE_BRANCH [-- TOKEN...]
copyfix [-v]
```

Use `-c TOKEN` or `-- TOKEN...` to replace the comment on each copied fix
commit. Without either option, copied commits retain their original comments.

Use `-d` to preview the copy without changing the target. Successful copies
are available through `report`, and the command prints `Run report for
details.` Dry runs and operation errors write
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
lsbranch [-t SEC] [-v]
lsbranch BRANCH [-t SEC] [-v]
lsbranch {-a | PATTERN} [-i] [-l] [-r] [-t SEC] [-v] [-x PATTERN]
```

**Arguments:**

- `BRANCH` - Show one branch and its parent.
- `PATTERN` - Show branches matching a quoted glob pattern.
- `-a` and `PATTERN` are mutually exclusive; `-a` includes all branches.
- `-i` lists only invalid branches after include and exclude filtering.
- `-x PATTERN` excludes matching branches, even when they match the include
  pattern.
- `-l` and `-r` select local and remote branches; if neither is specified,
  both are selected.
- A pattern with no matches exits with status `2`.
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
`branch-l-<datetime>.md`, `branch-r-<datetime>.md`,
`branch-pl-<datetime>.md`, `branch-pr-<datetime>.md`, or
`style-<datetime>.md`. Only one report with each filename prefix is kept.
Local, remote, and parent reports are retained independently.

Use `report -l`, `report -r`, `report -pl`, or `report -pr` to select the
current local, current remote, parent local, or parent remote branch report.
Without a selection option, `report` generates all four. Remote selections
refresh the corresponding remote branch without changing the checked-out branch
or read-only copy. The timeout defaults to 10 seconds.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.7. mkbranch</summary>

#### 1.1.7. mkbranch

**Purpose:** Create branches with policy validation and proper naming.

**Usage:**

```bash
mkbranch [OPTIONS] <newbranch> [<parentbranch>] [-- TOKEN...]
```

**Key Options:**

- `-d` - Dry-run. Validate the mkbranch workflow without creating the branch.
- `-l` - Create only a local branch.
- `-r` - Also create the remote branch; this is the default for version
  branches.
- `-c TOKEN` or `-- TOKEN...` - Set the branch-creation comment.

For a targeted branch, the parent defaults to the version in its name. Other
branch types use the parent rules described by `mkbranch -h`.

Creating a remote branch with `-r` requires its parent to exist both locally
and remotely. While `pushup` is unfinished, `mkbranch` refuses to create a
remote copy for its source or parent branch so the remote-copy choices saved
by `pushup` cannot change during recovery. Local-only branch creation does not
require a configured or reachable remote.

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
for verbose output. After a successful pull, run `report` to review the
recorded local branch activity.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.9. pulldown</summary>

#### 1.1.9. pulldown

**Purpose:** Pull parent-branch changes down into the current branch.

**Usage:**

```bash
pulldown [OPTIONS] [-- TOKEN...]
```

Use `-d` for a dry run, `-c TOKEN` or `-- TOKEN...` for the commit comment,
`-o` for an eligible owner-authorized version-branch operation, and `-t SEC`
for the remote timeout. After a successful pull-down, run `report` to review
the recorded local branch activity.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.10. pushup</summary>

#### 1.1.10. pushup

**Purpose:** Update the parent with the current source branch's files and
directories so both local branches contain the same files and directories. If
the parent or source has a remote copy, its files and directories finish aligned
with its corresponding local branch. A source remote copy requires a parent
remote copy. Missing optional remote copies are not created, and protected
branches must have remote copies. Interrupted work is recovered or resumed by
rerunning `pushup`.

**Usage:**

```bash
pushup [OPTIONS] [-- TOKEN...]
```

**Options:**

- `-c TOKEN` - Custom pushup commit comment.
- `-o` - Repository-owner override for eligible targeted-to-version paths.
- `-t SEC` - Remote timeout in seconds. After parent publication starts,
  subsequent remote access uses three times this value.
- `-v` - Verbose output.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.11. release</summary>

#### 1.1.11. release

**Purpose:** Create and publish releases for the repository.

**Usage:**

```bash
release [OPTIONS] VERSION
```

**Notes:**

- Approver role required
- Validates the current protected branch, then creates and publishes an
  annotated tag and GitHub release
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.12. retarget</summary>

#### 1.1.12. retarget

**Purpose:** Retarget the current local targeted branch to a different version
branch.

**Usage:**

```bash
retarget [OPTIONS] <new-parent-version> [-- TOKEN...]
```

**Notes:**

- The current branch must be a local targeted branch
- Renames the current branch with the new version
- Contributor, reviewer, or approver role required
- A successful local retarget records activity for `report`.
- With `-r`, the command also updates remote activity and directs the user to
  `report -r`.
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
rmbranch [OPTIONS] <branchname> [-- TOKEN...]
```

**Protected Branches (Cannot Delete):**

- Remote `main` and version branches cannot be deleted.
- Local protected branches may be removed when they exist locally.

Use `-l`, `-r`, or `-a` to select local, remote, or both locations. Use `-f`
only to remove a local branch with unmerged commits.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.1.15. undo</summary>

#### 1.1.15. undo

**Purpose:** Undo recent pull-down, release, commit, push, pull, or uncommitted
changes.

**Usage:**

```bash
undo [OPTIONS] [TYPE]
```

`TYPE` may be `uncommitted`, `commit`, `pull`, `push`, `copyfix`, `pulldown`,
or `release`; it defaults to `uncommitted`.
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

- `-d` - Generate a dry-run report for the push workflow without running the
  push workflow.
- `-e` - Generate an error report for the push workflow without running the
  push workflow.
- `-t SEC` - Set the remote reachability timeout.
- `-v` - Show progress and diagnostics.

**Related Commands:** Run `commit` before `push`, `pull` when both the local and
remote branches contain different changes, and `report` to inspect recorded
activity.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. Repository and Clone Management</summary>

### 1.2. Repository and Clone Management

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.1. fixlocal</summary>

#### 1.2.1. fixlocal

**Purpose:** Check this local repository, safely fix supported problems, and
produce a diagnostic report.

**Usage:**

```bash
fixlocal [OPTIONS]
```

**Functions:**

- Check for damaged Git data
- Check for uncommitted changes and missing repository files
- Check remote access and whether local branches match their remote copies
- Safely update the current branch when only its remote copy has newer changes
- Clean unused local Git data and repeat affected checks
- Record checks, fixes, and remaining problems in the report

**Exit Codes:**

- 0: Success - no issues or all issues fixed
- 1: Invalid option or argument
- 2: User is not authorized (requires contributor role or higher)
- 3: This clone has no remote repository URL
- 4: Remote is unreachable
- 5: Remote connectivity check timed out
- 6: One or more issues were not fixable
- 7: Dry run found only issues that a normal run can fix
- 100: Missing required helper files, dependencies, or configuration

Every completed run writes a diagnostic report and prints its path. Open that
file for details; these diagnostics are not generated by the `report` command.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.2. fixremote</summary>

#### 1.2.2. fixremote

**Purpose:** Restore remote branches, tags, and required Git data from a healthy
local clone. This command is restricted to approvers and owners.

**Usage:**

```bash
fixremote [OPTIONS] <clone-path>
```

**Functions:**

- Verify that the user is an approver or owner
- Verify that the source clone is healthy, has no uncommitted changes, and uses
  the same remote repository
- Preview checks by default; restore the remote only when `-x` is specified
- Restore branches, tags, and required Git data from the source clone
- Verify that the remote `main` branch matches the source clone
- Generate a recovery report with specific follow-up actions

**Exit Codes:**

- 0: Success - checks passed and no unresolved issues
- 1: Invalid option or argument
- 2: User is not authorized - only approver/owner can run fixremote
- 3: Recovery failed - see report for details
- 100: Missing required dependencies or configuration files
- 200: Git operation failed during recovery

Every completed preview or recovery run writes a diagnostic report and prints
its path. Open that file for details; these diagnostics are not generated by
the `report` command.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.3. setupclone</summary>

#### 1.2.3. setupclone

**Purpose:** Configure a clone so project commands are available and local
safeguards are active.

**Usage:**

```bash
bash briteRepo/bin/setupclone [-t SEC]
```

**Functions:**

- Make all scripts executable
- Add `briteRepo/bin/` to PATH in `~/.bashrc`
- Activate local repository safeguards
- Load configuration immediately
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.4. mkclone</summary>

#### 1.2.4. mkclone

**Purpose:** Clone the repository with optional target naming.

**Usage:**

```bash
mkclone [OPTIONS] [directory]
```

The default directory is the repository name. Use `-t SEC` to set the remote
timeout.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.5. mkfork</summary>

#### 1.2.5. mkfork

**Purpose:** Create a fork of the repository and optionally connect it to the
source repository.

**Usage:**

```bash
mkfork [OPTIONS]
```

**Key Options:**

- `-c` - Delete an incomplete or misconfigured existing fork instead of
  completing its configuration.
- `-d` - Dry-run. Validate the mkfork workflow without creating the fork.
- `-t SEC` - Set the remote timeout.
- `-v` - Show progress and diagnostics.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.6. rmclone</summary>

#### 1.2.6. rmclone

**Purpose:** Safely remove a local clone with validation checks.

**Usage:**

```bash
rmclone [OPTIONS] <clone-path>
```

**Options:**

- `-d` - Dry-run. Validate the rmclone workflow without removing the
  clone.
- `--override` - Override safety checks and remove the clone.
- `-t SEC` - Set the remote timeout.
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

- `-d` - Generate a dry-run report for the fixrepo workflow without attempting
  repairs.
- `-q` - Use reduced-cost diagnostics.
- `-t SEC` - Set the remote timeout; use `0` to skip remote checks.
- `-v` - Show the generated report.

**Related Commands:** Use `fixlocal` first for an isolated local problem and
`fixremote` only to recover a damaged remote from a known-good clone.

Every completed run writes a repository diagnostic report and prints its path.
Open that file for details; these diagnostics are not generated by the
`report` command.
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

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.2.10. mkrepo</summary>

#### 1.2.10. mkrepo

**Purpose:** Create a GitHub repository, or update an existing one, so it has
the canonical directory layout used by the `briteRepo/bin/` commands.

**Usage:**

```bash
mkrepo [OPTIONS] <repository>
```

`<repository>` is a repository name owned by the authenticated GitHub user,
not a directory. The repository is cloned to a temporary working directory,
updated, committed, and pushed to its default branch; use `mkclone` for a
working clone.

**Key Options:**

- `-d` - Generate a dry-run report for the mkrepo workflow without running the
  mkrepo workflow.
- `-e` - Generate an error report for the mkrepo workflow without running the
  mkrepo workflow.
- `-t SEC` - Set the remote timeout.
- `-v` - Report items that are already canonical.
- `--public` - Create a public repository; the default is private.
- `--rulesets` - Run `setup_rulesets` for the repository after the push.
  Repository administration permission and `jq` are required.
- `--tests` - Also refresh the `briteRepo/tests/` scripts.

**Behavior:** `briteRepo/bin/`, `briteRepo/helpers/`, and
`.github/workflows/` are replaced with a fresh copy. The command also adds
`docs/md/Guide.md` as the repository introduction with `README.md` linked to
it, copies the Contributor documents from `docs/md/`, and creates default
branding in `docs/branding/` using a black square monogram, the repository
name as the brand name, and a placeholder tagline. Other existing files are
never modified or deleted; when an existing file has a canonical name but
non-canonical content, the canonical content is added alongside it as
`<name>-canonical<ext>`, for example `README-canonical.md`.

**Report:** each run writes `reports/mkrepo-<datetime>.md` in the clone that
ran the command, listing the canonical items, the refreshed directories, the
files with non-canonical content, and the follow-up items still needed. With
`-d` the same report is written as `reports/mkrepo-d-<datetime>.md`; it is
identical except for its heading and its commit value, which is
`To be determined`. A failure after the working clone is prepared writes
`reports/mkrepo-e-<datetime>.md`, which is the same report with the exit
code, the error message, the last remote command output, and guidance for
the failure appended.

**Hardening:** the command checks the tools, the source scripts, the commit
identity, and the GitHub authentication before the repository is touched;
retries a remote operation once; and verifies that the default branch holds
the pushed commit before reporting success.

**After the push:** work through the follow-up items in the report. They
include adding contributor logins and roles to `config/contributors.md`,
setting `config/version_status.md`, replacing the placeholder text in
`docs/md/Guide.md`, replacing the default branding with `rebrand` and
`genpngs`, running `setup_rulesets` unless `--rulesets` was used, and
preparing a working clone with `mkclone` and `setupclone`.

**Prerequisite:** No local clone or checkout of the target repository may be
in use, because `mkrepo` pushes directly to the default branch. `mkrepo`
refuses to run from inside a clone of the target.
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
genpngs
```

**Requirements:**

- `inkscape` or `convert` command-line tools
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1.3.4. rebrand</summary>

#### 1.3.4. rebrand

**Purpose:** Update brand name, initials, and tagline across the repository.

**Usage:**

```bash
rebrand [-d] [-t SEC]
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
replacetext [-d] [-r] [-t SEC] [MAPPINGS]
replacetext [-d] [-r] [-t SEC] FIND REPLACE [FIND REPLACE]...
```
</details>
</details>
</details>

<details>
<summary><strong>2. Branch and Permission Reference</strong></summary>

## 2. Branch and Permission Reference

Use these tables to look up branch names, supported push-up paths, repository
permissions, and path access. For procedural guidance, see
[Branches and Permissions](./Contributor_Guide.md#5-branches-and-permissions).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. Branch Types</summary>

### 2.1. Branch Types

| Branch type | Naming pattern | Purpose |
|-------------|----------------|---------|
| Main | `main` | Production-ready protected branch |
| Version | `v<M>.<m>.0` | Protected work for a release line |
| Targeted | `dev/<desc>-<version>` or `fix/<desc>-<version>` | Work for one version |
| Contributor | `[<type>/]<description>` | General contribution work |

Changes are made on local targeted or contributor branches. `main` and version
branches are protected publication destinations.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. Allowed Push-Up Paths</summary>

### 2.2. Allowed Push-Up Paths

| Source | Parent | Pull Request | Who May Run `pushup` |
|--------|--------|--------------|----------------------|
| Contributor | Contributor | Optional | Contributor or higher |
| Contributor | Targeted | Optional | Contributor or higher |
| Targeted | Version | Approved PR required | Contributor or higher |
| Targeted | Version with `-o` | Optional | Repository owner only |
| Version | `main` | Not required | Approver |

Pushing up from `main` is not allowed. When an optional pull request exists,
`pushup` validates its current state and approval.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.3. Roles</summary>

### 2.3. Roles

| Role | Routine Capabilities |
|------|----------------------|
| Public | Read, clone, and fork the repository |
| User | Read repository content as a read-only collaborator |
| Contributor | Create branches, commit, push, and open pull requests |
| Reviewer | Contributor capabilities plus review and feedback workflows |
| Approver | Reviewer capabilities plus protected push-up and release workflows |
| Repository owner | Repository administration and supported owner overrides |

Commands requiring a specific permission resolve the GitHub login and match it
against `config/contributors.md`. Repository ownership does not automatically
grant the approver permission.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.4. File Access</summary>

### 2.4. File Access

| Path or Setting | Public | User | Contributor | Reviewer | Approver | Owner |
|-----------------|--------|------|-------------|----------|----------|-------|
| `docs/md/`, `docs/branding/`, `src/`, `include/`, `examples/` | R | R | RW | RW | RW | RW |
| `briteRepo/bin/`, `briteRepo/helpers/` | R | R | RW | RW | RW | RW |
| `config/contributors.md` | R | R | - | - | RW | RW |
| `.github/workflows/` | R | R | - | - | - | RW* |
| GitHub rulesets and branch-protection settings | R | R | - | - | - | RW* |

The table describes supported repository workflows, not raw filesystem access.
`RW*` requires GitHub repository administration permission and the applicable
exceptional protected-change procedure. Repository roles do not themselves
grant GitHub administration permission.
</details>
</details>

<details>
<summary><strong>3. Command Permission Checks</strong></summary>

## 3. Command Permission Checks

Commands check repository permissions before performing restricted operations.
The exact requirement is documented by each command's `-h` output.

Identity is resolved from the authenticated GitHub user and matched against
`config/contributors.md`. See [Roles](#23-roles) for the capability summary.
Protected operations may add approval or repository-owner checks; those checks
do not grant the caller a different repository permission.
</details>

<details>
<summary><strong>4. User Environment</strong></summary>

## 4. User Environment

Commands normally resolve identity through the authenticated GitHub CLI. Set
`GITHUB_ACTOR` to your GitHub login only when that identity cannot be resolved
automatically. The login must appear in `config/contributors.md` for commands
that require a repository permission.
</details>

<details>
<summary><strong>5. Exit Codes</strong></summary>

## 5. Exit Codes

Exit status `0` means success. Every nonzero status is command-specific; the
same number may describe different failures in different commands.

Run `COMMAND -h` to view the current exit statuses for that command. This keeps
automation and troubleshooting aligned with the executable interface.
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
2. Run `mkbranch -h` to review the supported patterns
3. Retry `mkbranch` with a valid branch and parent

#### Version Check Fails

**Error:** `Version inconsistency detected`

**Solution:**

1. Run: `report style -m`
2. Review the differences reported
3. Update the listed version numbers to the expected version
4. Rerun `report style -m` to verify

#### Permission Denied

**Error:** `Permission denied` on script execution

**Solution:**

Run `setupclone` to restore command permissions and local configuration.

#### Role Check Fails for Known Approver/Reviewer

**Error:** Identity cannot be resolved or user not found in contributors list

**Solution:**

1. Ensure login exists in `config/contributors.md`
2. Ensure identity resolves to your GitHub login:
	- `export GITHUB_ACTOR=<login>`
	- or `gh auth login`
	- or `git config user.name <login>`

#### Repository Operation Fails

**Error:** A project command reports invalid repository or branch state

**Solution:**

1. Run the command again with `-v` when supported
2. Run `fixlocal` for damaged Git data, uncommitted changes, missing repository
  files, remote access, or branch synchronization problems
3. See the [Repair Decision Tree](./Contributor_Internal_Guide.md#2-repair-decision-tree)
   if the local repair does not resolve the issue
</details>
</details>

<details>
<summary><strong>7. Contributor-Specific Glossary</strong></summary>

## 7. Contributor-Specific Glossary

For terms used throughout the broader documentation and testing framework, see
the [Glossary Reference](./Glossary_Reference.md).

- **Approver**: A reviewer authorized to approve changes and perform protected
  workflows such as release publication.
- **Breaking change**: A change that removes or changes supported public
  behavior and normally requires a major version increment.
- **Contributor**: A person authorized to submit code, documentation, fixes,
  or other improvements through the project workflow.
- **Contributor branch**: A branch for general contribution work that is not
  tied to one version. Its name is `[<type>/]<description>`.
- **Deprecated**: Supported public behavior marked for removal in a future
  major version. Deprecation requires documentation and migration guidance.
- **Documentation update**: A change to a canonical Markdown document. Update
  versioned documentation and regenerate its output formats when required.
- **Internal API change**: An implementation change that does not alter public
  API behavior but may require updates to an Internal Guide or Reference.
- **Major increment**: An increase to the first component of an `M.m.p`
  version, used for a breaking or major structural change.
- **Parent branch**: The destination immediately above a branch in an allowed
  push-up path.
- **Protected branch**: A branch, such as `main` or a version branch, that
  cannot be edited directly through routine contributor workflows.
- **Public API change**: A change to the Runner or Test API visible to API
  users. A breaking public API change requires a major version increment.
- **Pull request**: A proposal to review and approve changes before they are
  pushed up to a parent branch.
- **Push up**: Update the parent with the source branch's files and directories
  using `pushup` so both local branches contain the same files and directories.
  Existing remote copies finish with the same files and directories as their
  corresponding local branches.
- **Release**: A published, versioned project state made available to users.
- **Remote copy**: The version of a branch stored in the remote repository.
- **Reviewer**: A contributor authorized to formally review changes and manage
  review feedback. An approver is also a reviewer.
- **Synchronize**: Update a branch so it contains the required version or
  changes from another branch or its remote copy. A synchronized branch may
  retain its own additional changes; the command report identifies what was
  updated. **Synchronized**, **synchronization**, and **resynchronize** describe
  the completed action, the process, and repeating that process after another
  branch changes. When a command guarantees matching files and directories,
  its description states that explicitly.
- **Targeted branch**: A `dev/` or `fix/` branch whose work belongs to a
  specific version.
- **Test coverage requirement**: The expectation that changed behavior has
  focused tests and that applicable existing tests continue to pass.
- **Version branch**: A protected branch named `v<M>.<m>.0` for work belonging
  to one release line.
- **Versioned file**: A file that records a document or component version and
  its version history.
</details>
