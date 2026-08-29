![Contributor Guide](/docs/branding/Contributor_Guide.png)

#### Version: v1.0.0

This guide explains how contributors, reviewers, and approvers prepare, test,
review, and publish changes to the repository.

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

This document is the task-oriented guide for routine contribution work.

- For command options and exit statuses, see
  [Contributor_Reference.md](./Contributor_Reference.md).
- For internal source-control policy and repair procedures, see
  [Contributor_Internal_Guide.md](./Contributor_Internal_Guide.md).
- For internal command details, see
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

1. [Introduction](#1-introduction)<br>
2. [Start Here](#2-start-here)<br>
   2.1. [Set Up Your Clone](#21-set-up-your-clone)<br>
   2.2. [Make Your First Contribution](#22-make-your-first-contribution)<br>
3. [Daily Contribution Workflow](#3-daily-contribution-workflow)<br>
   3.1. [Create or Select a Branch](#31-create-or-select-a-branch)<br>
   3.2. [Edit, Test, Commit, and Push](#32-edit-test-commit-and-push)<br>
   3.3. [Keep Your Branch Current](#33-keep-your-branch-current)<br>
   3.4. [Undo a Change](#34-undo-a-change)<br>
4. [Pull Requests and Feedback](#4-pull-requests-and-feedback)<br>
   4.1. [Prepare a Pull Request](#41-prepare-a-pull-request)<br>
   4.2. [Open and Update a Pull Request](#42-open-and-update-a-pull-request)<br>
   4.3. [Review and Approval](#43-review-and-approval)<br>
   4.4. [Push Up an Approved Change](#44-push-up-an-approved-change)<br>
5. [Branches and Permissions](#5-branches-and-permissions)<br>
6. [Quality Requirements](#6-quality-requirements)<br>
7. [Signing Commits](#7-signing-commits)<br>
8. [Protected Branches and Releases](#8-protected-branches-and-releases)<br>
9. [Validation and Local Safeguards](#9-validation-and-local-safeguards)<br>
10. [Troubleshooting and Help](#10-troubleshooting-and-help)<br>
    10.1. [Common Problems](#101-common-problems)<br>
    10.2. [Interrupted Pushup](#102-interrupted-pushup)<br>
    10.3. [Getting Help](#103-getting-help)<br>
</details>

<details>
<summary><strong>1. Introduction</strong></summary>

## 1. Introduction

The repository provides commands in `briteRepo/bin/` to perform repository-changing
actions. Contributors, reviewers, and approvers must use these commands instead
of direct Git commands for branch modification operations.

The commands validate each action, enforce repository policy, and
provide recovery guidance. After `setupclone`, the commands are normally
available by name. You may also run them by path, such as
`briteRepo/bin/commit`.

| Task | Command |
|------|---------|
| Create or select a branch | `mkbranch`, `chbranch` |
| Commit and publish changes | `commit`, `push` |
| Update from the branch's remote copy | `pull` |
| Pull parent changes down | `pulldown` |
| Create or update a pull request | `review` |
| Read and respond to feedback | `feedback` |
| Push changes up to a parent branch | `pushup` |
| Undo recent work | `undo` |

Run any command with `-h` for current usage, prerequisites, and exit statuses.
</details>

<details>
<summary><strong>2. Start Here</strong></summary>

## 2. Start Here

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.1. Set Up Your Clone</summary>

### 2.1. Set Up Your Clone

1. Create the clone with `mkclone`. It configures the commands and local
   safeguards required by the workflow.
2. Enter the new repository directory.
3. Authenticate the GitHub CLI with `gh auth login`.
4. Confirm that your GitHub login appears in `config/contributors.md`.
5. Configure commit signing as described in
   [Signing Commits](#7-signing-commits).

If you already have a clone, run `setupclone` to configure it.

To create a repository that uses these commands, or to add the canonical
layout to a repository you already own, run `mkrepo <repository>`.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;2.2. Make Your First Contribution</summary>

### 2.2. Make Your First Contribution

1. Create your targeted work branch and its remote copy:

   ```bash
  mkbranch -r dev/description-v1.0.0 v1.0.0
   ```

2. Edit the files and run the relevant tests. To run the complete suite:

   ```bash
   make run
   ```

3. Commit and push the change:

   ```bash
   commit -- Add the new capability.
   push
   ```

4. Create a draft pull request with `review`.
5. Run `review -s` when it is ready for formal review.
6. Address comments with `feedback view`, `feedback respond`, and
   `feedback resolve`. Use `commit` and `push` for each revision.
7. After approval, the authorized contributor runs `pushup` to push the
  approved change up to its parent branch.
</details>
</details>

<details>
<summary><strong>3. Daily Contribution Workflow</strong></summary>

## 3. Daily Contribution Workflow

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.1. Create or Select a Branch</summary>

### 3.1. Create or Select a Branch

```bash
mkbranch -r BRANCH PARENTBRANCH
chbranch BRANCH
```

Examples:

```bash
mkbranch -r mywork/feature main
mkbranch -r dev/parser-fix-v1.0.0 v1.0.0
mkbranch -r fix/memory-leak-v1.0.0 v1.0.0
```

Use `lsbranch` to inspect branches. Use `rmbranch BRANCH` to remove an
unneeded branch. Protected branches cannot be removed.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.2. Edit, Test, Commit, and Push</summary>

### 3.2. Edit, Test, Commit, and Push

1. Keep each change focused and update tests and documentation with the code.
2. Run the tests relevant to the change.
3. Commit and push:

   ```bash
   commit -- Describe the change.
   push
   ```

`commit` stages and commits all current changes. Do not run `git add` or
`git commit`. `push` publishes local commits. Do not run `git push`.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.3. Keep Your Branch Current</summary>

### 3.3. Keep Your Branch Current

- Run `pull` when the remote copy of the current branch has newer changes.
- Run `pulldown` when the parent branch has newer changes that must be pulled
  down into the current branch.

Both commands require a clean working tree. If a conflict cannot be resolved
automatically, follow the command's report, resolve the files, and rerun it.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;3.4. Undo a Change</summary>

### 3.4. Undo a Change

```bash
undo                 # Undo uncommitted changes.
undo commit          # Undo the latest local commit and keep its changes.
undo pull            # Undo the latest pull.
undo pulldown        # Undo the latest pull down.
```

Run `undo -h` before using other modes. Do not use direct reset commands.
</details>
</details>

<details>
<summary><strong>4. Pull Requests and Feedback</strong></summary>

## 4. Pull Requests and Feedback

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.1. Prepare a Pull Request</summary>

### 4.1. Prepare a Pull Request

- [ ] The change is focused and logically grouped.
- [ ] Relevant documentation and tests are updated.
- [ ] Relevant tests pass.
- [ ] New source files contain the MIT license header.
- [ ] No credentials, tokens, keys, or files larger than 10 MB are included.
- [ ] Versioned files are updated when required.
- [ ] The branch is current with its remote copy and parent branch.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.2. Open and Update a Pull Request</summary>

### 4.2. Open and Update a Pull Request

1. Run `review` to create or update a draft pull request.
2. Optionally set its title and labels with
   `review -T "Title" -l "label"`.
3. Run `review -s` when it is ready for formal review.
4. Optionally run `review -b` to open it in a browser.

Correct failed checks locally, then run `commit` and `push` again.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.3. Review and Approval</summary>

### 4.3. Review and Approval

Use `feedback view`, `feedback respond -i ID -c "Response"`, and
`feedback resolve -i ID` throughout review. Reviewers and approvers use
`feedback approve` or `feedback disapprove` for approval decisions.

Approval applies to the current source commit. A later commit requires review
and approval again. Only one approved pull request may wait to push up to a
given parent branch. `feedback approve` refuses another approval until the
earlier pull request has completed `pushup` or is no longer approved.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;4.4. Push Up an Approved Change</summary>

### 4.4. Push Up an Approved Change

Run `pushup` from the source branch. It determines the parent branch, validates
the path and permissions, checks any required approval, publishes the parent,
then pulls the published parent changes down into the source branch.

If the source is behind its parent, run `pulldown` first. For interruption
recovery, see [Interrupted Pushup](#102-interrupted-pushup).
</details>
</details>

<details>
<summary><strong>5. Branches and Permissions</strong></summary>

## 5. Branches and Permissions

Create routine work on a contributor branch. Use a targeted `dev/` or `fix/`
branch when the work belongs to a specific version. Do not work directly on
`main` or a version branch.

The parent branch and your repository permission determine whether `pushup`
requires a pull request and approval. If a command reports that your branch,
permission, or destination is not allowed, do not bypass it; select the correct
branch or ask an approver for help.

For exact branch patterns, allowed push-up paths, roles, and path permissions,
see [Branch and Permission Reference](./Contributor_Reference.md#2-branch-and-permission-reference).
</details>

<details>
<summary><strong>6. Quality Requirements</strong></summary>

## 6. Quality Requirements

**Code**

- Use C99 and POSIX.1-2001 APIs for C code.
- Keep headers self-contained.
- Add the MIT license header to new source and script files.
- Include focused tests for changed behavior.

**Tests**

Run relevant tests and, when practical, the complete suite with `make run`.

**Documentation**

- Use precise, neutral language and consistent terminology.
- Use backticks for commands, paths, and identifiers.
- Run `make check-doc` after changing canonical documentation.

**Security**

- Never commit credentials, tokens, private keys, or other secrets.
- Do not commit files larger than 10 MB.
- Report vulnerabilities through `.github/SECURITY.md`.

**Versioning and branding**

The repository uses `M.m.p` version numbers. Patch releases contain fixes, minor
releases add backward-compatible features, and major releases contain breaking
changes. Update branding through `rebrand`.
</details>

<details>
<summary><strong>7. Signing Commits</strong></summary>

## 7. Signing Commits

Protected-branch commits require a GPG signature. After signing is configured,
`commit` signs commits automatically.

On Linux and macOS:

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format=long
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
gpg --armor --export YOUR_KEY_ID
```

Add the exported public key to your GitHub account. On Windows, install GnuPG,
run the same key commands in PowerShell, and configure `gpg.program` if Git
cannot locate `gpg.exe`.

For signing failures, verify the key with `gpg --list-secret-keys`, confirm the
commit email belongs to your GitHub account, and run
`gpg-connect-agent updatestartuptty /bye` after changing terminals on Linux or
macOS.
</details>

<details>
<summary><strong>8. Protected Branches and Releases</strong></summary>

## 8. Protected Branches and Releases

`main` and `v<M>.<m>.0` branches are protected. Do not commit to them directly,
edit them through GitHub.com, delete them, or rewrite their history.

Use `pushup` through an allowed push-up path. It validates branch versions,
permissions, synchronization, and required pull requests before publication.
GitHub rulesets separately prevent deletion and non-fast-forward updates.

Releases are approver operations. Before running `release`, verify the version
branch, version numbers, release notes, tests, stale references, and generated
documents. Commit and push preparation changes through project commands. Run
`release -h` for current prerequisites. Do not create or push release tags with
direct Git commands.
</details>

<details>
<summary><strong>9. Validation and Local Safeguards</strong></summary>

## 9. Validation and Local Safeguards

GitHub validates branch relationships, commit metadata, authors, signatures,
protected files, large files, secrets, license headers, code quality, and
workflow syntax. When a check fails, read its first actionable error, correct
and test the problem locally, then run `commit` and `push`.

`setupclone` configures local hooks that prevent accidental direct commits,
pushes, and pulls. Project commands perform policy and permission checks and
invoke Git safely. Contributors do not need to know or set internal hook-bypass
variables.

If local safeguards are missing, run `setupclone` to restore them.
</details>

<details>
<summary><strong>10. Troubleshooting and Help</strong></summary>

## 10. Troubleshooting and Help

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;10.1. Common Problems</summary>

### 10.1. Common Problems

- **Identity cannot be determined:** run `gh auth login`, set `GITHUB_ACTOR`,
  or configure `git config user.name` with a login in
  `config/contributors.md`.
- **Branch is behind its remote copy:** run `pull`.
- **Branch is behind its parent:** run `pulldown`.
- **Validation failed:** correct the first actionable error locally, test it,
  then run `commit` and `push`.
- **Reviewer requested changes:** use `feedback view`, make and test the
  changes, run `commit` and `push`, then respond and resolve addressed threads.
- **Wrong files or commit:** run `undo`; it selects the current branch's latest
  reversible operation. Do not use direct reset commands.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;10.2. Interrupted Pushup</summary>

### 10.2. Interrupted Pushup

- Restore the system or network connection.
- Rerun `pushup`; it inspects the saved phase and exact local and remote tips.
- If recovery proves publication did not occur, it restores the saved
  local branch versions. Run `pushup` to begin again.
- If the remote remains unavailable, restore connectivity and retry. The
  command retains saved recovery information rather than guessing.

Do not edit participating branches or delete saved recovery information while
recovery is pending. Repeated continuation checks exact local and remote branch
versions before resuming.
</details>

<details>
<summary>&nbsp;&nbsp;&nbsp;&nbsp;10.3. Getting Help</summary>

### 10.3. Getting Help

- Run `COMMAND -h` for command-specific help.
- See [Contributor_Reference.md](./Contributor_Reference.md) for detailed
  command behavior and exit statuses.
- See [Contributor_Internal_Guide.md](./Contributor_Internal_Guide.md) for
  internal policy and recovery work.
- Open a GitHub issue for a defect or a GitHub Discussion for a question.
</details>
</details>