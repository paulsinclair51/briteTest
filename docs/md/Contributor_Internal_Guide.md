![Contributor Internal Guide](/docs/branding/Contributor_Internal_Guide.png)

#### Version: v1.0.0

This document explains protected repository policy, repair decisions, and
exceptional administrative procedures for maintainers, approvers, and repository
owners. It is not part of the routine contributor workflow.

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
manage policy enforcement, repair workflows, or GitHub-side protections.

For the public contribution workflow, see the [Contributor_Guide.md](./Contributor_Guide.md).
For script-level details, see the [Contributor_Reference.md](./Contributor_Reference.md).
For the internal implementation reference, see the [Contributor_Internal_Reference.md](./Contributor_Internal_Reference.md).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-08-13 | Internal contributor policy split from public guide. | Paul Sinclair |
</details><br>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [Internal Role and Policy Model](#1-internal-role-and-policy-model)<br>
2. [Repair Decision Tree](#2-repair-decision-tree)<br>
3. [Protected Branch and Ruleset Model](#3-protected-branch-and-ruleset-model)<br>
4. [Remote Repair Procedure](#4-remote-repair-procedure)<br>
5. [Override Semantics](#5-override-semantics)<br>
6. [Internal Operational Notes](#6-internal-operational-notes)<br>
7. [GitHub Validation Architecture](#7-github-validation-architecture)<br>
</details>

<details>
<summary><strong>1. Internal Role and Policy Model</strong></summary>

## 1. Internal Role and Policy Model

This repository uses script-enforced workflow boundaries together with GitHub-side
rulesets and branch protection. The public contributor guide describes the user
level of the model; this document captures the internal enforcement model.

- Direct git operations that modify the repository are intentionally discouraged
  and blocked by local hooks unless the workflow requires a local exceptional
  override.
- Protected branches and version branches are server-authoritative; GitHub rulesets
  enforce deletion and non-fast-forward protections.
- The repository owner is not automatically exempt from these protections.
- Script-level checks are enforced locally and remain authoritative for workflow
  semantics that GitHub cannot express from a ref update alone.

These rules are intended to preserve auditability and to keep repository mutations
bound to known project workflows rather than direct branch editing.
</details>

<details>
<summary><strong>2. Repair Decision Tree</strong></summary>

## 2. Repair Decision Tree

Use the repair scripts in the following order unless a different issue is already
known:

1. `fixlocal` for the current local clone, branch tracking, worktree state, or
   local repository integrity issues. This is the default starting point for
   repairing the current local repository.
2. `fixrepo` for broader repository-level validation when the issue may affect
   more than the current working copy or when a second clone needs review.
3. `fixremote` when the issue is in the remote origin repository or a remote
   ref/object must be recovered from a known-good local clone.
4. GitHub admin-side remote repair workflow only when protected remote refs or
   rulesets must be changed. Use `override -r` only as the temporary owner
   authorization marker; it does not perform the repair itself.

This order keeps the repair scope narrow first and only expands to broader or
remote recovery steps when the local repository is clean and the issue remains.
</details>

<details>
<summary><strong>3. Protected Branch and Ruleset Model</strong></summary>

## 3. Protected Branch and Ruleset Model

The GitHub ruleset configuration is managed by `briteRepo/bin/setup_rulesets`.
Protected branches are enforced at the server level for:

- `main`
- version branches such as `v<M>.<m>.0`
- any additional branches explicitly configured in the ruleset set

The ruleset model is intentionally conservative:

- no bypass actor is configured for protected branch enforcement
- direct branch mutation on GitHub.com is not treated as a valid routine path
- remote repair requires admin-side exception or explicit rule adjustment

This means that a contributor or owner cannot rely on local config to bypass
repository protection. Only an actual GitHub-side admin authority can do that.
</details>

<details>
<summary><strong>4. Remote Repair Procedure</strong></summary>

## 4. Remote Repair Procedure

When a protected branch or remote ref must be repaired, the repository owner must
use GitHub-side admin controls and a documented repair sequence, not a local clone
override.

1. Verify the acting user is a GitHub repository admin or organization admin.
2. Run `override -r on` to mark the start of a temporary remote repair session.
3. In GitHub, temporarily disable or update the relevant ruleset or
   branch-protection rule for the damaged ref.
4. Repair the remote state from a clean clone using the approved recovery
   workflow, such as `fixremote -x <clean-clone-path>`.
5. Re-enable the same ruleset or protection immediately after verification.
6. Run `override off` to close the repair session and restore the normal local
   and remote authorization state.
7. Confirm the protected ref is back to a clean, valid state before resuming
   normal workflow.

This process must be explicit, logged, and temporary. Routine direct edits to
protected or script-managed branches remain blocked unless there is an explicit
server-side exception approved by repository administrators.
</details>

<details>
<summary><strong>5. Override Semantics</strong></summary>

## 5. Override Semantics

The `override` script is intentionally narrow in scope:

- `override` without `-r` is local clone-only recovery for exceptional local
  work in the current checkout.
- `override -r` records a clone-local authorization marker for an owner-admin
  remote repair workflow; it does not create server-side state.
- `override` does not bypass GitHub rulesets, server-side branch protection, or
  the repository scripts themselves.
- The override must be turned off after the repair window ends.

Local unrestricted mode and remote repair authorization are independent Git
configuration values in the clone. `override -r on` does not enable local
unrestricted mode. `override off` clears both values.

Prerequisites for `override`:

- The caller must be the repository owner as resolved from Git identity and
  repository metadata.
- The command must be run from a valid Git repository clone checked out to a
  normal local branch.
- The remote must be reachable within the configured timeout for remote repair.
- For remote repair mode, the caller must also have GitHub repository admin or
  organization admin authority.
</details>

<details>
<summary><strong>6. Internal Operational Notes</strong></summary>

## 6. Internal Operational Notes

- The public document set is intentionally written for contributor-facing use.
- The internal documents capture policy, enforcement, and repair details that are
  not meant to be treated as normal operations by all contributors.
- Server-side protections remain the final authority over branch deletion and
  history rewriting.
- Script-only invocation is a local guardrail; stronger identity enforcement would
  require a dedicated GitHub App or bot if direct ref updates must be attributed
  to a system identity rather than a user identity.

Keep this document aligned with the repository policy whenever workflows, rulesets,
or protected branch policy change.
</details>

<details>
<summary><strong>7. GitHub Validation Architecture</strong></summary>

## 7. GitHub Validation Architecture

GitHub validation has two operational layers:

1. Pull-request workflows reject invalid content, commit metadata, signatures,
  protected-file changes, and other policy violations before publication.
2. Protected-branch workflows verify and record pushes, tags, and other protected
  repository events after publication.

When changing validation behavior:

1. Put reusable checks in the appropriate helper rather than duplicating shell
  logic across workflow files.
2. Add or update the workflow under `.github/workflows/`.
3. Test the workflow on a contributor or targeted branch.
4. Update required checks and rulesets when the workflow name or protection role
  changes.
5. Update the Internal Reference when helper contracts, environment variables, or
  hook behavior change.

For implementation names and contracts, see
[Internal Helpers and Hooks](./Contributor_Internal_Reference.md#5-internal-helpers-and-hooks).
</details>
