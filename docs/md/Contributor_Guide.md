![Contributor Guide](/docs/branding/Contributor_Guide.png)

#### Version: v1.0.0

This document defines the contribution process, coding standards, documentation rules, versioning guidelines, branch management, and validation workflows for contributors, reviewers, and approvers.

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

This document is for contributors, reviewers, and approvers who need guidance 
on enhancing and maintaining briteTest.

For detailed script reference information, see the [Contributor_Reference.md](./Contributor_Reference.md).

For an in-depth analysis of the SCM system, see [SCM_REVIEW.md](../SCM_REVIEW.md).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;Document Version History</summary>

### Document Version History

| Version | Date | Comment | Author/Editor |
|----------|------|---------|---------------|
| v1.0.0 | 2026-07-09 | Initial verison. | Paul Sinclair |
</details><br>
</details>

<details>
<summary><strong>Table of Contents</strong></summary>

## Table of Contents

1. [Introduction](#1-introduction)<br>
   1.1. [Scripts (scripts/bin)](#11-scripts-scriptsbin)<br>

2. [Branching Model Overview](#2-branching-model-overview)<br>

3. [Validation Workflows](#3-validation-workflows)<br>
   3.1. [Workflow Summary Dashboard](#31-workflow-summary-dashboard)<br>
   3.2. [Primary Prevention Layer](#32-primary-prevention-layer)<br>
   3.3. [Secondary Audit Layer](#33-secondary-audit-layer)<br>
   3.4. [Handling Validation Failures](#34-handling-validation-failures)<br>

4. [Branch Management](#4-branch-management)<br>
   4.1. [Creating Branches](#41-creating-branches)<br>
   4.2. [Making Changes](#42-making-changes)<br>
   4.3. [Merge Remote Branch to Local Branch](#43-merge-remote-branch-to-local-branch)<br>
   4.4. [Removing (Deleting) Branches](#44-removing-deleting-branches)<br>
   4.5. [Git Hooks Infrastructure](#45-git-hooks-infrastructure)<br>
        4.5.1. [Automatic Setup](#451-automatic-setup)<br>
        4.5.2. [How Hooks Work](#452-how-hooks-work)<br>
        4.5.3. [Available Hooks](#453-available-hooks)<br>
      4.5.4. [How Enforcement Hooks Work](#454-how-enforcement-hooks-work)<br>
      4.5.5. [Script Bypass (Automatic)](#455-script-bypass-automatic)<br>
      4.5.6. [Workflow: Commit and Push Example](#456-workflow-commit-and-push-example)<br>
      4.5.7. [Identity Configuration](#457-identity-configuration)<br>
      4.5.8. [Troubleshooting Hooks](#458-troubleshooting-hooks)<br>

5. [Access Control & Roles](#5-access-control--roles)<br>
   5.1. [File Access Matrix](#51-file-access-matrix)<br>
   5.2. [Identity Prerequisites for Role-Gated Scripts](#52-identity-prerequisites-for-role-gated-scripts)<br>
   5.3. [Detailed Tier Access Levels](#53-detailed-tier-access-levels)<br>

6. [Public Repository Security](#6-public-repository-security)<br>

7. [GPG Signing](#7-gpg-signing)<br>
   7.1. [Linux Setup](#71-linux-setup)<br>
   7.2. [Windows Setup](#72-windows-setup)<br>
   7.3. [Signing Commits](#73-signing-commits)<br>
   7.4. [Troubleshooting GPG](#74-troubleshooting-gpg)<br>

8. [Versioning Guidelines](#8-versioning-guidelines)<br>

9. [Branding](#9-branding)<br>

10. [Documentation Guidelines](#10-documentation-guidelines)<br>

11. [Code Guidelines](#11-code-guidelines)<br>

12. [Testing Requirements](#12-testing-requirements)<br>

13. [CODEOWNERS and Review Routing](#13-codeowners-and-review-routing)<br>

14. [Making Modifications in a Branch](#14-making-modifications-in-a-branch)<br>

15. [Pull Request (PR)](#15-pull-request-pr)<br>
   15.1. [Pre-PR Checklist](#151-pre-pr-checklist)<br>
   15.2. [Opening and Reviewing](#152-opening-and-reviewing)<br>

16. [Release](#16-release)<br>

17. [Protected Branches](#17-protected-branches)<br>

18. [Troubleshooting FAQ](#18-troubleshooting-faq)<br>
   18.1. [Validation Failures](#181-validation-failures)<br>
   18.2. [Git Operations](#182-git-operations)<br>
   18.3. [Merge and Reviews](#183-merge-and-reviews)<br>

19. [Team Onboarding Checklist](#19-team-onboarding-checklist)<br>
   19.1. [Before First Commit](#191-before-first-commit)<br>
   19.2. [First Contribution](#192-first-contribution)<br>
   19.3. [Quick Reference](#193-quick-reference)<br>
   19.4. [Getting Help](#194-getting-help)<br>
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

This Contributor Guide defines the expectations and rules for contributing to briteTest. It covers branching, versioning, testing, documentation, code style, validation workflows, pull requests, and release requirements.

Contributors should read this document before submitting changes, reviewing, or approving to ensure consistency across the code and documentation.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;1.1. Scripts (scripts/bin)</summary>

### 1.1. Scripts (scripts/bin)

A script-based workflow is required. Direct use of git commands that modify the
repository is not allowed for users, contributors, reviewers, or approvers.
These roles must use project scripts for repository-modifying actions. A script validates the action, enforces policy, issues the git commands needed to complete
the action, generates informational output, and, for some scripts, a report. This
simplifies the workflow for contributors, reviewers, and approvers while
maintaining integrity in the repository.

For routine contributor work, use the scripts in `scripts/bin/` without any
special owner privileges. An owner may use the repository-owner override only in
exceptional local-repair scenarios, and any protected-remote recovery still
requires GitHub-side admin authority.

For the internal owner, ruleset, and remote-repair policy, see the
[Contributor_Internal_Guide.md](./Contributor_Internal_Guide.md). For detailed
script usage and repair script behavior, see the
[Contributor_Internal_Reference.md](./Contributor_Internal_Reference.md).

The current executable script set is maintained in `scripts/bin/README.md`.
After `setupclone`, run `bind -f ~/.inputrc` in an already-open terminal.
Then type a leading command prefix and press Tab to list choices; use
Alt+n and Alt+p to cycle forward and backward through those choices.

- **Setup/installation:** `setupclone`
- **Document/brand:** `ckstyle`, `gendocs`, `genpngs`, `replacephrases`, `updatebrand`
- **Repository/fork/clone:** `mkfork`, `mkclone`, `rmclone`, `fixrepo`
- **Branch/workflow:** `ckbranch_history`, `chcurrent`, `lsbranch`, `mkbranch`, `commit`, `copyfix`, `mkfeedback`, `mergetoparent`, `mkpullrequest`, `chtarget`, `mkrelease`, `syncfromremote`, `syncfromparent`, `undo`, `rmbranch`
- **Owner controls:** `override` (toggle repository-owner unrestricted mode for this clone); `override -r` (temporary remote repair authorization window for GitHub-side repair workflows)
</details>
</details>

<details>
<summary><strong>2. Branching Model Overview</strong></summary>

## 2. Branching Model Overview

This repository uses a release-oriented branching model with four branch types:

**Protected Branches** (Effectively read-only; no direct commits, force-push, or deletion):
- `main` - Production-ready code (remote-only; use `origin/main` for Git commands)
- `v<M>.<m>.0` - Version branches (e.g., v1.0.0, v2.1.0)

**Unprotected Branches** (Direct commits allowed, PRs optional):
- `dev/<desc>-<version>` or `fix/<desc>-<version>` - Targeted branches
- `[<type>/]<description>` - Contributor branches

**Valid Merge Up Paths:**
- contributor -> contributor (optional PR/review by contributors, `pushup` by the contributor)
- contributor -> targeted (optional PR/review by contributors, `pushup` by the contributor)
- targeted -> version (required approved PR for the current commit; `pushup`
  by the contributor, reviewer, or approver using that clone)
- targeted -> version with `pushup -o` (PR optional, repository owner only)
- version -> `origin/main` (no PR, `pushup` by an approver)
- main -> any (not allowed)

**Branch Presence Rules (Local/Remote):**
- `main`: remote-only by policy (`origin/main`). A local `main` branch is not required.
- `v<M>.<m>.0` version branches: remote branch required; local branch optional.
- targeted (`dev/...`, `fix/...`) branches: local and remote branches are required for merge workflows.
- contributor branches: local branch required; remote branch optional while developing,
  but required before remote-reviewed workflows (for example PR-required merge paths).

**Editing and Commit Policy:**
- Remote branches are read-only for editing in this workflow.
- To make changes, use a local branch.
- `commit` must be run from a local branch.
- A local branch may exist without a corresponding remote branch.
- Existing branches with policy-invalid names may be inspected with `chbranch`
  in read-only mode and removed with `rmbranch`; they cannot be used for edits
  or commits.

**Merge-Up Safety Preconditions (`pushup`):**
- remote must be connected/reachable.
- current local branch must be in sync with its remote when a remote branch exists.
- current branch must not be behind its parent.
- parent local/remote must be in sync when both parent refs exist.

**PR Requirements (`pushup` is authoritative):**
- A PR is required only for a targeted branch merged to a version branch
  without `-o`.
- The repository owner may use `pushup -o` for a targeted-to-version merge;
  that operation does not require a PR or approver role.
- PRs are optional for contributor-to-contributor,
  contributor-to-targeted, and version-to-main merges.
- If an optional PR exists, `pushup` still validates its state and approval.
- Approval applies to the current source commit. Any additional source commit
  requires review and approval again before `pushup`.

Role naming used in this guide is: users, contributors, reviewers, approvers,
and repository owner.

Repository owner role model:
- Protected operations (for example merge-up to protected branches and releases)
  are approver responsibilities.
- The repository owner is not required to be an approver.
- By default, the repository owner follows the role assigned in
  `config/contributors.md`.
- For scripts that support `-o`, repository owner may explicitly enable a
  temporary, operation-scoped override for that command run only.
- When the command exits, override is no longer active and normal role
  restrictions apply again.
- `override on/off` is separate from script `-o`: it controls local direct
  command restrictions enforced by hooks and similar local mechanisms.
</details>

<details>
<summary><strong>3. Validation Workflows</strong></summary>

## 3. Validation Workflows

GitHub Actions workflows provide validation and post-push auditing. GitHub
rulesets separately provide server-authoritative protection against deletion
and non-fast-forward updates of protected branches.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Workflow Summary Dashboard</summary>

### 3.1. Workflow Summary Dashboard

| Workflow | Purpose | Trigger | When Blocks |
|----------|---------|---------|------------|
| validate-pull-request.yml | Validates branch relationships, naming, roles | PR events | Invalid merge path |
| validate-merge.yml | Post-merge compliance audit logging | Push to protected | Audit trail only |
| validate-commit-message.yml | Enforces conventional commit format | PR events | Invalid format |
| validate-author.yml | Verifies approved commit authors | PR events | Unknown author |
| validate-gpg-signature.yml | Requires GPG signatures on protected branches | PR to main/version | Unsigned commits |
| validate-rebase.yml | Monitors rebase operations | Push events | Audit trail only |
| validate-force-push.yml | Audits force push attempts | Push events | Blocked by GitHub |
| validate-cherry-pick.yml | Detects cherry-pick operations | Push events | Cherry-pick to protected |
| validate-file-changes.yml | Prevents critical file modifications | PR events | LICENSE, workflows modified |
| validate-large-files.yml | Detects and blocks files > 10MB | Push events | File exceeds limit |
| validate-secrets.yml | Prevents API keys and credentials | PR events | Secrets detected |
| validate-workflow.yml | Validates GitHub workflow syntax | PR modifying workflows | Invalid syntax |
| validate-license-headers.yml | Ensures MIT license headers | PR events | Missing headers |
| validate-code-quality.yml | Runs linting and format checks | PR events | Formatting issues |
| validate-tags.yml | Validates tag naming conventions | Tag creation | Invalid tag format |
| validate-rulesets.yml | Verifies live protected-branch rulesets | Weekly/manual | Ruleset drift |
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Primary Prevention Layer</summary>

### 3.2. Primary Prevention Layer

Pull-request workflows run before a PR merge. `pushup` performs the authoritative
merge-path, role, and conditional PR checks for the script-based workflow:

PASS: **Valid commits:** Allowed to proceed
BLOCKED: **Invalid commits:** PR blocked until fixed

**Examples of blocked commits:**
- Merge with wrong branch path (contributor->main)
- Commit message format: "Add feature" (missing type: prefix)
- File modification: LICENSE
- Secret detected: AWS API key in code
- Large file: 15MB binary uploaded
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.3. Secondary Audit Layer</summary>

### 3.3. Secondary Audit Layer

These workflows run **AFTER merge up** for compliance logging:

**Purpose:** Audit trail, monitoring, compliance
**Note:** Cannot prevent already-merged up changes, but logs violations

**Examples of audited operations:**
- Rebase on version branch
- Force push attempt (blocked by GitHub anyway)
- Cherry-pick to non-protected branch
- Invalid tag creation
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.4. Handling Validation Failures</summary>

### 3.4. Handling Validation Failures

**When a validation fails:**

1. **Read error message** - Explains what's wrong and how to fix
2. **Fix locally** - Make the required changes
3. **Re-push** - GitHub automatically re-runs validations
4. **Verify passing** - Green checkmark on PR before requesting review
</details>
</details>

<details>
<summary><strong>4. Branch Management</strong></summary>

## 4. Branch Management

The following shows the path to the script but just the script name is needed
if the default path is setup for bash (this is normally done automatically;
use scripts/bin/setupclone to set the default path manually).

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.1. Creating Branches</summary>

### 4.1. Creating Branches

Changes are made in a targeted or contributor branch which you need
to create:

```bash
scripts/bin/mkbranch -r BRANCH [PARENTBRANCH]
```

BRANCH is the targeted or contributor branch to use for making
your changes.

PARENTBRANCH is the version, targeted, or contributor branch from which to
create the branch. If BRANCH is a targeted branch name, the default is the
version branchcorresponding to th e version in BRANCH; otherwise,
PARENTBRANCH must be specified.

**Examples:**
```bash
scripts/bin/mkbranch -r mywork/feature main
scripts/bin/mkbranch -r dev/parser-fix-v1.0.0 v1.0.0
scripts/bin/mkbranch -r fix/memory-leak-v1.0.0 v1.0.0
```

**Branch Naming Rules:**
- **Contributor:** `[<type>/]<description>` (e.g., `dev/json-parser`)
- **Targeted:** `dev/<desc>-<version>` or `fix/<desc>-<version>`
- **Version:** `v<M>.<m>.0` (created by approvers only)
- **Main**: `main`
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.2. Making Changes</summary>

### 4.2. Making Changes

```bash
scripts/bin/chcurrent BRANCH
# Edit files...
scripts/bin/commit -- Feature: add new capability.
```

BRANCH is the contributor branch or a targeted branch to use for making
changes.

**Commit Best Practices:**
- Keep commits focused and logical
- Use conventional commit format: `<type>: <description>`
- Suggested types: feature, fix, doc, style, refactor, cleanup, test
- Commit often

`scripts/bin/commit` behavior summary:
- Runs only on a local targeted or contributor branch.
- Does not push. Use `scripts/bin/push` to publish local commits to remote.
- Successful commits are available through `report`. Dry-run and error-run
  reports use `commit-d-<datetime>.md` and `commit-e-<datetime>.md`.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.3. Merge Remote Branch to Local Branch</summary>

### 4.3. Merge Remote Branch to Local Branch

Rebase a local branch to its remote has had changes. There must
not be any untracked or uncommitted changes for the local branch
(if there are, use the commit or undo scripts prior to the merge).

```bash
scripts/bin/chcurrent BRANCH
scripts/bin/mrgremote
```

BRANCH is the contributor branch or targeted branch to merge.

If no unsresolved conflicts, then done.

Otherwise, resolve conflicts (see merge remote report) and then repeat
above. Iterate this workflow until there are no more conflicts (in most
cases, conflicts are automatically resolved in one execution of mrgremote
or two executions of mrgremote if there unresolved conflicts).
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.4. Removing (Deleting) Branches</summary>

### 4.4. Removing (Deleting) Branches

```bash
scripts/bin/rmbranch BRANCH
```

BRANCH is the contributor branch or a targeted branch to remove.

Protected branches (`main` and `v*.0`) cannot be deleted.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.5. Git Hooks Infrastructure</summary>

### 4.5. Git Hooks Infrastructure

The repository uses Git hooks to automate configuration and validation during development. Hooks are versioned in the repository and automatically configured on clone and checkout operations.

#### 4.5.1. Automatic Setup

Hooks are automatically configured when you:
- Clone the repository for the first time
- Run `scripts/bin/setupclone` 
- Checkout branches

No manual setup is required. If hooks are not configured, you can manually run:

```bash
bash scripts/helpers/install_git_hooks.sh
```

#### 4.5.2. How Hooks Work

The repository uses Git's `core.hooksPath` configuration (Git 2.9+) to point to a versioned hooks directory instead of the traditional `.git/hooks/` approach. This means:

- **Hooks are tracked in version control** at `scripts/helpers/.githooks/`
- **Changes to hooks apply automatically** after pulling updates
- **Hooks run in consistent environments** across all clones and Codespaces
- **No copying or duplication** to `.git/hooks/` directories

Git hook entrypoints keep the canonical hook names (`pre-commit`, `pre-push`,
`pre-merge-commit`, `post-checkout`) because Git looks for those exact names.
Shared hook logic can use `.sh` suffixes, such as `githook_helper.sh`.

#### 4.5.3. Available Hooks

The repository uses four Git hooks to enforce the script-based workflow and configure development environment:

| Hook | Trigger | Purpose |
|------|---------|---------|
| **post-checkout** | After clone, branch checkout | Auto-configures git identity to match your GitHub login |
| **pre-commit** | Before `git add`/`git commit` | Enforces script-based commits via `commit` script |
| **pre-push** | Before `git push` | Enforces script-based push operations |
| **pre-merge-commit** | Before `git merge` | Enforces script-based merge operations |

#### 4.5.4. How Enforcement Hooks Work

The enforcement hooks (pre-commit, pre-push, pre-merge-commit) prevent direct Git commands and require you to use the appropriate briteTest script instead:

Hooks are local workflow guardrails, not an authorization boundary. A user who
controls the local Git process can disable hooks, use `--no-verify`, or set the
internal bypass environment variable. Server-side GitHub rulesets remain the
authoritative protection for protected remote refs.

**Example: Attempting direct commit (blocked)**
```bash
$ git add file.txt
$ git commit -m "my change"

[ERROR] Direct git add/commit/rm operations are not allowed.

   Use the 'commit' script instead:
   
     commit -c "Your commit message"
     commit -- Your commit message
   
   For help:
     commit -h
```

**Why this protection?**
- [OK] Ensures all changes go through validated scripts
- [OK] Maintains consistent commit history and metadata
- [OK] Prevents accidental commits to protected branches
- [OK] Enables audit trails and compliance logging
- [OK] Blocks commits from detached read-only checkouts, even when the normal
  script bypass environment variable is present

#### 4.5.5. Script Bypass (Automatic)

Scripts automatically bypass hook enforcement by setting an environment variable:

```bash
# When you run:
commit -c "my change"

# The script internally does:
env GIT_BYPASS_HOOKS=true git add <files>
env GIT_BYPASS_HOOKS=true git commit -m "my change"
```

This is transparent - you don't need to do anything. The script handles the details.
The bypass is an implementation mechanism, not proof that a caller is
authorized; each public script must perform its own policy and role checks.

#### 4.5.6. Workflow: Commit and Push Example

**Direct approach (blocked):**
```bash
git add file.txt
git commit -m "fix typo"     # [ERROR] BLOCKED by pre-commit hook
git push origin branch       # [ERROR] BLOCKED by pre-push hook
```

**Correct approach (using scripts):**
```bash
commit -c "fix typo"         # [OK] Uses commit script
push                          # [OK] Publishes local commits to remote
```

#### 4.5.7. Identity Configuration

When you clone or checkout a branch, the post-checkout hook automatically:

```bash
# Sets local git config to match your GitHub login
git config --local user.name "paulsinclair51"

# Ensures core.hooksPath is configured
git config core.hooksPath scripts/helpers/.githooks
```

This happens transparently - you don't see the hook running, but your git identity is automatically correct.

#### 4.5.8. Troubleshooting Hooks

If you suspect hooks aren't working:

```bash
# Check if core.hooksPath is configured
git config core.hooksPath

# Manually reconfigure hooks
bash scripts/helpers/install_git_hooks.sh

# Verify your git identity
git config --local user.name
git config --local user.email
```

If git identity is wrong, you can correct it manually:

```bash
git config --local user.name "your-github-login"
git config --local user.email "your-email@example.com"
```
</details>
</details>

<details>
<summary><strong>5. Access Control & Roles</strong></summary>

## 5. Access Control & Roles

briteTest uses a six-tier access model for public repository safety:

| Tier | Core Capabilities | Restrictions |
|------|-------------------|--------------| 
| **PUBLIC** | Read, clone, fork | No write access |
| **USERS** (read-only collaborator) | Read all repository content | No push, PR, or script execution |
| **CONTRIBUTOR (C)** | Create branches, commit, open PRs, run contributor scripts | Cannot merge/release/protected-script operations |
| **REVIEWER (R)** | All contributor actions plus review/rebase workflows | Cannot run approver-only scripts |
| **APPROVER (A)** | Merge, release, run protected scripts with override confirmation | Must follow audit and override controls |
| **REPOSITORY OWNER (O)** | Repository admin and access management | Responsible for governance and audits |

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.1. File Access Matrix</summary>

### 5.1. File Access Matrix
| `docs/md/`, `docs/branding/`, `src/`, `include/`, `examples/` | R | R | RW | RW | RW | RW |
| `scripts/bin/`, `scripts/helpers/` | R | R | RW | RW | RW* | RW |
| `.github/workflows/`, branch-protection settings | R | R | - | - | RW* | RW |
| `config/contributors.md`, governance/policy docs | R | R | RW | RW | RW* | RW |

**Write access is script-controlled** (`mkbranch`, `commit`, `mkpullrequest`, `mergetoparent`, `chtarget`, `mkrelease`) rather than direct protected-branch git operations.
Direct user git commands that modify repository state are blocked by hooks for
users, contributors, reviewers, and approvers.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.2. Identity Prerequisites for Role-Gated Scripts</summary>

### 5.2. Identity Prerequisites for Role-Gated Scripts

Role-gated scripts (for example `mergetoparent` and `mkrelease`) require a
resolvable GitHub login that matches an entry in `config/contributors.md`.

Configure at least one of these identity sources:

- `GITHUB_ACTOR` set to your GitHub login
- `gh auth login` completed in your environment
- `git config user.name <github-login>` using your GitHub login (not display name)

If identity cannot be resolved, role checks fail by design.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;5.3. Detailed Tier Access Levels</summary>

### 5.3. Detailed Tier Access Levels

#### PUBLIC (Unauthenticated Users)

**Who:** Anyone on the Internet

**Read Access:**
- README, public documentation, source code, examples, LICENSE
- Clone and fork the repository

**Cannot:**
- Push changes, submit PRs, execute scripts
- Access internal/private documentation

#### USERS (Read-Only Collaborators)

**Who:** Invited collaborators with read-only access

**Read Access:**
- All public content
- Private documentation (if granted)
- All repository files

**Cannot:**
- Push changes, submit PRs to main repo
- Execute briteTest scripts
- Modify any files

#### CONTRIBUTOR (C)

**Who:** Active contributors who can submit work for review

**Can:**
- Create feature branches from main/version branches
- Create commits and sign them
- Submit pull requests for review
- Run contributor-tier scripts (`mkbranch`, `commit`, `copyfix`, `mrgbranch`, etc.)
- Cherry-pick fixes between branches
- Access all scripts/code for reading

**Cannot:**
- Merge directly to main or version branches outside the approved `pushup`
  workflow
- Create releases
- Run approver-only `pushup` paths such as version-to-main
- Run other approver-only scripts (`release`, `fixrepo`)
- Modify workflow/security configuration

#### REVIEWER (R)

**Who:** Experienced contributors who provide code review feedback

**Inherits:** All Contributor capabilities

**Additional:**
- Provide feedback and approve/request changes on PRs
- Rebase branches and update pull requests
- Run reviewer-tier scripts (`feedback`, `review`)
- Check code style compliance (`ckstyle`)

**Cannot:**
- Merge to protected branches without an approved current source commit
- Create releases
- Run approver-only `pushup` paths or other approver-only scripts

#### APPROVER (A)

**Who:** Approvers responsible for merges, releases, and protected operations

**Inherits:** All Reviewer and Contributor capabilities

**Additional:**
- Merge PRs to main and version branches
- Create official releases and version tags
- Run approver-only `pushup` paths and other approver-only scripts (`release`,
  `fixrepo`, `rebrand`, `replacetext`)
- Modify repository configuration (with override)

**Requirements:**
- Protected scripts require explicit `SCRIPT_OVERRIDE_CONFIRMED=true` confirmation
- Must follow audit trail and approval controls
- Responsible for release integrity and repository governance

#### REPOSITORY OWNER (O)

**Who:** Repository owner

**Access:**
- Full administrative access to all repository settings
- Add/remove collaborators and change access levels
- Modify branch protection rules
- Change repository configuration and secrets

**Script Policy Behavior:**
- Repository owner is not automatically treated as approver.
- Repository owner follows the role assigned in `config/contributors.md`
  unless an explicit owner override is requested.
- In scripts that support `-o`, owner override is temporary and applies only
  to that command invocation.

---
</details>
</details>

<details>
<summary><strong>6. Public Repository Security</strong></summary>

## 6. Public Repository Security

Security controls expected for contributor workflows:

- **Branch protection:** GitHub rulesets prevent deletion and
  non-fast-forward updates of `main` and `v<M>.<m>.0` branches.
- **Merge policy:** `pushup` enforces merge paths, roles, synchronization, and
  the targeted-to-version PR requirement. GitHub rulesets cannot express that
  source/target-dependent PR rule without breaking allowed version-to-main
  and repository-owner override operations.
- **Configuration drift:** `validate-rulesets.yml` compares live rulesets with
  `scripts/bin/setup_rulesets --check` each week and on manual request.
- **Ruleset credentials:** configure the repository Actions secret
  `RULESET_ADMIN_TOKEN` with permission to read repository administration
  rules. Apply changes with an admin-authenticated
  `scripts/bin/setup_rulesets`; the default Actions token is insufficient.
- **Secret prevention:** never commit credentials, tokens, or keys; use repository
  secret scanning  and validation workflows.
- **Critical file protection:** avoid direct changes to protected areas
  (`.github/workflows/`, policy/security files) unless explicitly required and approved.
- **Signed provenance:** use GPG signing for protected-branch commits.
- **Vulnerability reporting:** report security concerns via the repository
  security policy (`.github/SECURITY.md`) rather than public issue disclosure.
- **Auditability:** approver-level actions and protected operations must remain
   traceable through workflow/script logs.

GitHub cannot distinguish a user running `pushup` from the same user issuing an
equivalent direct Git push. Consequently, script-only invocation is enforced
locally as a guardrail and monitored by push workflows; deletion and history
rewrite restrictions are the server-authoritative controls. The repository owner
is not exempt from direct-edit restrictions: the ruleset is configured without a
bypass actor, and direct mutation of protected or script-managed branches must
use the repository workflow rather than GitHub.com editing. A local
`override on` mode is a narrow recovery aid for exceptional local admin work in
a clone, not an authorization to perform routine direct edits to protected or
script-managed branches. Remote repair of protected refs or repository state
must be performed through GitHub admin controls or an explicit server-side
exception, not through a local clone-only override. Stronger script-identity
enforcement would require a dedicated GitHub App or bot to be the only
identity permitted to update protected refs.

Keep this section aligned with repository policy whenever workflows or branch protections change.
</details>

<details>
<summary><strong>7. GPG Signing Setup</strong></summary>

## 7. GPG Signing Setup

For commits to protected branches (main and version branches), GPG signatures are required.

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;7.1. Linux/Mac Setup</summary>

### 7.1. Linux/Mac Setup

**1. Generate GPG Key**

```bash
gpg --gen-key
```

Respond to prompts:
- Kind: RSA and RSA (default)
- Size: 4096 bits (recommended)
- Valid for: 2y (or as desired)
- Name: Your name
- Email: Your GitHub email
- Comment: (optional)

**2. List Your Keys**

```bash
gpg --list-secret-keys --keyid-format=long
```

Output looks like:
```
sec   rsa4096/3AA5C34371567BD2 2016-03-10 [SC] [expires: 2017-03-10]
      27D6D3E4F2B0D16F
uid                 [ultimate] Hubot <hubot@example.com>
ssb   rsa4096/42B6315D7637C87E 2016-03-10 [E] [expires: 2017-03-10]
```

Your key ID is after `rsa4096/` - in this example: `3AA5C34371567BD2`

**3. Configure Git**

```bash
# Set key ID for all commits
git config --global user.signingkey 3AA5C34371567BD2

# Sign commits by default
git config --global commit.gpgsign true
```

**4. Add to GitHub**

```bash
# Export public key
gpg --armor --export 3AA5C34371567BD2
```

Copy the output and add to GitHub:
- Go to Settings -> SSH and GPG keys
- Click "New GPG key"
- Paste the key
- Confirm
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;7.2. Windows Setup</summary>

### 7.2. Windows Setup

**1. Install GPG**

Download from https://www.gnupg.org/download/

**2. Generate Key**

Use Windows PowerShell:
```powershell
gpg --gen-key
```

Follow same steps as Linux/Mac (above)

**3. Configure Git**

Tell Git to use gpg.exe:
```powershell
git config --global gpg.program "C:\Program Files (x86)\GNU\GnuPG\bin\gpg.exe"
git config --global user.signingkey <YOUR_KEY_ID>
git config --global commit.gpgsign true
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;7.3. Signing Commits</summary>

### 7.3. Signing Commits

Once configured, commits are automatically signed:

```bash
git commit -m "feat: add feature"  # Automatically signed
```

Or sign manually:

```bash
git commit -S -m "feat: add feature"
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;7.4. Troubleshooting GPG</summary>

### 7.4. Troubleshooting GPG

**Error: "gpg failed to sign"

Try:
```bash
# Reload GPG agent
gpg-connect-agent updatestartuptty /bye

# Or restart agent
killall gpg-agent
```

**Key not found**

Verify key exists:
```bash
gpg --list-secret-keys
```

**GitHub doesn't show verified badge**

- Verify public key is added to GitHub
- Verify commit email matches GitHub account email
- Wait a few seconds (GitHub takes time to verify)
</details>
</details>

<details>
<summary><strong>8. Versioning Guidelines</strong></summary>

## 8. Versioning Guidelines

Versioning format: `M.m.p` (major, minor, patch)

- **Patch (e.g., 1.0.1):** Bug fixes, improvements, doc corrections
- **Minor (e.g., 1.1.0):** New features, backward compatible
- **Major (e.g., 2.0.0):** Breaking changes, incompatibilities

**Versioned files:**
- `include/runnerapi.h`, `src/runnerapi.c`
- `include/testapi.h`, `src/testapi.c`
- `docs/md/*.md` (except README.md)

Use `make test-all-scripts` before PRs, and verify versioned file edits in `git diff`.
</details>

<details>
<summary><strong>9. Branding</strong></summary>

## 9. Branding

- **Brand name:** briteTest
- **Distinctive camelCase** aligns with `bT` monogram
- Update branding with: `scripts/bin/updatebrand`
</details>

<details>
<summary><strong>10. Documentation Guidelines</strong></summary>

## 10. Documentation Guidelines

- Root `README.md` remains short and onboarding-focused
- Technical tone: precise, neutral, clear
- Use backticks for code identifiers
- Use fenced code blocks for examples
- Maintain parallel structure in lists
- Define terms once, use consistently
</details>

<details>
<summary><strong>11. Code Guidelines</strong></summary>

## 11. Code Guidelines

- C99 standard
- POSIX.1-2001 APIs only
- Keep headers self-contained
- Add MIT license header to new files
</details>

<details>
<summary><strong>12. Testing Requirements</strong></summary>

## 12. Testing Requirements

```bash
make run
```

- Ensure all tests pass before opening PR
- Update tests when code changes
- Include test coverage for new features
</details>

<details>
<summary><strong>13. CODEOWNERS and Review Routing</strong></summary>

## 13. CODEOWNERS and Review Routing

- **Default owner:** `paulsinclair51`
- CODEOWNERS affects who is **requested** for review
- CODEOWNERS does **not** block merges alone
- Blocking depends on branch protection rules

See `.github/CODEOWNERS` for details.
</details>

<details>
<summary><strong>14. Making Modifications in a Branch</strong></summary>

## 14. Making Modifications in a Branch

1. Create focused, logically grouped changes
2. Update documentation in parallel with code
3. Update version numbers in versioned files
4. Follow code and documentation guidelines
5. Include test coverage
6. Verify tests pass: `make run`
</details>

<details>
<summary><strong>15. Pull Request (PR)</strong></summary>

## 15. Pull Request (PR)

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;15.1. Pre-PR Checklist</summary>

### 15.1. Pre-PR Checklist

- [ ] Changes are focused and logically grouped
- [ ] Documentation updated
- [ ] Version numbers updated (if needed)
- [ ] License headers on new files
- [ ] Tests pass: `make run`
- [ ] Commits follow conventional format
- [ ] No secrets or credentials
- [ ] No files > 10MB
- [ ] No protected file modifications
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;15.2. Opening and Reviewing</summary>

### 15.2. Opening and Reviewing

1. Commit and push your branch updates.
2. Create a draft PR (or update the existing draft PR): `review`.
3. Optionally set or update title/labels while in draft: `review -T "WIP: ..." -l "..."`.
4. Start formal review when ready: `review -s` (converts draft to ready when needed).
5. GitHub runs validation workflows automatically.
6. Respond to feedback with `feedback view`, `feedback respond`, and `feedback resolve`.
7. Push follow-up fixes and run `review -s` again only if review requests must be refreshed.
8. Once approved and checks pass, approver merges.
</details>
</details>

<details>
<summary><strong>16. Release</strong></summary>

## 16. Release

1. **Prepare:** Summary of changes, verify versions, ensure compatibility
2. **Validate:** `make run`, check for stale references
3. **Commit:** Clear message with version updates and release notes
4. **Tag:** `git tag v1.2.3` and push
5. **Publish:** Create GitHub release with notes
</details>

<details>
<summary><strong>17. Protected Branches</strong></summary>

## 17. Protected Branches

Protected branches require:
- prohibited: direct commits and direct edits in GitHub.com
- accidental local modify/rename/delete changes must be undone before
  continuing workflows that require a clean branch
- prohibited by GitHub ruleset: non-fast-forward updates
- prohibited by GitHub ruleset: deletions
- required by `pushup`: approved PR for targeted-to-version merges without `-o`
- optional PR: version-to-main merges and owner `pushup -o` merges

The protected base branch is `origin/main`; version branches are local protected branches.
Neither may receive direct commits or direct GitHub.com edits.
Updates are made through `scripts/bin/pushup` only:

- Use `scripts/bin/pulldown` first if the source is behind its parent.
- Resolve source conflicts before running `pushup`.
- `pushup` validates policy, prepares and publishes the parent, returns to the
  source, merges the published parent down, and publishes the source.
- Before parent publication, a failure restores the original local branch tips.
- After parent publication, a failure writes a `pushup-e` report describing
  completed and pending steps. Address its guidance and run
  `pushup --continue`.
- For targeted-to-version push-up workflows, run `pushup` only after the current
  source commit is approved. Any additional source commit requires approval
  again.
- If another user publishes the same parent first, `pushup` rejects its stale
  publication attempt without overwriting remote history.
- Version-to-main remains approver-only. The repository owner may use the
  targeted-to-version `pushup -o` override without a PR.
- The owner override only authorizes the merge workflow; it does not permit direct
  editing of protected or script-managed branches in GitHub.com.
- A separate local `override on` recovery mode is reserved for exceptional
  repository-repair or maintenance work, not for routine direct branch changes.

</details>

<details>
<summary><strong>18. Troubleshooting FAQ</strong></summary>

## 18. Troubleshooting FAQ

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;18.1. Validation Failures</summary>

### 18.1. Validation Failures

**Q: "Commit message format is invalid"

**A:** Use conventional format: `<type>: <description>`
```bash
# Wrong
git commit -m "Add new feature"

# Correct
git commit -m "feat: add new feature"
```

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;18.2. Git Operations</summary>

### 18.2. Git Operations

**Q: "File size exceeds 10MB"

**A:** Don't commit large binary files. Use Git LFS instead:
```bash
# Install Git LFS
git lfs install

# Track large files
git lfs track "*.bin"
git add .gitattributes
```

**Q: "Protected file cannot be modified"

**A:** Don't modify LICENSE, SECURITY.md, or .github/workflows/ unless approved.
For legitimate changes, contact the repository owner.

**A:** Remove credentials immediately:
```bash
# Remove the file from history
git filter-repo --path <file> --invert-paths

# Rotate/regenerate the credential
# (password, API key, token, etc.)
```

**Q: "License headers missing"

**A:** Add MIT license header to new source files:
```c
// Copyright (c) 2026 Paul Sinclair
// SPDX-License-Identifier: MIT
```

**Q: "I accidentally committed to main"

**A:** Don't panic. Contact repository owner. Main is protected so direct commits should fail.

**Q: "Role-gated script says it cannot determine GitHub login identity"

**A:** Configure one of the supported identity sources:
```bash
# Option 1: Environment identity
export GITHUB_ACTOR=<your-github-login>

# Option 2: GitHub CLI authentication
gh auth login

# Option 3: Git identity mapped to GitHub login
git config user.name <your-github-login>
```

**Q: "How do I undo the last commit?"

**A:** If not pushed:
```bash
git reset --soft HEAD~1  # Keep changes
git reset --hard HEAD~1  # Discard changes
```

**Q: "How do I update my branch with latest main?"

**A:**
```bash
git fetch origin
git rebase origin/main
git push --force-with-lease origin <branch>
```

**Q: "Can I delete a branch?"

**A:** Use the safe deletion script:
```bash
scripts/bin/rmbranch <branch_name>
```

Protected branches (main, v*.0) cannot be deleted.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;18.3. Merge and Reviews</summary>

### 18.3. Merge and Reviews

**Q: "PR is blocked by validation checks"

**A:** Look at the failing check:
1. Click on the red X next to the workflow
2. Read the error message
3. Fix locally
4. Re-push (validation runs automatically)

**Q: "Reviewer requested changes, what do I do?"

**A:**
1. Read the review comments
2. Make the requested changes
3. Commit and push
4. Comment: "Updated. Ready for re-review."
5. Re-request review

**Q: "My PR has been merged, how do I get local changes?"

**A:**
```bash
git fetch origin
git pull origin main  # or version branch
```
</details>
</details>

<details>
<summary><strong>19. Team Onboarding Checklist</strong></summary>

## 19. Team Onboarding Checklist

For new contributors to briteTest:

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;19.1. Before First Commit</summary>

### 19.1. Before First Commit

**Clone using mkclone (recommended method):**

`mkclone` is the only way to properly set up a new clone because it automatically handles setup tasks:

- [ ] **Clone the repository using mkclone** (from anywhere on your system)
  ```bash
  # Create clone with default directory name (BriteTest/)
  mkclone

  # Or specify a custom directory name
  mkclone my-britetest-workspace

  # mkclone automatically:
  # - Clones the repository
  # - Runs setupclone to make scripts executable
  # - Adds scripts to your PATH
  # - Configures Git hooks via core.hooksPath
  ```

- [ ] **Enter the repository directory**
  ```bash
  cd BriteTest  # or your custom directory name
  ```

- [ ] **Verify Git hooks are installed**
  ```bash
  git config core.hooksPath
  # Should output: scripts/helpers/.githooks
  ```

**Manual setup (if you prefer `git clone`):**

If you clone manually instead of using `mkclone`:

- [ ] **Clone the repository**
  ```bash
  git clone https://github.com/paulsinclair51/briteTest.git
  cd briteTest
  ```

- [ ] **Run setupclone to complete setup**
  ```bash
  bash scripts/bin/setupclone
  # Handles: chmod +x, PATH setup, Git hooks configuration
  ```

- [ ] **Reload your shell to activate PATH changes**
  ```bash
  source ~/.bashrc  # or ~/.zshrc for Mac
  ```

**Configure Git identity (required for role-gated scripts):**

- [ ] **Set Git user.name to your GitHub login** (must match `config/contributors.md`)
  ```bash
  git config user.name "your-github-login"
  git config user.email "your.email@example.com"
  ```

- [ ] **Authenticate GitHub CLI** (recommended for scripts that check roles)
  ```bash
  gh auth login
  ```

- [ ] **Set up GPG signing** (see [GPG Signing Setup](#7-gpg-signing-setup) section)

- [ ] **Verify Git configuration**
  ```bash
  git config --local --list
  ```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;19.2. First Contribution</summary>

### 19.2. First Contribution
  ```bash
  scripts/bin/mkbranch -r mywork/description main
  ```
- Make changes
  ```bash
  git checkout mywork/description
  # Edit files...
  ```
- Test locally
  ```bash
  make run  # Ensure all tests pass
  ```
- [ ] **Check branch naming**
  ```bash
  bash scripts/helpers/ckbranchname.sh mywork/description
  # Should return exit code 4 (contributor branch)
  ```
- [ ] **Commit with conventional format**
  ```bash
  git add .
  git commit -m "feat: add new feature"
  # Will be GPG signed automatically
  ```
- [ ] **Push your branch**
  ```bash
  git push origin mywork/description
  ```
- [ ] **Open a Pull Request on GitHub**
  - Run `review` to create/update the draft PR for your current branch
  - Use `review -T "..." -l "..."` to refine title/labels while drafting
- [ ] **Start review when ready**
  - Run `review -s` to create a non-draft PR or convert the current draft PR
  - Optionally run `review -b` to open the PR in GitHub UI
- [ ] **Wait for validation**
  - GitHub runs 15+ workflows automatically
  - All should pass with green checkmarks
  - If any fail, fix locally and re-push
- [ ] **Request review**
  - `review -s` requests review from configured reviewers/approvers
- [ ] **Respond to feedback**
  - Read review comments: `feedback view`
  - Reply to comments: `feedback respond -i <id> -c "..."`
  - Resolve addressed threads: `feedback resolve -i <id>`
  - Make requested changes, commit, and re-push
- [ ] **Celebrate merge**
  - Once approved and checks pass, approver merges
  - Your contribution is now in the codebase!
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;19.3. Quick Reference</summary>

### 19.3. Quick Reference

Common commands:
```bash
# Create branch
scripts/bin/mkbranch -r mywork/feature main

# Switch to branch
git checkout mywork/feature

# Make changes and commit
git add .
git commit -m "feat: description"

# Push to GitHub
git push origin mywork/feature

# Validate branch name
bash scripts/helpers/ckbranchname.sh mywork/feature

# Run tests
make run

# Delete branch
scripts/bin/rmbranch mywork/feature
```
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;19.4. Getting Help</summary>

### 19.4. Getting Help

- **This guide:** `docs/md/Contributor_Guide.md`
- **Script reference:** `docs/md/Contributor_Reference.md`
- **SCM deep dive:** `docs/SCM_REVIEW.md`
- **Issue:** Open an issue on GitHub
- **Question:** Start a discussion on GitHub Discussions
</details>
</details>

<details>
<summary><strong>Related Documents</strong></summary>

## Related Documents

- [Contributor_Reference.md](./Contributor_Reference.md) - Script reference and tools
- [SCM_REVIEW.md](../SCM_REVIEW.md) - Detailed SCM system analysis
- [README.md](../../README.md) - Project overview
</details>

