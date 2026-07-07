# `<repo>/scripts/bin/`

Directory containing contributor scripts.

Copyright (c) 2026 Paul Sinclair  
SPDX-License-Identifier: MIT  
For license details, see `<repo>/LICENSE`.

See `<repo>/README.md` for an introduction to briteTest.

## Files

### Setup and Installation

- **installscripts**: Make all scripts executable and add `<repo>/scripts/bin/` to PATH.

### Document and Brand Management

- **ckstyle**: Check style quidelines for documention, code, scripts, directory
  guides, versions etc. for the current branch. See Contributor Guide for guidelines.
- **gendocs**: Generate PDF and DOCX documentation.
- **genpngs**: Generate branding PNG images from SVG files.
- **replacephrases**: Apply configured phrase replacements in markdown files.
- **updatebrand**: Update branding text and regenerate related assets.

### Branch and Workflow Management

- **lsbranch**: Check branch and repository status.
- **ckbranch_history**: Query branch history log entries.
- **ckversions**: Validate version consistency across `<repo>/docs/include/src.`
- **mkbranch**: Create branches with policy validation.
- **mkclone**: Clone the repository with optional target naming.
- **mkcommit**: Commit and optionally push changes.
- **mkcopy**: Cherry-pick/copy commits from another branch.
- **mkfeedback**: View/respond to PR feedback workflows.
- **mkmerge**: Merge current branch to its base branch.
- **mkpullrequest**: Create or update a pull request.
- **mkrebase**: Rebase current branch to a new base branch.
- **mkrelease**: Create and publish releases.
- **mksync**: Fetch and pull latest changes.
- **mksyncup**: Merge base branch into current branch.
- **mktest**: Run tests and optional documentation checks.
- **mkundo**: Undo recent merge/release/commit operations.
- **rmbranch**: Remove local and/or remote branches.

### README Directory Guide

- **README.md**: This directory guide.

## Subdirectories

- None.

## Getting Started with Scripts

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

## Script Usage

For a script's usage information, execute the script using the `-h` option. For example,

```sh
lsbranch -h
```

## Troubleshooting

### Scripts not executable

If a script is not executable in your environment, you can:

1. **Run the setup script** to fix all scripts at once:

   ```sh
   bash `<repo>/scripts/bin/installscripts`
   ```

3. **Manually fix individual scripts**:

   ```sh
   chmod +x `<repo>/scripts/bin/<script_name>`
   ```

### Scripts not in PATH

If scripts are not available by name in your shell, ensure you've run:

```sh
bash `<repo>/scripts/bin/installscripts`
```

This adds the necessary PATH configuration to ~/.bashrc. You may need to start a new terminal session for changes to take effect.

### Manual PATH configuration

If you prefer to configure PATH manually instead of using `installscripts`, add this line to ~/.bashrc:

```sh
export PATH="`<repo>/scripts/bin`:$PATH"
```

Then reload your shell configuration:

```sh
source ~/.bashrc
```
