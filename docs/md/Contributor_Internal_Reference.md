![Contributor Internal Reference](/docs/branding/Contributor_Internal_Reference.png)

#### Version: v1.0.0

This reference records implementation contracts for repository repair, helper
modules, Git hooks, environment variables, and GitHub-side enforcement.

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

This document is intended for maintainers, approvers, and repository owners who
maintain validation, repair, hooks, or GitHub-side protection controls.

For routine workflow usage, see the [Contributor_Guide.md](./Contributor_Guide.md).
For public script usage, see the [Contributor_Reference.md](./Contributor_Reference.md).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-08-13 | Internal contribution reference split from public reference. | Paul Sinclair |
</details><br>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [Repository Repair Scripts](#1-repository-repair-scripts)<br>
   1.1. [fixlocal](#11-fixlocal)<br>
   1.2. [fixrepo](#12-fixrepo)<br>
   1.3. [fixremote](#13-fixremote)<br>
   1.4. [override](#14-override)<br>
2. [Role and Access Assumptions](#2-role-and-access-assumptions)<br>
3. [GitHub Server-Side Controls](#3-github-server-side-controls)<br>
4. [Operational Notes and Security Boundaries](#4-operational-notes-and-security-boundaries)<br>
5. [Internal Helpers and Hooks](#5-internal-helpers-and-hooks)<br>
  5.1. [Helper Modules](#51-helper-modules)<br>
  5.2. [Git Hooks](#52-git-hooks)<br>
6. [Internal Environment and Workflow Context](#6-internal-environment-and-workflow-context)<br>
</details>

<details>
<summary><strong>1. Repository Repair Scripts</strong></summary>

## 1. Repository Repair Scripts

These entries define the repair command interfaces. For command selection and
procedures, see the
[Repair Decision Tree](./Contributor_Internal_Guide.md#2-repair-decision-tree).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. fixlocal</summary>

### 1.1. fixlocal

**Purpose:** Repair damaged Git data, uncommitted changes, missing repository
files, remote access, or branch synchronization problems in the current clone.

**Usage:**

```bash
fixlocal [-d] [-f] [-t SEC] [-v]
```

**Key Options:**

- `-d` reports issues without repairs.
- `-f` permits guarded local repairs after saving a recovery point.
- `-t SEC` sets the remote timeout.
- `-v` prints detailed progress.

Reports are written under `reports/`. Run `fixlocal -h` for the complete exit
status contract.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. fixrepo</summary>

### 1.2. fixrepo

**Purpose:** Validate repository state beyond the current local checkout and
optionally inspect a second clone or broader workspace state.

**Usage:**

```bash
fixrepo [-d] [-q] [-t SEC] [-v] [<clone-path>]
```

**Key Options:**

- `-d` reports issues without repairs.
- `-q` uses reduced-cost diagnostics.
- `-t SEC` sets the remote timeout; `0` skips remote checks.
- `-v` prints the generated report.

The optional clone path is positional; `fixrepo` does not have an `-x` option.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.3. fixremote</summary>

### 1.3. fixremote

**Purpose:** Restore remote branches, tags, and required Git data from a healthy
local clone when local repair is insufficient.

**Usage:**

```bash
fixremote [-d] [-t SEC] [-v] <clean-clone-path>
fixremote -x [-t SEC] [-v] <clean-clone-path>
```

**Key Options:**

- Without `-x`, the command checks the source and remote and writes a report
  without changing either repository.
- `-x` restores the remote from the required healthy clone path.
- `-t SEC` sets the remote timeout; `0` skips reachability checks.
- `-v` adds per-step detail and prints the report.

Recovery reports are written under `reports/`.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.4. override</summary>

### 1.4. override

**Purpose:** Toggle explicit owner override semantics for local or remote repair
windows.

**Usage:**

```bash
override [-t SEC] on
override [-t SEC] -r on
override off
```

**Behavior:**

- Local override mode sets `brite.ownerOverride` in the clone and permits the
  repository owner through local hook enforcement.
- Remote repair mode sets `brite.remoteRepairOverride` in the clone after
  verifying remote reachability; it does not create server-side state.
- `override -r on` does not enable local unrestricted mode. `override off`
  disables both clone-local values.
- The script does not bypass GitHub rulesets or branch protection.

**Important:** the actual remote repair still requires GitHub admin authority and
must be performed by the appropriate server-side admin workflow.
</details>
</details>

<details>
<summary><strong>2. Role and Access Assumptions</strong></summary>

## 2. Role and Access Assumptions

- Repository ownership is resolved from Git identity and repository metadata.
- Contributors and reviewers are not treated as repository owners unless the
  repository configuration identifies them as such.
- The owner may use local override state to temporarily relax local, clone-scoped
  restrictions for exceptional local recovery work.
- The owner may use `override -r` only to mark a temporary remote repair workflow
  context; it is not a grant of unlimited GitHub-side authority.
- `override -r off` is not allowed; use `override off` to clear both local and
  remote override state.
- Actual remote-side repair still requires repository admin or organization admin
  permissions in GitHub.
</details>

<details>
<summary><strong>3. GitHub Server-Side Controls</strong></summary>

## 3. GitHub Server-Side Controls

The repository protection model is enforced by GitHub rulesets and branch protection
policies, not by local scripts alone:

- protected branches are managed by GitHub policies
- direct pushes to protected branches are blocked by GitHub
- deletion and force-push operations require explicit admin handling
- a temporary override hook on a local clone cannot undo server enforcement

In practical terms, the repository owner may need to make a protected branch
temporarily editable through GitHub admin controls, complete the repair, then
restore the protection immediately.
</details>

<details>
<summary><strong>4. Operational Notes and Security Boundaries</strong></summary>

## 4. Operational Notes and Security Boundaries

- Local-first repair should be attempted before remote recovery.
- Remote repair is reserved for protected branch problems or damaged Git data
  that cannot be corrected locally.
- The owner override is not a general bypass and should be kept as short-lived as
  possible.
- All exceptional repair actions should be logged and reviewed before returning to
  the normal workflow.
- Do not treat direct GitHub.com edits or direct git commands as the normal
  contributor path. They are exceptional admin-only operations.
- `mkrepo` pushes directly to the default branch and is a repository setup
  operation, not a contributor workflow path. It requires that the default
  branch is unprotected and that no local clone of the target is in use, and
  it never deletes existing content outside the `briteRepo/` script
  directories and `.github/workflows/`, which it replaces with a fresh copy.
  Server-side enforcement is only complete once those workflows are present
  and `setup_rulesets` has been run for the repository.

This document records the explicit limitations of the owner override and the
server-side administrative authority required for protected remote repair.
</details>

<details>
<summary><strong>5. Internal Helpers and Hooks</strong></summary>

## 5. Internal Helpers and Hooks

These files are implementation modules, not contributor commands. Public
workflows must invoke the corresponding command in `briteRepo/bin/`.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.1. Helper Modules</summary>

### 5.1. Helper Modules

| Module | Responsibility |
|--------|----------------|
| `ckbranchname.sh` | Branch-name classification and validation |
| `ckrole.sh`, `rbac.sh` | Identity, role, and permission checks |
| `ckstyle.sh`, `validation_helpers.sh` | Style and reusable validation checks |
| `common.sh`, `common_utils.sh` | Shared paths, output, identity, and utility functions |
| `git_helpers.sh`, `github_helpers.sh` | Git and GitHub API operations |
| `history_log.sh`, `report_helpers.sh`, `report_sync.sh` | History and report generation or synchronization |
| `branch_status.sh` | Shared branch status collection and rendering for `lsbranch` and `report` |
| `pulldown_workflow.sh` | Shared merge-down implementation for `pulldown` and `pushup` |
| `health_report.sh` | Repository health report support |
| `push_command.sh`, `push_workflow.sh`, `pushup_parent.sh` | Shared push and push-up command implementation and state transitions |
| `gendocx.sh`, `genpdf.sh` | Document conversion backends |
| `install_git_hooks.sh` | Configure the versioned hooks directory |

Source a module only from a repository command, test, or another helper that
honors its return-status contract. The helper source remains authoritative for
individual function signatures.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.2. Git Hooks</summary>

### 5.2. Git Hooks

Hooks are stored in `briteRepo/helpers/.githooks/` and selected through
`core.hooksPath`.

| Hook | Contract |
|------|----------|
| `post-checkout` | Restore local identity and hook configuration after checkout |
| `pre-commit` | Reject direct commit operations outside project commands |
| `pre-push` | Reject direct pushes outside project commands |
| `pre-merge-commit` | Reject direct merge commits outside project commands |
| `githook_helper.sh` | Shared operation detection and bypass handling |

Repository commands set `GIT_BYPASS_HOOKS=true` only around authorized internal
Git operations. It is an implementation signal, not a supported user override.
`override on` is the supported exceptional local recovery control.
</details>
</details>

<details>
<summary><strong>6. Internal Environment and Workflow Context</strong></summary>

## 6. Internal Environment and Workflow Context

| Variable | Internal Use |
|----------|--------------|
| `GIT_BYPASS_HOOKS` | Marks an authorized Git operation performed by a project command |
| `CKROLE_TRUSTED_ACTORS` | Lists explicitly trusted automation identities |
| `GITHUB_ACTOR` | Identifies the user or automation actor |
| `GITHUB_EVENT_NAME` | Identifies the triggering GitHub event |
| `GITHUB_REF_NAME` | Identifies the current branch or tag |
| `GITHUB_BASE_REF`, `GITHUB_HEAD_REF` | Identify pull-request target and source branches |

Pull-request workflows perform preventive validation. Protected-branch workflows
verify and record repository events. Their definitions under `.github/workflows/`
and the helper source are authoritative for event filters and input contracts.
For the procedure to change validation, see
[GitHub Validation Architecture](./Contributor_Internal_Guide.md#7-github-validation-architecture).
</details>
