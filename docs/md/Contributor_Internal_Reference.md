![Contributor Internal Reference](/docs/branding/Contributor_Internal_Reference.png)

#### Version: v1.0.0

This reference contains internal operational details for the briteTest contributor
workflow, repository protection, repair scripts, and GitHub-side enforcement
controls. It complements the public Contributor Reference and the public
Contributor Guide.

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

This document is intended for repository maintainers, approvers, and contributors
working directly with repository validation, repair paths, and GitHub-side
protection controls.

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
</details>

<details>
<summary><strong>1. Repository Repair Scripts</strong></summary>

## 1. Repository Repair Scripts

These scripts form the internal repair sequence used when the repository state is
not healthy or when a remote-authored issue must be diagnosed from a clean local
state.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. fixlocal</summary>

### 1.1. fixlocal

**Purpose:** Repair the current local clone, worktree state, tracking, or local
repository integrity issues.

**Typical use:**

```bash
fixlocal
```

**Prerequisites:**

- Must run inside a valid repository clone.
- Current branch should be a local branch rather than a remote snapshot.
- Local repository metadata must be consistent enough to make repairs.

This is the default first repair action when the current repo is the issue.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.2. fixrepo</summary>

### 1.2. fixrepo

**Purpose:** Validate repository state beyond the current local checkout and
optionally inspect a second clone or broader workspace state.

**Typical use:**

```bash
fixrepo
fixrepo -x <clean-clone-path>
```

**Prerequisites:**

- Local repo should already be repaired to the extent possible.
- Additional clone path may be needed for broader diagnosis.

This is the broader follow-up when local repair was insufficient or when a second
clone must be included in the validation.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.3. fixremote</summary>

### 1.3. fixremote

**Purpose:** Recover a damaged remote repository state from a clean local clone,
including remote refs or object issues that cannot be resolved in-place.

**Typical use:**

```bash
fixremote
fixremote -x <clean-clone-path>
```

**Prerequisites:**

- Must be run from a clean local clone or from a valid recovery path.
- Remote reachability must succeed within the configured timeout.
- The operation is reserved for remote repo recovery and is not the first repair
  path for normal local issues.

This script is not a general-purpose branch editor; it is specifically for remote
repository repair preparation and recovery flow.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.4. override</summary>

### 1.4. override

**Purpose:** Toggle explicit owner override semantics for local or remote repair
windows.

**Typical use:**

```bash
override on
override off
override -r on
```

**Behavior:**

- Local override mode affects local enforcement that is tied to the current clone.
- Remote repair mode records a temporary server-side repair authorization window.
- The script does not bypass GitHub rulesets or branch protection.

**Important:** the actual remote repair still requires GitHub admin authority and
must be performed by the appropriate server-side admin workflow.
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

<details>
<summary><strong>3. GitHub Server-Side Controls</strong></summary>

## 3. GitHub Server-Side Controls

The repository protection model is enforced by GitHub rulesets and branch protection
policies, not by local scripts alone:

- protected refs are managed as server-side policies
- direct pushes to protected branches are blocked by GitHub
- deletion and force-push operations require explicit admin handling
- a temporary override hook on a local clone cannot undo server enforcement

In practical terms, the repository owner may need to make a protected branch
temporarily editable through GitHub admin controls, complete the repair, then
restore the protection immediately.

<details>
<summary><strong>4. Operational Notes and Security Boundaries</strong></summary>

## 4. Operational Notes and Security Boundaries

- Local-first repair should be attempted before remote recovery.
- Remote repair is reserved for protected ref issues, repository state damage, or
  bad object/data issues that cannot be corrected locally.
- The owner override is not a general bypass and should be kept as short-lived as
  possible.
- All exceptional repair actions should be logged and reviewed before returning to
  the normal workflow.
- Do not treat direct GitHub.com edits or direct git commands as the normal
  contributor path. They are exceptional admin-only operations.

This document records the explicit limitations of the owner override and the
server-side administrative authority required for protected remote repair.
</details>
</details>
