# `<repo>/scripts/bin/`

Directory containing contributor scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

### Setup and Installation

- **installscripts**: Make all scripts executable and add
   `<repo>/scripts/bin/` to PATH.

### Document and Brand Management

- **ckstyle**: Check style quidelines for documention, code, scripts,
   directory guides, versions etc. for the current branch.
   See Contributor Guide for guidelines.
- **gendocs**: Generate PDF and DOCX documentation.
- **genpngs**: Generate branding PNG images from SVG files.
- **replacephrases**: Apply configured phrase replacements in markdown files.
- **updatebrand**: Update branding text and regenerate related assets.

### Repository and Fork Management

- **mkfork**: Create a fork of the repository and optionally configure it with
  upstream remote and user as approver.

### Branch and Workflow Management

- **ckbranch_history**: Query branch history log entries.
- **lsbranch**: List a branch or branches and their status.
- **mkbranch**: Create branches with policy validation.
- **mkclone**: Clone the repository with optional target naming.
- **commit**: Commit and optionally push changes.
- **copyfix**: Cherry-pick/copy fix commits from another branch.
- **mkfeedback**: View/respond to PR feedback workflows.
- **mergetoparent**: Merge current branch to its parent branch.
- **mkpullrequest**: Create or update a pull request.
- **chtarget**: Retarget a targeted branch to a different version parent.
- **mkrelease**: Create and publish releases.
- **syncfromremote**: Fetch and pull latest changes.
- **syncfromparent**: Merge parent branch into current branch.
- **testscripts**: Run tests and optional documentation checks.
- **undo**: Undo recent merge/release/commit operations.
- **rmbranch**: Remove local and/or remote branches.

### README Directory Guide

- **README.md**: This directory guide.

## Subdirectories

- None.

## Getting Started

To make all scripts executable and add them to your PATH, run:

   ```sh
   bash `<repo>/scripts/bin/installscripts`
   ```

This script will:
- Make all scripts executable (chmod +x)
- Add `<repo>/scripts/bin/` to PATH in ~/.bashrc
- Load the updated configuration so scripts are available immediately

For more information, run:

  ```sh
  bash `<repo>/scripts/bin/installscripts` -h
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

1. Run or rerun `<repo>/scripts/bin/installscripts` (see Getting
   Started above).

3. Manually fix individual scripts:

   ```sh
   chmod +x `<repo>/scripts/bin/<script_name>`
   ```

### Scripts not in PATH

1. Run or rerun `<repo>/scripts/bin/installscripts` (see Getting
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
