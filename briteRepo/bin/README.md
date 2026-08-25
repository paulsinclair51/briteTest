# `<repo>/briteRepo/bin/`

Directory containing contributor scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to the repository.

## Files

### Setup and Installation

**setup_rulesets**: Configure repository rulesets for protected branch and tag
policy. Repository owner and GitHub administration access are required.

**setupclone**: Setup clone environment `<repo>/briteRepo/bin/` to PATH.

### Document and Brand Management

**gendocs**: Generate PDF and DOCX documentation.

**genpngs**: Generate branding PNG images from SVG files.

**rebrand**: Update branding text and regenerate related assets.

**replacetext**: Apply configured text replacements in markdown files.

### Repository and Fork Management

**fixlocal**: Start here for local working-copy, branch-tracking, or local repo
integrity issues. It validates the current clone and applies only safe local
repairs.

**fixremote**: Remote-recovery workflow. Use only when the error is in the remote
(origin) repository or when a protected ref/object must be recovered from a
known-clean clone.

**fixrepo**: Broader repository-wide validation across the current repo and an
optional second clone. Use after fixlocal if the issue may extend beyond the
current working copy.

**mkclone**: Clone the repository with optional target naming.

**mkfork**: Create a fork of the repository and optionally configure it with
upstream remote and user as approver.

**rmclone**: Safely remove a local clone with validation checks and optional
override.

### Branch and Workflow Management

**chbranch**: Select an existing local branch or a fresh read-only remote
snapshot. Local branches are preferred by default, including protected
branches. A local protected branch is refreshed only by a safe fast-forward;
protected branches and remote snapshots remain read-only.

**commit**: Commit and optionally push changes to remote.

**copyfix**: Copy fix commits from a source fix branch into
the current branch.

**feedback**: View/respond to PR feedback workflows.

**lsbranch**: List a branch or branches and their status.

**mkbranch**: Create branches with policy validation.

**override**: Repository owner only. Toggle local or remote-repair authorization
for this clone (`override on` / `override off`, and `override -r on`). Use
`override off` to clear both local and remote override modes. Local override is
for exceptional local recovery; remote repair mode is only a temporary
owner-admin workflow marker and does not bypass GitHub rulesets or branch
protection.

**pull**: Pull from remote to current branch (which must be local).

**pulldown**: Merge parent branch into current branch.

**push**: Push from current branch (which must be local) to its
corresponding remote branch.

**pushup**: Push the current branch up to its parent, publish the parent,
resynchronize the source branch, and publish the source. Partial push-up workflows
are recorded and resumed with `pushup --continue`.

**release**: Create and publish releases.

**report**: Generate repository health, branch activity, and style reports.

**retarget**: Retarget a targeted branch locally; use `-r` to publish it.
targeted branch is renamed to have its version as the specified version.

**review**: Create or update a pull request.

**rmbranch**: Remove local and/or remote branches.

**undo**: Undo recent merge/release/commit operations.

### README Directory Guide

**README.md**: This directory guide.

## Subdirectories

None.

## Recommended repair order

Use the repair scripts in this order when more than one layer is involved:

1. `fixlocal` for the current local clone/worktree/state issues
   (default starting point for fixing the current local repository)
2. `fixrepo` for broader repo-level local checks
3. `fixremote` for remote-origin recovery from a clean clone
4. `override -r` only as the temporary owner-admin repair authorization step
   while GitHub-side admin controls restore a protected remote ref

## Getting Started

To make all scripts executable and add them to your PATH, run:

   ```sh
   bash `<repo>/briteRepo/bin/setupclone`
   ```

This script will:
- Make all scripts executable (chmod +x)
- Add `<repo>/briteRepo/bin/` to PATH in ~/.bashrc
- Update the shell configuration for current and future sessions

For an already-open terminal, reload the updated PATH before running scripts by
name:

   ```sh
   source ~/.bashrc
   hash -r
   ```

For more information, run:

  ```sh
  bash `<repo>/briteRepo/bin/setupclone` -h
  ```

## Usage

For a script's usage information, execute the script using the
`-h` option. For example,

  ```sh
  lsbranch -h
  ```

## Troubleshooting

### Scripts not executable

If a script is not executable in your environment, you can:

1. Run or rerun `<repo>/briteRepo/bin/setupclone` (see Getting
   Started above).

3. Manually fix individual scripts:

   ```sh
   chmod +x `<repo>/briteRepo/bin/<script_name>`
   ```

### Scripts not in PATH

1. Run or rerun `<repo>/briteRepo/bin/setupclone` (see Getting
   Started above).

3. Manually update the PATH configuration:

   - Add this line to ~/.bashrc:

      ```sh
      export PATH="`<repo>/briteRepo/bin`:$PATH"
      ```

   - Then reload your shell configuration:

     ```sh
     source ~/.bashrc
     ```
