# `<repo>/scripts/bin/`

Directory containing contributor scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

### Setup and Installation

- **setupclone**: Setup clone environment
   `<repo>/scripts/bin/` to PATH.

### Document and Brand Management

- **ckstyle**: Check style quidelines for documention, code, scripts,
   directory guides, versions etc. for the current branch.
   See Contributor Guide for guidelines.
- **gendocs**: Generate PDF and DOCX documentation.
- **genpngs**: Generate branding PNG images from SVG files.
- **replacetext**: Apply configured text replacements in markdown files.
- **rebrand**: Update branding text and regenerate related assets.

### Repository and Fork Management

- **fixrepo**: Verify repository/clone integrity, run safe cleanup fixes,
  rerun affected post-cleanup checks, and generate a health report.
- **mkclone**: Clone the repository with optional target naming.
- **mkfork**: Create a fork of the repository and optionally configure it with
  upstream remote and user as approver.
- **rmclone**: Safely remove a local clone with validation checks and optional
   override.

### Branch and Workflow Management

- **chbranch**: Change to specified local branch as current branch
  (blocks `main` which is not allowed to have a local branch).
  When local branch doesn't exist, creates local tracking branch from
  origin/<branch>` if it exists and is available.
  List can include cached remote-only branches.
- **retarget**: Retarget a targeted branch to a different version branch.
  targeted branch is renamed to have its version as the specified version.
- **lsbranchlog**: Query branch history log entries.
- **commit**: Commit and optionally push changes to remote.
- **copyfix**: Cherry-pick/copy fix commits from another branch.
- **lsbranch**: List a branch or branches and their status.
- **mkbranch**: Create branches with policy validation.
- **feedback**: View/respond to PR feedback workflows.
- **mrgup**: Merge current branch to its parent branch.
- **review**: Create or update a pull request.
- **release**: Create and publish releases.
- **rmbranch**: Remove local and/or remote branches.
- **mrgdown**: Merge parent branch into current branch.
- **mrgbranch**: Fetch and pull latest changes from remote into
  local branch
- **undo**: Undo recent merge/release/commit operations.

### README Directory Guide

- **README.md**: This directory guide.

## Subdirectories

- None.

## Getting Started

To make all scripts executable and add them to your PATH, run:

   ```sh
   bash `<repo>/scripts/bin/setupclone`
   ```

This script will:
- Make all scripts executable (chmod +x)
- Add `<repo>/scripts/bin/` to PATH in ~/.bashrc
- Load the updated configuration so scripts are available immediately

For more information, run:

  ```sh
  bash `<repo>/scripts/bin/setupclone` -h
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

1. Run or rerun `<repo>/scripts/bin/setupclone` (see Getting
   Started above).

3. Manually fix individual scripts:

   ```sh
   chmod +x `<repo>/scripts/bin/<script_name>`
   ```

### Scripts not in PATH

1. Run or rerun `<repo>/scripts/bin/setupclone` (see Getting
   Started above).

3. Manually update the PATH configuration:

   - Add this line to ~/.bashrc:

      ```sh
      export PATH="`<repo>/scripts/bin`:$PATH"
      ```

   - Then reload your shell configuration:

     ```sh
     source ~/.bashrc
     ```
